using System.ComponentModel.DataAnnotations;
using SaasBackend.Models.Interfaces;

namespace SaasBackend.Models.Entities;

public class TimeBooking : ITenantEntity
{
    [Key]
    public Guid Id { get; set; }
    
    public Guid TenantId { get; set; }
    public Tenant? Tenant { get; set; }
    
    public Guid ResourceId { get; set; }
    public Resource? Resource { get; set; }
    
    [Required]
    [MaxLength(200)]
    public string CustomerName { get; set; } = string.Empty;
    
    public Guid? CustomerId { get; set; }
    public Customer? Customer { get; set; }
    
    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; }
    
    // Crucial for Pool logic
    public bool IsFullDayBlock { get; set; }
    
    public BookingStatus Status { get; set; } = BookingStatus.Confirmed;
    
    public decimal TotalAmount { get; set; }
    public decimal AmountPaid { get; set; }
}
