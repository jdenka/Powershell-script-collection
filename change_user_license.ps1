$Users = Get-AzureADGroupMember -ObjectId 465676e1-c14a-4005-9151-163e9db824e4
$License = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicense
$License.SkuId = "6fd2c87f-b296-42f0-b197-1e91e994b900"
$LicensesToAssign = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicenses
$LicensesToAssign.AddLicenses = @()
$LicensesToAssign.RemoveLicenses = $License.SkuId
foreach($Users in $users) { Set-AzureADUserLicense -ObjectId $Users.ObjectId -AssignedLicenses $LicensesToAssign }