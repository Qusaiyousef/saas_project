using System.Security.Claims;
using SaasBackend.Services;

namespace SaasBackend.Middleware;

public class TenantMiddleware
{
    private readonly RequestDelegate _next;

    public TenantMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context, ITenantProvider tenantProvider)
    {
        // Try to get TenantId from User Claims (JWT)
        var tenantIdClaim = context.User.FindFirst("TenantId")?.Value;
        
        // As a fallback for testing without auth, you could read from a custom header
        if (string.IsNullOrEmpty(tenantIdClaim))
        {
            tenantIdClaim = context.Request.Headers["X-Tenant-ID"].FirstOrDefault();
        }

        if (!string.IsNullOrEmpty(tenantIdClaim) && Guid.TryParse(tenantIdClaim, out var tenantId))
        {
            tenantProvider.SetTenantId(tenantId);
        }

        await _next(context);
    }
}
