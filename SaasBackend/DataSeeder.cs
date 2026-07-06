using Microsoft.AspNetCore.Identity;
using SaasBackend.Data;
using SaasBackend.Models;
using SaasBackend.Models.Entities;
using Microsoft.EntityFrameworkCore;

namespace SaasBackend;

public static class DataSeeder
{
    public static async Task SeedDataAsync(IServiceProvider serviceProvider)
    {
        using var scope = serviceProvider.CreateScope();
        var userManager = scope.ServiceProvider.GetRequiredService<UserManager<ApplicationUser>>();
        var roleManager = scope.ServiceProvider.GetRequiredService<RoleManager<IdentityRole>>();
        var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        // Seed Roles
        if (!await roleManager.RoleExistsAsync("Admin"))
            await roleManager.CreateAsync(new IdentityRole("Admin"));
        if (!await roleManager.RoleExistsAsync("Employee"))
            await roleManager.CreateAsync(new IdentityRole("Employee"));

        // =============================================
        // TENANT 1: POOL - seed only if admin not found
        // =============================================
        if (await userManager.FindByEmailAsync("qusai@gmail.com") == null)
        {
            var poolTenant = new Tenant { Id = Guid.NewGuid(), Name = "Aqua Pool Center", Type = TenantType.Pool, IsActive = true };
            context.Tenants.Add(poolTenant);
            await context.SaveChangesAsync();
            context.Resources.Add(new Resource { Id = Guid.NewGuid(), TenantId = poolTenant.Id, Name = "Main Swimming Pool", Capacity = 100 });
            await context.SaveChangesAsync();
            await CreateUser(userManager, "qusai@gmail.com", "Admin123!", "Qusai (Pool Admin)", poolTenant.Id, "Admin");
            await CreateUser(userManager, "ali@gmail.com", "Ali1234!", "Ali (Pool Employee)", poolTenant.Id, "Employee");
        }

        // =============================================
        // TENANT 2: GYM - seed only if admin not found
        // =============================================
        if (await userManager.FindByEmailAsync("gym_admin@gmail.com") == null)
        {
            var gymTenant = new Tenant { Id = Guid.NewGuid(), Name = "Power Gym", Type = TenantType.Gym, IsActive = true };
            context.Tenants.Add(gymTenant);
            await context.SaveChangesAsync();
            context.Resources.Add(new Resource { Id = Guid.NewGuid(), TenantId = gymTenant.Id, Name = "Main Gym Hall", Capacity = 50 });
            await context.SaveChangesAsync();
            await CreateUser(userManager, "gym_admin@gmail.com", "Admin123!", "Ahmad (Gym Admin)", gymTenant.Id, "Admin");
            await CreateUser(userManager, "gym_emp@gmail.com", "Emp1234!", "Noor (Gym Employee)", gymTenant.Id, "Employee");
        }

        // =============================================
        // TENANT 3: CHALET - seed only if admin not found
        // =============================================
        if (await userManager.FindByEmailAsync("chalet_admin@gmail.com") == null)
        {
            var chaletTenant = new Tenant { Id = Guid.NewGuid(), Name = "Green Chalet Resort", Type = TenantType.Chalet, IsActive = true };
            context.Tenants.Add(chaletTenant);
            await context.SaveChangesAsync();
            context.Resources.Add(new Resource { Id = Guid.NewGuid(), TenantId = chaletTenant.Id, Name = "Chalet A - Main Villa", Capacity = 1 });
            context.Resources.Add(new Resource { Id = Guid.NewGuid(), TenantId = chaletTenant.Id, Name = "Chalet B - Garden Suite", Capacity = 1 });
            await context.SaveChangesAsync();
            await CreateUser(userManager, "chalet_admin@gmail.com", "Admin123!", "Sara (Chalet Admin)", chaletTenant.Id, "Admin");
            await CreateUser(userManager, "chalet_emp@gmail.com", "Emp1234!", "Omar (Chalet Employee)", chaletTenant.Id, "Employee");
        }
    }

    private static async Task CreateUser(
        UserManager<ApplicationUser> userManager,
        string email, string password, string fullName,
        Guid tenantId, string role)
    {
        if (await userManager.FindByEmailAsync(email) != null) return;

        var user = new ApplicationUser
        {
            UserName = email,
            Email = email,
            FullName = fullName,
            TenantId = tenantId,
            EmailConfirmed = true
        };

        var result = await userManager.CreateAsync(user, password);
        if (result.Succeeded)
            await userManager.AddToRoleAsync(user, role);
    }
}
