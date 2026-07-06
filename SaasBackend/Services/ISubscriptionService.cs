using SaasBackend.Models.Entities;

namespace SaasBackend.Services;

public interface ISubscriptionService
{
    Task<Subscription> CreateSubscriptionAsync(Subscription subscription);
    Task<IEnumerable<Subscription>> GetActiveSubscriptionsAsync(Guid resourceId);
}
