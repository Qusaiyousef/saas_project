using Microsoft.EntityFrameworkCore;
using SaasBackend.Data;
using SaasBackend.Models;
using SaasBackend.Models.Entities;

namespace SaasBackend.Services;

public class SubscriptionService : ISubscriptionService
{
    private readonly AppDbContext _context;

    public SubscriptionService(AppDbContext context)
    {
        _context = context;
    }

    public async Task<Subscription> CreateSubscriptionAsync(Subscription subscription)
    {
        subscription.Status = SubscriptionStatus.Active;
        _context.Subscriptions.Add(subscription);
        
        if (subscription.AmountPaid > 0 && subscription.CustomerId.HasValue)
        {
            _context.PaymentRecords.Add(new PaymentRecord
            {
                Id = Guid.NewGuid(),
                TenantId = subscription.TenantId,
                CustomerId = subscription.CustomerId.Value,
                SubscriptionId = subscription.Id,
                Amount = subscription.AmountPaid,
                PaymentDate = DateTime.UtcNow,
                Notes = "Initial payment upon subscription"
            });
        }
        
        await _context.SaveChangesAsync();
        return subscription;
    }

    public async Task<IEnumerable<Subscription>> GetActiveSubscriptionsAsync(Guid resourceId)
    {
        // Return all subscriptions for this resource (tenant filter applied automatically via global filter)
        return await _context.Subscriptions
            .Where(s => s.ResourceId == resourceId && s.Status == SubscriptionStatus.Active)
            .OrderByDescending(s => s.StartDate)
            .ToListAsync();
    }

    public async Task<Subscription?> CancelSubscriptionAsync(Guid id)
    {
        var subscription = await _context.Subscriptions.FindAsync(id);
        if (subscription == null) return null;

        subscription.Status = SubscriptionStatus.Cancelled;
        subscription.EndDate = DateTime.UtcNow;

        await _context.SaveChangesAsync();
        return subscription;
    }
}
