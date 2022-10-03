Connect-AzureAD



$Template = Get-AzureADDirectorySettingTemplate | Where-Object {$_.DisplayName -eq 'Group.Unified'}
$Setting = $Template.CreateDirectorySetting()
New-AzureADDirectorySetting -DirectorySetting $Setting
$Setting = Get-AzureADDirectorySetting -Id (Get-AzureADDirectorySetting | Where-Object -Property DisplayName -Value "Group.Unified" -EQ).id
$Setting["EnableGroupCreation"] = $False
$Setting["GroupCreationAllowedGroupId"] = (Get-AzureADGroup -SearchString "AAD-M365-GruppSkapare").objectid
Set-AzureADDirectorySetting -Id (Get-AzureADDirectorySetting | Where-Object -Property DisplayName -Value "Group.Unified" -EQ).id -DirectorySetting $Setting


# (Get-AzureADDirectorySetting).Values