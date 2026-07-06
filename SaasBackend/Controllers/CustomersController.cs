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
                HasActiveSubscription = _context.Subscriptions.Any(s => s.CustomerId == c.Id && s.EndDate >= DateTime.UtcNow)
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
        if (customer == null)
            return NotFound(new { message = "Customer not found." });

        _context.Customers.Remove(customer);
        await _context.SaveChangesAsync();
        
        return Ok(new { message = "Customer deleted successfully." });
    }
}
