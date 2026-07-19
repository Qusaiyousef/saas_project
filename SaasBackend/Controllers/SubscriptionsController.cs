using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SaasBackend.Models.Entities;
using SaasBackend.Services;
using Microsoft.Extensions.Caching.Memory;

namespace SaasBackend.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class SubscriptionsController : ControllerBase
{
    private readonly ISubscriptionService _subscriptionService;
    private readonly ITenantProvider _tenantProvider;
    private readonly IMemoryCache _cache;

    public SubscriptionsController(ISubscriptionService subscriptionService, ITenantProvider tenantProvider, IMemoryCache cache)
    {
        _subscriptionService = subscriptionService;
        _tenantProvider = tenantProvider;
        _cache = cache;
    }

    [HttpPost]
    public async Task<IActionResult> CreateSubscription([FromBody] Subscription subscription)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        // Always enforce TenantId from JWT - never trust the client
        var tenantId = _tenantProvider.GetTenantId();
        if (!tenantId.HasValue)
            return Unauthorized(new { message = "Tenant not identified." });

        subscription.TenantId = tenantId.Value;
        subscription.Id = Guid.NewGuid();

        try
        {
            var created = await _subscriptionService.CreateSubscriptionAsync(subscription);

            // Invalidate Finance Cache for the Tenant
            _cache.Remove($"FinanceSummary_{tenantId.Value}");
            _cache.Remove($"FinanceTransactions_{tenantId.Value}");

            return CreatedAtAction(nameof(GetSubscriptions), new { resourceId = subscription.ResourceId }, created);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = $"Error creating subscription: {ex.Message}" });
        }
    }

    [HttpGet("resource/{resourceId}/active")]
    public async Task<IActionResult> GetSubscriptions(Guid resourceId)
    {
        var subscriptions = await _subscriptionService.GetActiveSubscriptionsAsync(resourceId);
        return Ok(subscriptions);
    }

    [HttpPut("{id}/cancel")]
    public async Task<IActionResult> CancelSubscription(Guid id)
    {
        try
        {
            var cancelled = await _subscriptionService.CancelSubscriptionAsync(id);
            if (cancelled == null) return NotFound(new { message = "Subscription not found." });

            var tenantId = _tenantProvider.GetTenantId();
            if (tenantId.HasValue)
            {
                _cache.Remove($"FinanceSummary_{tenantId.Value}");
                _cache.Remove($"FinanceTransactions_{tenantId.Value}");
            }

            return Ok(new { message = "Subscription cancelled successfully." });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = $"Error cancelling subscription: {ex.Message}" });
        }
    }
}
