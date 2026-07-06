namespace SaasBackend.Models;

public enum TenantType
{
    Chalet,
    Gym,
    Pool
}

public enum PlanType
{
    Block,
    TimeBased,
    Subscription
}

public enum BookingStatus
{
    Confirmed,
    Cancelled,
    Completed
}

public enum SubscriptionStatus
{
    Active,
    Expired,
    Suspended
}
