$scope = @(
    "AppRoleAssignment.ReadWrite.All" # Required scope to connect to Graph to set permissions to the Managed Identity
)

Connect-MgGraph -Scopes $scope

$MIName = "" # Name of the Managed Identity

$Permissions = @( # Permissions to be set to the Managed Identity
    "User.Read.All"
    "Group.Read.All"
    "GroupMember.Read.All"
)

$GraphAppId = "00000003-0000-0000-c000-000000000000" # Application ID of the Graph API
$MI = Get-MgServicePrincipal -Filter "displayName eq '$MIName'" # Get the Managed Identity
$GraphSP = Get-MgServicePrincipal -Filter "appId eq '$GraphAppId'" # Get the Graph API Service Principal

$AppRole = $GraphSP.Approles | Where-Object { $_.Value -in $Permissions } # Get the AppRole object for the permissions

foreach($Role in $AppRole) {
    $ApproleAssignment = @{
        "PrincipalId" = $MI.Id
        "ResourceId" = $GraphSP.Id
        "AppRoleId" = $Role.Id
    }
    New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $ApproleAssignment.PrincipalId -AppRoleAssignment $ApproleAssignment -Verbose
}
