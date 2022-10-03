$notificationEmailToAdd = "test@example.com"

Connect-MgGraph -Scopes "Application.ReadWrite.All"
Get-MgServicePrincipal -Filter "tags/any(t:t eq 'WindowsAzureActiveDirectoryIntegratedApp')" -All `
| Where-Object { $_.PreferredTokenSigningKeyThumbprint -and $_.notificationEmailAddresses -notcontains $notificationEmailToAdd } `
| ForEach-Object { 
    Write-Host "Adding notification email to $($_.DisplayName) ($($_.AppId))..."
    $_.notificationEmailAddresses += $notificationEmailToAdd
    Update-MgServicePrincipal -ServicePrincipalId $_.Id `
                              -NotificationEmailAddresses $_.NotificationEmailAddresses
}