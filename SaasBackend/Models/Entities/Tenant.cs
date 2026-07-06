using System.ComponentModel.DataAnnotations;

namespace SaasBackend.Models.Entities;

public class Tenant
{
    [Key]
    public Guid Id { get; set; }
    
    [Required]
    [MaxLength(200)]
    public string Name { get; set; } = string.Empty;
    
    public TenantType Type { get; set; }
    
    public bool IsActive { get; set; } = true;
    
    // Navigation properties
    public ICollection<Resource> Resources { get; set; } = new List<Resource>();
    public ICollection<ApplicationUser> Users { get; set; } = new List<ApplicationUser>();
}
