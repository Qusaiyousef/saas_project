namespace SaasBackend.Models.DTOs;

public class UserPagePermissionDto
{
    public bool CanAccessDashboard { get; set; }
    public bool CanAccessCalendar { get; set; }
    public bool CanAccessPOS { get; set; }
    public bool CanAccessSubscriptions { get; set; }
    public bool CanAccessUsers { get; set; }
    public bool CanAccessFinance { get; set; }
    public bool CanAccessCustomers { get; set; }
    public bool CanAccessSettings { get; set; }
}
