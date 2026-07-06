using System.ComponentModel.DataAnnotations;
using SaasBackend.Models.Interfaces;

namespace SaasBackend.Models.Entities;

public class PaymentRecord : ITenantEntity
{
    [Key]
    public Guid Id { get; set; }
    
    public Guid TenantId { get; set; }
    public Tenant? Tenant { get; set; }
    
    public Guid CustomerId { get; set; }
    public Customer? Customer { get; set; }
    
    public Guid? SubscriptionId { get; set; }
    public Subscription? Subscription { get; set; }
    
    public Guid? TimeBookingId { get; set; }
    public TimeBooking? TimeBooking { get; set; }
    
    public decimal Amount { get; set; }
    public DateTime PaymentDate { get; set; }
    
    [MaxLength(500)]
    public string? Notes { get; set; }
}
