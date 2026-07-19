using Microsoft.EntityFrameworkCore;
using SaasBackend.Data;
using SaasBackend.Models;
using SaasBackend.Models.Entities;

namespace SaasBackend.Services;

public class BookingService : IBookingService
{
    private readonly AppDbContext _context;

    public BookingService(AppDbContext context)
    {
        _context = context;
    }

    public async Task<TimeBooking> CreateBookingAsync(TimeBooking booking)
    {
        // Enforce Pool Conflict Resolution Rule using EF Core explicit transaction 
        // to prevent race conditions during concurrent bookings.
        using var transaction = await _context.Database.BeginTransactionAsync(System.Data.IsolationLevel.Serializable);

        try
        {
            var targetDate = booking.StartTime.Date;

            if (booking.IsFullDayBlock)
            {
                // Rule 1: If creating a Full-Day Block, check if ANY booking exists for this resource on that day.
                var existingBookings = await _context.TimeBookings
                    .Where(b => b.ResourceId == booking.ResourceId
                                && b.StartTime.Date == targetDate
                                && b.Status == BookingStatus.Confirmed)
                    .AnyAsync();

                if (existingBookings)
                {
                    throw new InvalidOperationException("Cannot create a full-day block. Existing bookings found for this date.");
                }
            }
            else
            {
                // Rule 2: If creating a Time-Based booking, check if a Full-Day Block already exists for this date.
                var fullDayBlockExists = await _context.TimeBookings
                    .Where(b => b.ResourceId == booking.ResourceId
                                && b.StartTime.Date == targetDate
                                && b.IsFullDayBlock == true
                                && b.Status == BookingStatus.Confirmed)
                    .AnyAsync();

                if (fullDayBlockExists)
                {
                    throw new InvalidOperationException("Cannot create booking. The resource is blocked for the entire day.");
                }
                
                // TODO: Add standard capacity checks here for Gyms/Pools based on Resource.Capacity
            }

            _context.TimeBookings.Add(booking);
            
            if (booking.AmountPaid > 0 && booking.CustomerId.HasValue)
            {
                _context.PaymentRecords.Add(new PaymentRecord
                {
                    Id = Guid.NewGuid(),
                    TenantId = booking.TenantId,
                    CustomerId = booking.CustomerId.Value,
                    TimeBookingId = booking.Id,
                    Amount = booking.AmountPaid,
                    PaymentDate = DateTime.UtcNow,
                    Notes = "Initial payment upon booking"
                });
            }

            await _context.SaveChangesAsync();
            await transaction.CommitAsync();

            return booking;
        }
        catch
        {
            await transaction.RollbackAsync();
            throw;
        }
    }

    public async Task<IEnumerable<TimeBooking>> GetBookingsForResourceAsync(Guid resourceId, DateTime fromDate, DateTime toDate)
    {
        return await _context.TimeBookings
            .AsNoTracking()
            .Where(b => b.ResourceId == resourceId 
                     && b.StartTime >= fromDate 
                     && b.StartTime <= toDate)
            .OrderBy(b => b.StartTime)
            .ToListAsync();
    }

    public async Task<TimeBooking?> CancelBookingAsync(Guid id, decimal feePercentage)
    {
        var booking = await _context.TimeBookings.FindAsync(id);
        if (booking == null) return null;

        booking.Status = BookingStatus.Cancelled;

        var fee = booking.TotalAmount * (feePercentage / 100m);
        if (fee > booking.AmountPaid) fee = booking.AmountPaid;

        booking.TotalAmount = fee;
        booking.AmountPaid = fee;

        var payment = await _context.PaymentRecords
            .FirstOrDefaultAsync(p => p.TimeBookingId == id);

        if (payment != null)
        {
            if (fee <= 0)
            {
                _context.PaymentRecords.Remove(payment);
            }
            else
            {
                payment.Amount = fee;
                payment.Notes = string.IsNullOrEmpty(payment.Notes) 
                    ? $"Cancellation Fee ({feePercentage}%)" 
                    : payment.Notes + $" - Cancellation Fee ({feePercentage}%)";
            }
        }

        await _context.SaveChangesAsync();
        return booking;
    }
}
