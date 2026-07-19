using System.ComponentModel.DataAnnotations;
using SaasBackend.Models.Interfaces;

namespace SaasBackend.Models.Entities;

public class Customer : ITenantEntity
{
    [Key]
    public Guid Id { get; set; }
    
    public Guid TenantId { get; set; }
    public Tenant? Tenant { get; set; }
    
    [Required]
    [MaxLength(200)]
    public string Name { get; set; } = string.Empty;
    
    [MaxLength(20)]
    public string? Phone { get; set; }
    
    [MaxLength(100)]
    public string? FingerprintId { get; set; }
    
    public DateTime? DateOfBirth { get; set; }
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    public bool IsDeleted { get; set; } = false;
}
