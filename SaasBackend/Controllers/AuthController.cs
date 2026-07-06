using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using SaasBackend.Data;
using SaasBackend.Models.DTOs;
using SaasBackend.Models.Entities;

namespace SaasBackend.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly AppDbContext _context;
    private readonly IConfiguration _configuration;

    public AuthController(UserManager<ApplicationUser> userManager, AppDbContext context, IConfiguration configuration)
    {
        _userManager = userManager;
        _context = context;
        _configuration = configuration;
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginRequest request)
    {
        // Support login by email OR username
        var identifier = request.Email?.Trim();
        if (string.IsNullOrEmpty(identifier))
            return BadRequest(new { message = "Email or username is required." });

        ApplicationUser? user;

        // If identifier looks like an email (contains @), search by email first
        if (identifier.Contains('@'))
        {
            user = await _userManager.FindByEmailAsync(identifier);
        }
        else
        {
            // Otherwise search by username (Identity UserName)
            user = await _userManager.FindByNameAsync(identifier);
        }

        // Fallback 1: try the other lookup if first one failed
        user ??= await _userManager.FindByNameAsync(identifier);
        user ??= await _userManager.FindByEmailAsync(identifier);

        // Fallback 2: allow logging in with the prefix of the email (e.g., 'qusai' for 'qusai@gmail.com')
        user ??= await _userManager.Users.FirstOrDefaultAsync(u => u.Email.StartsWith(identifier + "@"));

        // Fallback 3: allow logging in by exact Full Name (case-insensitive)
        user ??= await _userManager.Users.FirstOrDefaultAsync(u => u.FullName.ToLower() == identifier.ToLower());

        if (user == null || !await _userManager.CheckPasswordAsync(user, request.Password))
        {
            return Unauthorized(new { message = "Invalid email/username or password." });
        }

        // Fetch Tenant Type from DB bypassing Global Query Filters
        var tenant = await _context.Tenants.IgnoreQueryFilters().FirstOrDefaultAsync(t => t.Id == user.TenantId);

        var roles = await _userManager.GetRolesAsync(user);
        var userRole = roles.FirstOrDefault() ?? "Employee";

        var permissions = await _context.UserPagePermissions
            .IgnoreQueryFilters()
            .FirstOrDefaultAsync(p => p.UserId == user.Id);

        if (permissions == null)
        {
            permissions = new UserPagePermission
            {
                UserId = user.Id,
                TenantId = user.TenantId,
                CanAccessDashboard = userRole != "Employee",
                CanAccessCalendar = true,
                CanAccessPOS = true,
                CanAccessSubscriptions = true,
                CanAccessUsers = userRole != "Employee",
                CanAccessFinance = userRole != "Employee",
                CanAccessCustomers = true,
                CanAccessSettings = true
            };
            _context.UserPagePermissions.Add(permissions);
            await _context.SaveChangesAsync();
        }

        // Generate JWT
        var tokenHandler = new JwtSecurityTokenHandler();
        var key = Encoding.ASCII.GetBytes(_configuration["Jwt:Secret"] ?? "this_is_a_very_long_and_secure_secret_key_for_development_only");
        var tokenDescriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(new[]
            {
                new Claim(JwtRegisteredClaimNames.Sub, user.Id),
                new Claim(JwtRegisteredClaimNames.Email, user.Email!),
                new Claim("TenantId", user.TenantId.ToString()),
                new Claim("TenantType", tenant?.Type.ToString() ?? "Pool"),
                new Claim("Role", userRole),
                new Claim("FullName", user.FullName ?? "")
            }),
            Expires = DateTime.UtcNow.AddDays(7),
            SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256Signature)
        };

        var token = tokenHandler.CreateToken(tokenDescriptor);
        var jwt = tokenHandler.WriteToken(token);

        return Ok(new AuthResponse
        {
            Token = jwt,
            Email = user.Email!,
            Role = userRole,
            TenantType = tenant?.Type.ToString() ?? "Pool",
            Permissions = new UserPagePermissionDto
            {
                CanAccessDashboard = permissions.CanAccessDashboard,
                CanAccessCalendar = permissions.CanAccessCalendar,
                CanAccessPOS = permissions.CanAccessPOS,
                CanAccessSubscriptions = permissions.CanAccessSubscriptions,
                CanAccessUsers = permissions.CanAccessUsers,
                CanAccessFinance = permissions.CanAccessFinance,
                CanAccessCustomers = permissions.CanAccessCustomers,
                CanAccessSettings = permissions.CanAccessSettings
            }
        });
    }
}
