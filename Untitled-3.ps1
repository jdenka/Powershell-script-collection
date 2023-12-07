<#
This function requires you to connecto to Graph with Connect-MgGraph -Scopes "User.Read.All, AuditLog.Read.All"
#>
function Get-LastSuccessfulSignin {
    param (
        $upn
    )
    # User lookup
    try {
        $u = Get-MgUser -UserId $upn -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to get a user with UPN: $($upn)"
        break
    }
    # Getting users last successfull logon
    $useruri = "https://graph.microsoft.com/beta/users/$($u.Id)"
    $searchuri = '?$select=signInActivity'
    $uri = $useruri+$searchuri
    try {
        $result = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop
        Write-Output "Last successful signin from user $($upn) `n $($result.signInActivity.lastSuccessfulSignInDateTime) `n Last successful non interactive signin `n $($result.signInActivity.lastNonInteractiveSignInDateTime)"
    }
    catch {
        Write-Error "Failed to get last successful signin for user $($upn)"
    }

}