using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SaasBackend.Models.Entities;
using SaasBackend.Services;
using Microsoft.Extensions.Caching.Memory;

namespace SaasBackend.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class BookingsController : ControllerBase
{
    private readonly IBookingService _bookingService;
    private readonly ITenantProvider _tenantProvider;
    private readonly IMemoryCache _cache;

    public BookingsController(IBookingService bookingService, ITenantProvider tenantProvider, IMemoryCache cache)
    {
        _bookingService = bookingService;
        _tenantProvider = tenantProvider;
        _cache = cache;
    }

    [HttpPost]
    public async Task<IActionResult> CreateBooking([FromBody] TimeBooking booking)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        // Always enforce TenantId from JWT - never trust the client
        var tenantId = _tenantProvider.GetTenantId();
        if (!tenantId.HasValue)
            return Unauthorized(new { message = "Tenant not identified." });

        booking.TenantId = tenantId.Value;
        booking.Id = Guid.NewGuid();

        try
        {
            var createdBooking = await _bookingService.CreateBookingAsync(booking);

            // Invalidate Finance Cache for the Tenant
            _cache.Remove($"FinanceSummary_{tenantId.Value}");
            _cache.Remove($"FinanceTransactions_{tenantId.Value}");

            return CreatedAtAction(nameof(GetBookings), new { resourceId = booking.ResourceId }, createdBooking);
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { message = ex.Message });
        }
        catch (Exception)
        {
            return StatusCode(500, new { message = "An error occurred while creating the booking." });
        }
    }

    [HttpGet("resource/{resourceId}")]
    public async Task<IActionResult> GetBookings(Guid resourceId, [FromQuery] DateTime from, [FromQuery] DateTime to)
    {
        var bookings = await _bookingService.GetBookingsForResourceAsync(resourceId, from, to);
        return Ok(bookings);
    }
}
