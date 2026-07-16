using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SaasBackend.Data;
using SaasBackend.Services;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.DependencyInjection;

namespace SaasBackend.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class FinanceController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly ITenantProvider _tenantProvider;
    private readonly IMemoryCache _cache;

    public FinanceController(AppDbContext context, ITenantProvider tenantProvider, IMemoryCache cache)
    {
        _context = context;
        _tenantProvider = tenantProvider;
        _cache = cache;
    }

    [HttpGet("summary")]
    public async Task<IActionResult> GetSummary()
    {
        var tenantId = _tenantProvider.GetTenantId();
        if (!tenantId.HasValue) return Unauthorized();

        var cacheKey = $"FinanceSummary_{tenantId.Value}";

        var summary = await _cache.GetOrCreateAsync(cacheKey, async entry =>
        {
            entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(5);

            var bookingsTotal = await _context.TimeBookings
                .Where(b => b.TenantId == tenantId.Value)
                .SumAsync(b => b.AmountPaid);

            var subsTotal = await _context.Subscriptions
                .Where(s => s.TenantId == tenantId.Value)
                .SumAsync(s => s.AmountPaid);

            var bookingsCash = await _context.TimeBookings
                .Where(b => b.TenantId == tenantId.Value && b.PaymentMethod == "Cash")
                .SumAsync(b => b.AmountPaid);

            var subsCash = await _context.Subscriptions
                .Where(s => s.TenantId == tenantId.Value && s.PaymentMethod == "Cash")
                .SumAsync(s => s.AmountPaid);

            return new
            {
                totalRevenue = bookingsTotal + subsTotal,
                bookingsRevenue = bookingsTotal,
                subscriptionsRevenue = subsTotal,
                totalCash = bookingsCash + subsCash
            };
        });

        return Ok(summary);
    }

    [HttpGet("transactions")]
    public async Task<IActionResult> GetTransactions()
    {
        var tenantId = _tenantProvider.GetTenantId();
        if (!tenantId.HasValue) return Unauthorized();

        var cacheKey = $"FinanceTransactions_{tenantId.Value}";

        var transactions = await _cache.GetOrCreateAsync(cacheKey, async entry =>
        {
            entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(5);

            var bookings = await _context.TimeBookings
                .Where(b => b.TenantId == tenantId.Value && b.AmountPaid > 0)
                .Select(b => new
                {
                    Id = b.Id,
                    Date = b.StartTime,
                    CustomerName = b.CustomerName,
                    Type = "Booking",
                    Description = b.IsFullDayBlock ? "Full Day Booking" : "Hourly Booking",
                    Amount = b.AmountPaid,
                    Method = b.PaymentMethod
                })
                .AsNoTracking()
                .ToListAsync();

            var subscriptions = await _context.Subscriptions
                .Where(s => s.TenantId == tenantId.Value && s.AmountPaid > 0)
                .Select(s => new
                {
                    Id = s.Id,
                    Date = s.StartDate,
                    CustomerName = s.CustomerName,
                    Type = "Subscription",
                    Description = "Membership Plan",
                    Amount = s.AmountPaid,
                    Method = s.PaymentMethod
                })
                .AsNoTracking()
                .ToListAsync();

            return bookings.Concat(subscriptions).OrderByDescending(t => t.Date).ToList();
        });

        return Ok(transactions);
    }
}
