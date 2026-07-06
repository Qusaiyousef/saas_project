using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using SaasBackend.Models.Entities;
using SaasBackend.Models.Interfaces;
using SaasBackend.Services;

namespace SaasBackend.Data;

public class AppDbContext : IdentityDbContext<ApplicationUser>
{
    private readonly ITenantProvider _tenantProvider;

    public AppDbContext(DbContextOptions<AppDbContext> options, ITenantProvider tenantProvider) 
        : base(options)
    {
        _tenantProvider = tenantProvider;
    }

    public DbSet<Tenant> Tenants { get; set; }
    public DbSet<Resource> Resources { get; set; } = null!;
    public DbSet<PricingPlan> PricingPlans { get; set; } = null!;
    public DbSet<TimeBooking> TimeBookings { get; set; } = null!;
    public DbSet<Subscription> Subscriptions { get; set; } = null!;
    public DbSet<Customer> Customers { get; set; } = null!;
    public DbSet<PaymentRecord> PaymentRecords { get; set; } = null!;
    public DbSet<UserPagePermission> UserPagePermissions { get; set; } = null!;

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        // --- Multi-Tenancy Global Query Filters ---
        // Exclude Tenant itself from this filter, as SuperAdmins might query multiple tenants
        
        builder.Entity<Resource>().HasQueryFilter(e => e.TenantId == _tenantProvider.GetTenantId());
        builder.Entity<PricingPlan>().HasQueryFilter(e => e.TenantId == _tenantProvider.GetTenantId());
        builder.Entity<PricingPlan>().Property(p => p.Price).HasColumnType("decimal(18,2)");

        builder.Entity<TimeBooking>().HasQueryFilter(e => e.TenantId == _tenantProvider.GetTenantId());
        builder.Entity<TimeBooking>().Property(t => t.AmountPaid).HasColumnType("decimal(18,2)");
        builder.Entity<TimeBooking>().Property(t => t.TotalAmount).HasColumnType("decimal(18,2)");

        builder.Entity<Subscription>().HasQueryFilter(e => e.TenantId == _tenantProvider.GetTenantId());
        builder.Entity<Subscription>().Property(s => s.AmountPaid).HasColumnType("decimal(18,2)");
        builder.Entity<Subscription>().Property(s => s.TotalAmount).HasColumnType("decimal(18,2)");

        builder.Entity<Customer>().HasQueryFilter(e => e.TenantId == _tenantProvider.GetTenantId());
        
        builder.Entity<PaymentRecord>().HasQueryFilter(e => e.TenantId == _tenantProvider.GetTenantId());
        builder.Entity<PaymentRecord>().Property(p => p.Amount).HasColumnType("decimal(18,2)");
        // NOTE: Do NOT add a query filter on ApplicationUser - Identity's UserManager uses its own
        // queries and cannot bypass the filter at login time (no tenant is set yet).

        builder.Entity<UserPagePermission>().HasQueryFilter(e => e.TenantId == _tenantProvider.GetTenantId());

        builder.Entity<UserPagePermission>()
            .HasOne(p => p.User)
            .WithMany()
            .HasForeignKey(p => p.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        // Configure relations and cascading
        builder.Entity<Tenant>()
            .HasMany(t => t.Resources)
            .WithOne(r => r.Tenant)
            .HasForeignKey(r => r.TenantId)
            .OnDelete(DeleteBehavior.Restrict);
            
        builder.Entity<Tenant>()
            .HasMany(t => t.Users)
            .WithOne(u => u.Tenant)
            .HasForeignKey(u => u.TenantId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.Entity<PaymentRecord>()
            .HasOne(p => p.Tenant)
            .WithMany()
            .HasForeignKey(p => p.TenantId)
            .OnDelete(DeleteBehavior.Restrict);
            
        builder.Entity<PaymentRecord>()
            .HasOne(p => p.Customer)
            .WithMany()
            .HasForeignKey(p => p.CustomerId)
            .OnDelete(DeleteBehavior.Restrict);
    }
    
    public override int SaveChanges()
    {
        EnforceTenantId();
        return base.SaveChanges();
    }

    public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        EnforceTenantId();
        return base.SaveChangesAsync(cancellationToken);
    }

    private void EnforceTenantId()
    {
        var tenantId = _tenantProvider.GetTenantId();
        
        foreach (var entry in ChangeTracker.Entries<ITenantEntity>())
        {
            if (entry.State == EntityState.Added || entry.State == EntityState.Modified)
            {
                if (tenantId.HasValue)
                {
                    // Automatically set the TenantId on creation
                    if (entry.State == EntityState.Added)
                    {
                        entry.Entity.TenantId = tenantId.Value;
                    }
                    // Prevent modification of TenantId
                    else if (entry.Entity.TenantId != tenantId.Value)
                    {
                        throw new UnauthorizedAccessException("Cross-tenant update is not allowed.");
                    }
                }
            }
        }
    }
}
