using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SaasBackend.Migrations
{
    /// <inheritdoc />
    public partial class AddUserPagePermissions : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "UserPagePermissions",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    UserId = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    CanAccessDashboard = table.Column<bool>(type: "bit", nullable: false),
                    CanAccessCalendar = table.Column<bool>(type: "bit", nullable: false),
                    CanAccessPOS = table.Column<bool>(type: "bit", nullable: false),
                    CanAccessSubscriptions = table.Column<bool>(type: "bit", nullable: false),
                    CanAccessUsers = table.Column<bool>(type: "bit", nullable: false),
                    CanAccessFinance = table.Column<bool>(type: "bit", nullable: false),
                    CanAccessCustomers = table.Column<bool>(type: "bit", nullable: false),
                    CanAccessSettings = table.Column<bool>(type: "bit", nullable: false),
                    TenantId = table.Column<Guid>(type: "uniqueidentifier", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserPagePermissions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_UserPagePermissions_AspNetUsers_UserId",
                        column: x => x.UserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_UserPagePermissions_Tenants_TenantId",
                        column: x => x.TenantId,
                        principalTable: "Tenants",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_UserPagePermissions_TenantId",
                table: "UserPagePermissions",
                column: "TenantId");

            migrationBuilder.CreateIndex(
                name: "IX_UserPagePermissions_UserId",
                table: "UserPagePermissions",
                column: "UserId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "UserPagePermissions");
        }
    }
}
