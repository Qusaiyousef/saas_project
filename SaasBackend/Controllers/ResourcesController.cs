using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SaasBackend.Data;
using SaasBackend.Services;

namespace SaasBackend.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ResourcesController : ControllerBase
{
    private readonly AppDbContext _context;

    public ResourcesController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet("default")]
    public async Task<IActionResult> GetDefaultResource()
    {
        var resource = await _context.Resources.FirstOrDefaultAsync();
        if (resource == null) return NotFound(new { message = "No resource found for this tenant." });
        return Ok(resource);
    }
}
