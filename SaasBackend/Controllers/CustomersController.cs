using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SaasBackend.Data;
using SaasBackend.Models.Entities;

namespace SaasBackend.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class CustomersController : ControllerBase
{
    private readonly AppDbContext _context;

    public CustomersController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<IActionResult> GetCustomers()
    {
        var customers = await _context.Customers
            .AsNoTracking()
            .Select(c => new
            {
                c.Id,
                c.Name,
                c.Phone,
                c.DateOfBirth,
                c.CreatedAt,
                TotalPaid = _context.Subscriptions.Where(s => s.CustomerId == c.Id).Sum(s => s.AmountPaid) +
                            _context.TimeBookings.Where(b => b.CustomerId == c.Id).Sum(b => b.AmountPaid),
                Balance = _context.Subscriptions.Where(s => s.CustomerId == c.Id).Sum(s => s.TotalAmount - s.AmountPaid) +
                          _context.TimeBookings.Where(b => b.CustomerId == c.Id).Sum(b => b.TotalAmount - b.AmountPaid),
                HasActiveSubscription = _context.Subscriptions.Any(s => s.CustomerId == c.Id && s.Status == SaasBackend.Models.SubscriptionStatus.Active)
            })
            .OrderByDescending(c => c.CreatedAt)
            .ToListAsync();

        return Ok(customers);
    }

    [HttpPost]
    public async Task<IActionResult> CreateCustomer([FromBody] Customer input)
    {
        if (string.IsNullOrWhiteSpace(input.Name))
            return BadRequest(new { message = "Customer name is required." });

        var customer = new Customer
        {
            Name = input.Name,
            Phone = input.Phone,
            DateOfBirth = input.DateOfBirth
        };

        _context.Customers.Add(customer);
        await _context.SaveChangesAsync();

        return Ok(customer);
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteCustomer(Guid id)
    {
        var customer = await _context.Customers.FindAsync(id);
        if (customer == null || customer.IsDeleted)
            return NotFound(new { message = "Customer not found." });

        customer.IsDeleted = true;
        await _context.SaveChangesAsync();
        
        return Ok(new { message = "Customer deleted successfully." });
    }

    // ── Check-In: البحث برقم الهاتف ──────────────────────────────────────────
    [HttpGet("by-phone/{phone}")]
    [AllowAnonymous]
    public async Task<IActionResult> GetByPhone(string phone)
    {
        var customer = await _context.Customers
            .AsNoTracking()
            .Where(c => c.Phone == phone && !c.IsDeleted)
            .FirstOrDefaultAsync();

        if (customer == null)
            return NotFound(new { message = "No customer found with this phone number." });

        return Ok(await BuildCheckInResult(customer));
    }

    // ── Check-In: البحث بمعرف البصمة الخارجية ──────────────────────────────
    [HttpGet("by-fingerprint/{fingerprintId}")]
    [AllowAnonymous]
    public async Task<IActionResult> GetByFingerprint(string fingerprintId)
    {
        var customer = await _context.Customers
            .AsNoTracking()
            .Where(c => c.FingerprintId == fingerprintId && !c.IsDeleted)
            .FirstOrDefaultAsync();

        if (customer == null)
            return NotFound(new { message = "No customer found with this fingerprint ID." });

        return Ok(await BuildCheckInResult(customer));
    }

    // ── تسجيل/تحديث معرف البصمة الخارجية للعميل ────────────────────────────
    [HttpPut("{id}/fingerprint")]
    public async Task<IActionResult> UpdateFingerprintId(Guid id, [FromBody] UpdateFingerprintDto dto)
    {
        var customer = await _context.Customers.FindAsync(id);
        if (customer == null || customer.IsDeleted)
            return NotFound(new { message = "Customer not found." });

        customer.FingerprintId = dto.FingerprintId;
        await _context.SaveChangesAsync();

        return Ok(new { message = "Fingerprint ID updated successfully." });
    }

    // ── دالة مساعدة لبناء نتيجة Check-In ───────────────────────────────────
    private async Task<object> BuildCheckInResult(Customer customer)
    {
        var now = DateTime.UtcNow;
        var activeSub = await _context.Subscriptions
            .AsNoTracking()
            .Where(s => s.CustomerId == customer.Id
                     && s.Status == SaasBackend.Models.SubscriptionStatus.Active
                     && s.EndDate >= now)
            .OrderByDescending(s => s.EndDate)
            .FirstOrDefaultAsync();

        return new
        {
            customer.Id,
            customer.Name,
            customer.Phone,
            customer.FingerprintId,
            Subscription = activeSub == null ? null : new
            {
                activeSub.Id,
                activeSub.StartDate,
                activeSub.EndDate,
                activeSub.TotalAmount,
                activeSub.AmountPaid,
                Balance = activeSub.TotalAmount - activeSub.AmountPaid,
                DaysRemaining = (int)(activeSub.EndDate - now).TotalDays,
                activeSub.PaymentMethod,
                activeSub.Status
            }
        };
    }
}

public class UpdateFingerprintDto
{
    public string? FingerprintId { get; set; }
}
