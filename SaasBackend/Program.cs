using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using SaasBackend.Data;
using SaasBackend.Middleware;
using SaasBackend.Models.Entities;
using SaasBackend.Services;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllers();
builder.Services.AddMemoryCache();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Configure CORS - allow Flutter web app
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFlutter", policy =>
    {
        policy.WithOrigins(
                "http://localhost:3000",
                "http://localhost:4200",
                "http://localhost:5173",
                "http://localhost:8080",
                "http://localhost:52695"
            )
            .AllowAnyHeader()
            .AllowAnyMethod()
            .AllowCredentials();
        
        // For Flutter web during development, allow any origin
        policy.SetIsOriginAllowed(_ => true)
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

// Configure Database
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection") 
    ?? "Server=localhost,1433;Database=SaasDb;User Id=sa;Password=YourStrong@Passw0rd!;TrustServerCertificate=True;";
    
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(connectionString));

// Configure Scoped Tenant Provider
builder.Services.AddScoped<ITenantProvider, TenantProvider>();

// Configure Business Services
builder.Services.AddScoped<IBookingService, BookingService>();
builder.Services.AddScoped<ISubscriptionService, SubscriptionService>();

// Configure Identity
builder.Services.AddIdentity<ApplicationUser, IdentityRole>()
    .AddEntityFrameworkStores<AppDbContext>()
    .AddDefaultTokenProviders();

// Configure JWT Authentication
var jwtSecret = builder.Configuration["Jwt:Secret"] ?? "this_is_a_very_long_and_secure_secret_key_for_development_only";
var key = Encoding.ASCII.GetBytes(jwtSecret);

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.RequireHttpsMetadata = false;
    options.SaveToken = true;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(key),
        ValidateIssuer = false,
        ValidateAudience = false,
        RoleClaimType = "Role"
    };
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// MUST be before authentication
app.UseCors("AllowFlutter");

// Remove HTTPS redirect to avoid issues in dev
// app.UseHttpsRedirection();

app.UseDefaultFiles();
app.UseStaticFiles();

app.UseAuthentication();

// Insert Tenant Middleware after Authentication but before Authorization
app.UseMiddleware<TenantMiddleware>();

app.UseAuthorization();

app.MapControllers();
app.MapFallbackToFile("index.html");

// Seed Default Users
using (var scope = app.Services.CreateScope())
{
    await SaasBackend.DataSeeder.SeedDataAsync(scope.ServiceProvider);
}

app.Run();
