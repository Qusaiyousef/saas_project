using SaasBackend.Models.Entities;

namespace SaasBackend.Services;

public interface IBookingService
{
    Task<TimeBooking> CreateBookingAsync(TimeBooking booking);
    Task<IEnumerable<TimeBooking>> GetBookingsForResourceAsync(Guid resourceId, DateTime fromDate, DateTime toDate);
    Task<TimeBooking?> CancelBookingAsync(Guid id, decimal feePercentage);
}
