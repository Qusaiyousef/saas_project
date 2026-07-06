using System.ComponentModel.DataAnnotations;
using SaasBackend.Models.Interfaces;

namespace SaasBackend.Models.Entities;

public class Subscription : ITenantEntity
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
    
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    
    public SubscriptionStatus Status { get; set; } = SubscriptionStatus.Active;
    
    public decimal TotalAmount { get; set; }
    public decimal AmountPaid { get; set; }
}
