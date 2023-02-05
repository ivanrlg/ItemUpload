codeunit 53105 UpgradeCodeunit
{
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    var
        ModuleInfo: ModuleInfo;
        TenantWebService: Record "Tenant Web Service";
    begin
        NavApp.GetCurrentModuleInfo(ModuleInfo);

        TenantWebService.Init();
        TenantWebService."Object Type" := TenantWebService."Object Type"::Codeunit;
        TenantWebService."Object ID" := Codeunit::ProcessMethod;
        TenantWebService."Service Name" := 'ProcessMethod';
        TenantWebService.Published := true;
        if not TenantWebService.Insert() then
            TenantWebService.Modify();

    end;

}