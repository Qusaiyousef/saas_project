using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SaasBackend.Models.Entities;
using SaasBackend.Services;
using System.IdentityModel.Tokens.Jwt;
using SaasBackend.Data;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.DependencyInjection;

namespace SaasBackend.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class UsersController : ControllerBase
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly ITenantProvider _tenantProvider;
    private readonly AppDbContext _context;
    private readonly IMemoryCache _cache;

    public UsersController(UserManager<ApplicationUser> userManager, ITenantProvider tenantProvider, AppDbContext context, IMemoryCache cache)
    {
        _userManager = userManager;
        _tenantProvider = tenantProvider;
        _context = context;
        _cache = cache;
    }

    // GET /api/users — List all users in the same tenant
    [HttpGet]
    public async Task<IActionResult> GetUsers()
    {
        var tenantId = _tenantProvider.GetTenantId();
        if (!tenantId.HasValue) return Unauthorized();

        var users = await _userManager.Users
            .Where(u => u.TenantId == tenantId.Value)
            .AsNoTracking()
            .ToListAsync();

        var permissionsList = await _context.UserPagePermissions
            .Where(p => p.TenantId == tenantId.Value)
            .AsNoTracking()
            .ToListAsync();

        var userIds = users.Select(u => u.Id).ToList();
        var userRoles = await (from ur in _context.UserRoles
                               join r in _context.Roles on ur.RoleId equals r.Id
                               where userIds.Contains(ur.UserId)
                               select new { ur.UserId, RoleName = r.Name })
                               .AsNoTracking()
                               .ToListAsync();

        var result = new List<object>();
        foreach (var user in users)
        {
            var role = userRoles.FirstOrDefault(ur => ur.UserId == user.Id)?.RoleName ?? "Employee";
            var permissions = permissionsList.FirstOrDefault(p => p.UserId == user.Id);

            result.Add(new
            {
                id = user.Id,
                email = user.Email,
                fullName = user.FullName,
                userName = user.UserName,
                role = role,
                permissions = new
                {
                    canAccessDashboard = permissions?.CanAccessDashboard ?? (role != "Employee"),
                    canAccessCalendar = permissions?.CanAccessCalendar ?? true,
                    canAccessPOS = permissions?.CanAccessPOS ?? true,
                    canAccessSubscriptions = permissions?.CanAccessSubscriptions ?? true,
                    canAccessUsers = permissions?.CanAccessUsers ?? (role != "Employee"),
                    canAccessFinance = permissions?.CanAccessFinance ?? (role != "Employee"),
                    canAccessCustomers = permissions?.CanAccessCustomers ?? true,
                    canAccessSettings = permissions?.CanAccessSettings ?? true
                }
            });
        }

        return Ok(result);
    }

    // POST /api/users — Create a new user within the current tenant
    [HttpPost]
    public async Task<IActionResult> CreateUser([FromBody] CreateUserRequest request)
    {
        var tenantId = _tenantProvider.GetTenantId();
        if (!tenantId.HasValue) return Unauthorized();

        // SAFETY: Only Admins can create users
        var currentUserId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value
                         ?? User.FindFirst(JwtRegisteredClaimNames.Sub)?.Value
                         ?? User.FindFirst("sub")?.Value;
        
        var currentUser = await _userManager.FindByIdAsync(currentUserId!);
        var currentUserRoles = await _userManager.GetRolesAsync(currentUser!);
        if (!currentUserRoles.Contains("Admin"))
        {
            return BadRequest(new { message = "You do not have permission to create users." });
        }

        // Check for existing email
        var existing = await _userManager.FindByEmailAsync(request.Email);
        if (existing != null)
            return Conflict(new { message = "A user with this email already exists." });

        var user = new ApplicationUser
        {
            UserName = request.Email,
            Email = request.Email,
            FullName = request.FullName,
            TenantId = tenantId.Value,
            EmailConfirmed = true
        };

        var result = await _userManager.CreateAsync(user, request.Password);
        if (!result.Succeeded)
        {
            var errors = string.Join(", ", result.Errors.Select(e => e.Description));
            return BadRequest(new { message = errors });
        }

        // Assign role (only Admin or Employee allowed)
        var role = request.Role == "Admin" ? "Admin" : "Employee";
        await _userManager.AddToRoleAsync(user, role);

        // Add permissions
        var permissions = new UserPagePermission
        {
            UserId = user.Id,
            TenantId = tenantId.Value,
            CanAccessDashboard = request.Permissions?.CanAccessDashboard ?? (role != "Employee"),
            CanAccessCalendar = request.Permissions?.CanAccessCalendar ?? true,
            CanAccessPOS = request.Permissions?.CanAccessPOS ?? true,
            CanAccessSubscriptions = request.Permissions?.CanAccessSubscriptions ?? true,
            CanAccessUsers = request.Permissions?.CanAccessUsers ?? (role != "Employee"),
            CanAccessFinance = request.Permissions?.CanAccessFinance ?? (role != "Employee"),
            CanAccessCustomers = request.Permissions?.CanAccessCustomers ?? true,
            CanAccessSettings = request.Permissions?.CanAccessSettings ?? true
        };
        _context.UserPagePermissions.Add(permissions);
        await _context.SaveChangesAsync();

        return Ok(new
        {
            id = user.Id,
            email = user.Email,
            fullName = user.FullName,
            userName = user.UserName,
            role,
            permissions = new
            {
                canAccessDashboard = permissions.CanAccessDashboard,
                canAccessCalendar = permissions.CanAccessCalendar,
                canAccessPOS = permissions.CanAccessPOS,
                canAccessSubscriptions = permissions.CanAccessSubscriptions,
                canAccessUsers = permissions.CanAccessUsers,
                canAccessFinance = permissions.CanAccessFinance,
                canAccessCustomers = permissions.CanAccessCustomers,
                canAccessSettings = permissions.CanAccessSettings
            }
        });
    }

    // PUT /api/users/{id} — Update user name, email, or role
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateUser(string id, [FromBody] UpdateUserRequest request)
    {
        var tenantId = _tenantProvider.GetTenantId();
        if (!tenantId.HasValue) return Unauthorized();

        var user = await _userManager.FindByIdAsync(id);
        if (user == null || user.TenantId != tenantId.Value)
            return NotFound(new { message = "User not found." });

        var currentUserId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value
                         ?? User.FindFirst(JwtRegisteredClaimNames.Sub)?.Value
                         ?? User.FindFirst("sub")?.Value;

        var currentUser = await _userManager.FindByIdAsync(currentUserId!);
        var currentUserRoles = await _userManager.GetRolesAsync(currentUser!);
        var isCurrentUserAdmin = currentUserRoles.Contains("Admin");

        var targetUserRoles = await _userManager.GetRolesAsync(user);
        var isTargetUserAdmin = targetUserRoles.Contains("Admin");

        // SAFETY: Employee cannot modify an Admin account
        if (!isCurrentUserAdmin && isTargetUserAdmin)
        {
            return BadRequest(new { message = "You do not have permission to modify an Admin account." });
        }

        // SAFETY: Employee cannot modify user permissions
        if (!isCurrentUserAdmin && request.Permissions != null)
        {
            return BadRequest(new { message = "You do not have permission to modify user permissions." });
        }

        // Update fields
        user.FullName = request.FullName;
        user.Email = request.Email;
        user.UserName = request.Email;

        var updateResult = await _userManager.UpdateAsync(user);
        if (!updateResult.Succeeded)
        {
            var errors = string.Join(", ", updateResult.Errors.Select(e => e.Description));
            return BadRequest(new { message = errors });
        }

        // Update role if changed
        var currentRoles = await _userManager.GetRolesAsync(user);
        var newRole = request.Role == "Admin" ? "Admin" : "Employee";

        if (!currentRoles.Contains(newRole))
        {
            await _userManager.RemoveFromRolesAsync(user, currentRoles);
            await _userManager.AddToRoleAsync(user, newRole);
        }

        // Update password if provided
        if (!string.IsNullOrEmpty(request.Password))
        {
            var token = await _userManager.GeneratePasswordResetTokenAsync(user);
            var passResult = await _userManager.ResetPasswordAsync(user, token, request.Password);
            if (!passResult.Succeeded)
            {
                var errors = string.Join(", ", passResult.Errors.Select(e => e.Description));
                return BadRequest(new { message = errors });
            }
        }

        // Update permissions if provided
        var permissions = await _context.UserPagePermissions.FirstOrDefaultAsync(p => p.UserId == user.Id);
        if (permissions == null)
        {
            permissions = new UserPagePermission
            {
                UserId = user.Id,
                TenantId = tenantId.Value
            };
            _context.UserPagePermissions.Add(permissions);
        }

        if (request.Permissions != null)
        {
            permissions.CanAccessDashboard = request.Permissions.CanAccessDashboard;
            permissions.CanAccessCalendar = request.Permissions.CanAccessCalendar;
            permissions.CanAccessPOS = request.Permissions.CanAccessPOS;
            permissions.CanAccessSubscriptions = request.Permissions.CanAccessSubscriptions;
            permissions.CanAccessUsers = request.Permissions.CanAccessUsers;
            permissions.CanAccessFinance = request.Permissions.CanAccessFinance;
            permissions.CanAccessCustomers = request.Permissions.CanAccessCustomers;
            permissions.CanAccessSettings = request.Permissions.CanAccessSettings;
            await _context.SaveChangesAsync();
        }

        // Invalidate permissions cache for the updated user
        _cache.Remove($"Permissions_{id}");

        return Ok(new
        {
            id = user.Id,
            email = user.Email,
            fullName = user.FullName,
            userName = user.UserName,
            role = newRole,
            permissions = new
            {
                canAccessDashboard = permissions.CanAccessDashboard,
                canAccessCalendar = permissions.CanAccessCalendar,
                canAccessPOS = permissions.CanAccessPOS,
                canAccessSubscriptions = permissions.CanAccessSubscriptions,
                canAccessUsers = permissions.CanAccessUsers,
                canAccessFinance = permissions.CanAccessFinance,
                canAccessCustomers = permissions.CanAccessCustomers,
                canAccessSettings = permissions.CanAccessSettings
            }
        });
    }

    // DELETE /api/users/{id} — Delete user (prevent deleting the current logged-in admin)
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteUser(string id)
    {
        var tenantId = _tenantProvider.GetTenantId();
        if (!tenantId.HasValue) return Unauthorized();

        // Get current user ID from JWT
        var currentUserId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value
                         ?? User.FindFirst(JwtRegisteredClaimNames.Sub)?.Value
                         ?? User.FindFirst("sub")?.Value;

        var currentUser = await _userManager.FindByIdAsync(currentUserId!);
        var currentUserRoles = await _userManager.GetRolesAsync(currentUser!);
        var isCurrentUserAdmin = currentUserRoles.Contains("Admin");

        // SAFETY: Only Admins can delete users
        if (!isCurrentUserAdmin)
        {
            return BadRequest(new { message = "You do not have permission to delete users." });
        }

        // SAFETY: Prevent admin from deleting themselves
        if (!string.IsNullOrEmpty(currentUserId) && id == currentUserId)
            return BadRequest(new { message = "You cannot delete your own account." });

        var user = await _userManager.FindByIdAsync(id);
        if (user == null || user.TenantId != tenantId.Value)
            return NotFound(new { message = "User not found." });

        // SAFETY: Prevent deleting the last Admin in the tenant
        var userRoles = await _userManager.GetRolesAsync(user);
        if (userRoles.Contains("Admin"))
        {
            var adminCount = 0;
            var allUsers = await _userManager.Users.Where(u => u.TenantId == tenantId.Value).ToListAsync();
            foreach (var u in allUsers)
            {
                var roles = await _userManager.GetRolesAsync(u);
                if (roles.Contains("Admin")) adminCount++;
            }
            if (adminCount <= 1)
                return BadRequest(new { message = "Cannot delete the last Admin. At least one Admin must remain." });
        }

        var result = await _userManager.DeleteAsync(user);
        if (!result.Succeeded)
        {
            var errors = string.Join(", ", result.Errors.Select(e => e.Description));
            return BadRequest(new { message = errors });
        }

        // Invalidate permissions cache for the deleted user
        _cache.Remove($"Permissions_{id}");

        return Ok(new { message = "User deleted successfully." });
    }

    // GET /api/users/my-permissions — Get permissions for the logged-in user
    [HttpGet("my-permissions")]
    public async Task<IActionResult> GetMyPermissions()
    {
        var tenantId = _tenantProvider.GetTenantId();
        if (!tenantId.HasValue) return Unauthorized();

        var currentUserId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value
                         ?? User.FindFirst(JwtRegisteredClaimNames.Sub)?.Value
                         ?? User.FindFirst("sub")?.Value;

        if (string.IsNullOrEmpty(currentUserId)) return Unauthorized();

        var cacheKey = $"Permissions_{currentUserId}";

        var permissionDto = await _cache.GetOrCreateAsync(cacheKey, async entry =>
        {
            entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(5);

            var permissions = await _context.UserPagePermissions
                .IgnoreQueryFilters()
                .AsNoTracking()
                .FirstOrDefaultAsync(p => p.UserId == currentUserId);

            if (permissions == null)
            {
                var user = await _userManager.FindByIdAsync(currentUserId);
                var roles = await _userManager.GetRolesAsync(user!);
                var role = roles.FirstOrDefault() ?? "Employee";

                permissions = new UserPagePermission
                {
                    UserId = currentUserId,
                    TenantId = tenantId.Value,
                    CanAccessDashboard = role != "Employee",
                    CanAccessCalendar = true,
                    CanAccessPOS = true,
                    CanAccessSubscriptions = true,
                    CanAccessUsers = role != "Employee",
                    CanAccessFinance = role != "Employee",
                    CanAccessCustomers = true,
                    CanAccessSettings = true
                };
                _context.UserPagePermissions.Add(permissions);
                await _context.SaveChangesAsync();
            }

            return new SaasBackend.Models.DTOs.UserPagePermissionDto
            {
                CanAccessDashboard = permissions.CanAccessDashboard,
                CanAccessCalendar = permissions.CanAccessCalendar,
                CanAccessPOS = permissions.CanAccessPOS,
                CanAccessSubscriptions = permissions.CanAccessSubscriptions,
                CanAccessUsers = permissions.CanAccessUsers,
                CanAccessFinance = permissions.CanAccessFinance,
                CanAccessCustomers = permissions.CanAccessCustomers,
                CanAccessSettings = permissions.CanAccessSettings
            };
        });

        return Ok(permissionDto);
    }
}

// DTOs
public class CreateUserRequest
{
    public string Email { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string Role { get; set; } = "Employee";
    public SaasBackend.Models.DTOs.UserPagePermissionDto? Permissions { get; set; }
}

public class UpdateUserRequest
{
    public string Email { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string? Password { get; set; }
    public string Role { get; set; } = "Employee";
    public SaasBackend.Models.DTOs.UserPagePermissionDto? Permissions { get; set; }
}
