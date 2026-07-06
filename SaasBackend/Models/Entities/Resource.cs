using System.ComponentModel.DataAnnotations;
using SaasBackend.Models.Interfaces;

namespace SaasBackend.Models.Entities;

public class Resource : ITenantEntity
{
    [Key]
    public Guid Id { get; set; }
    
    public Guid TenantId { get; set; }
    public Tenant? Tenant { get; set; }
    
    [Required]
    [MaxLength(200)]
    public string Name { get; set; } = string.Empty;
    
    // Capacity for Gym/Pool (High), Capacity for Chalet (1)
    public int Capacity { get; set; }
    
    public ICollection<PricingPlan> PricingPlans { get; set; } = new List<PricingPlan>();
    public ICollection<TimeBooking> Bookings { get; set; } = new List<TimeBooking>();
    public ICollection<Subscription> Subscriptions { get; set; } = new List<Subscription>();
}
