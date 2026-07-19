using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SaasBackend.Migrations
{
    /// <inheritdoc />
    public partial class AddFingerprintIdToCustomer : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "FingerprintId",
                table: "Customers",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "FingerprintId",
                table: "Customers");
        }
    }
}
