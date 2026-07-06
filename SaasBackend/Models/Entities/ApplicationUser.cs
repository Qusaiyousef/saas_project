using Microsoft.AspNetCore.Identity;
using SaasBackend.Models.Interfaces;

namespace SaasBackend.Models.Entities;

public class ApplicationUser : IdentityUser, ITenantEntity
{
    public Guid TenantId { get; set; }
    public Tenant? Tenant { get; set; }
    
    public string FullName { get; set; } = string.Empty;
}
