using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SaasBackend.Data;
using SaasBackend.Models.Entities;
using SaasBackend.Services;
using Microsoft.Extensions.Caching.Memory;

namespace SaasBackend.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class PaymentsController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly ITenantProvider _tenantProvider;
    private readonly IMemoryCache _cache;

    public PaymentsController(AppDbContext context, ITenantProvider tenantProvider, IMemoryCache cache)
    {
        _context = context;
        _tenantProvider = tenantProvider;
        _cache = cache;
    }

    [HttpGet("customer/{customerId}")]
    public async Task<IActionResult> GetCustomerPayments(Guid customerId)
    {
        var payments = await _context.PaymentRecords
            .Where(p => p.CustomerId == customerId)
            .OrderByDescending(p => p.PaymentDate)
            .Select(p => new
            {
                p.Id,
                p.Amount,
                p.PaymentDate,
                p.Notes,
                p.SubscriptionId,
                p.TimeBookingId
            })
            .ToListAsync();

        return Ok(payments);
    }

    public class AddPaymentDto
    {
        public Guid CustomerId { get; set; }
        public Guid? SubscriptionId { get; set; }
        public Guid? TimeBookingId { get; set; }
        public decimal Amount { get; set; }
        public string? Notes { get; set; }
    }

    [HttpPost]
    public async Task<IActionResult> AddPayment([FromBody] AddPaymentDto input)
    {
        if (input.Amount <= 0) return BadRequest(new { message = "Amount must be greater than 0" });

        var tenantId = _tenantProvider.GetTenantId();
        if (!tenantId.HasValue) return Unauthorized();

        var payment = new PaymentRecord
        {
            Id = Guid.NewGuid(),
            TenantId = tenantId.Value,
            CustomerId = input.CustomerId,
            SubscriptionId = input.SubscriptionId,
            TimeBookingId = input.TimeBookingId,
            Amount = input.Amount,
            PaymentDate = DateTime.UtcNow,
            Notes = input.Notes
        };

        _context.PaymentRecords.Add(payment);

        if (input.SubscriptionId.HasValue)
        {
            var sub = await _context.Subscriptions.FindAsync(input.SubscriptionId.Value);
            if (sub != null) sub.AmountPaid += input.Amount;
        }
        else if (input.TimeBookingId.HasValue)
        {
            var booking = await _context.TimeBookings.FindAsync(input.TimeBookingId.Value);
            if (booking != null) booking.AmountPaid += input.Amount;
        }
        else
        {
            // General payment, distribute across unpaid subscriptions and bookings
            decimal remainingAmount = input.Amount;

            var unpaidSubs = await _context.Subscriptions
                .Where(s => s.CustomerId == input.CustomerId && s.AmountPaid < s.TotalAmount)
                .OrderBy(s => s.StartDate)
                .ToListAsync();

            foreach (var sub in unpaidSubs)
            {
                if (remainingAmount <= 0) break;
                decimal subDebt = sub.TotalAmount - sub.AmountPaid;
                decimal payToSub = Math.Min(subDebt, remainingAmount);
                sub.AmountPaid += payToSub;
                remainingAmount -= payToSub;
            }

            if (remainingAmount > 0)
            {
                var unpaidBookings = await _context.TimeBookings
                    .Where(b => b.CustomerId == input.CustomerId && b.AmountPaid < b.TotalAmount)
                    .OrderBy(b => b.StartTime)
                    .ToListAsync();

                foreach (var booking in unpaidBookings)
                {
                    if (remainingAmount <= 0) break;
                    decimal bookingDebt = booking.TotalAmount - booking.AmountPaid;
                    decimal payToBooking = Math.Min(bookingDebt, remainingAmount);
                    booking.AmountPaid += payToBooking;
                    remainingAmount -= payToBooking;
                }
            }
        }

        await _context.SaveChangesAsync();

        // Invalidate Finance Cache for the Tenant
        _cache.Remove($"FinanceSummary_{tenantId.Value}");
        _cache.Remove($"FinanceTransactions_{tenantId.Value}");

        return Ok(payment);
    }
}
