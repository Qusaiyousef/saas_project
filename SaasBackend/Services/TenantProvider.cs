namespace SaasBackend.Services;

public class TenantProvider : ITenantProvider
{
    private Guid? _tenantId;
    
    public Guid? GetTenantId()
    {
        return _tenantId;
    }

    public void SetTenantId(Guid tenantId)
    {
        _tenantId = tenantId;
    }
}
