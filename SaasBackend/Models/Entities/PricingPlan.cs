using System.ComponentModel.DataAnnotations;
using SaasBackend.Models.Interfaces;

namespace SaasBackend.Models.Entities;

public class PricingPlan : ITenantEntity
{
    [Key]
    public Guid Id { get; set; }
    
    public Guid TenantId { get; set; }
    public Tenant? Tenant { get; set; }
    
    public Guid ResourceId { get; set; }
    public Resource? Resource { get; set; }
    
    public PlanType PlanType { get; set; }
    
    // Duration in minutes (e.g. 180 for 3 hours gym ticket), or null if not time-bound
    public int? DurationInMinutes { get; set; }
    
    [Required]
    public decimal Price { get; set; }
}
