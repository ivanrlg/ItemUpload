codeunit 53104 InstallCodeunit
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
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
        TenantWebService.Insert();

    end;

}