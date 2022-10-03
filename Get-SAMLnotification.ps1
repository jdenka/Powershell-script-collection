Connect-MgGraph -Scopes "Application.Read.All"
Get-MgServicePrincipal -Filter "tags/any(t:t eq 'WindowsAzureActiveDirectoryIntegratedApp')" -All `
| Where-Object { $_.PreferredTokenSigningKeyThumbprint } | Select-Object AppDisplayName, AppId, PreferredSingleSignOnMode, NotificationEmailAddresses