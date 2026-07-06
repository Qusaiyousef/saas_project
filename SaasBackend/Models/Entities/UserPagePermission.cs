using System;
using SaasBackend.Models.Interfaces;

namespace SaasBackend.Models.Entities;

public class UserPagePermission : ITenantEntity
{
    public Guid Id { get; set; }
    public string UserId { get; set; } = string.Empty;
    public ApplicationUser? User { get; set; }

    // Page permission bits
    public bool CanAccessDashboard { get; set; } = true;
    public bool CanAccessCalendar { get; set; } = true;
    public bool CanAccessPOS { get; set; } = true;
    public bool CanAccessSubscriptions { get; set; } = true;
    public bool CanAccessUsers { get; set; } = true;
    public bool CanAccessFinance { get; set; } = true;
    public bool CanAccessCustomers { get; set; } = true;
    public bool CanAccessSettings { get; set; } = true;

    // Tenant support
    public Guid TenantId { get; set; }
    public Tenant? Tenant { get; set; }
}
