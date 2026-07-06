using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SaasBackend.Migrations
{
    /// <inheritdoc />
    public partial class AddAmountPaid : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<decimal>(
                name: "AmountPaid",
                table: "TimeBookings",
                type: "decimal(18,2)",
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<decimal>(
                name: "AmountPaid",
                table: "Subscriptions",
                type: "decimal(18,2)",
                nullable: false,
                defaultValue: 0m);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "AmountPaid",
                table: "TimeBookings");

            migrationBuilder.DropColumn(
                name: "AmountPaid",
                table: "Subscriptions");
        }
    }
}
