<#
This function requires you to connecto to Graph with Connect-MgGraph -Scopes "User.Read.All, AuditLog.Read.All"
#>
function Get-LastSuccessfulSignin {
    param (
        $user
    )
    # Check Connection To Graph
    $context = Get-MgContext
    if ([string]::IsNullOrEmpty($context)) {
        Write-Error "Please connect to Microsoft Graph.."
        break
    }
    if ($user -gt 1) {
        foreach ($mu in $user) {
            # User lookup
            try {
                $u = Get-MgUser -UserId $mu -ErrorAction Stop
            }
            catch {
                Write-Error "Failed to get a user with UPN/ID: $($mu)"
            }
            # Getting users last successfull logon
            $uri = "https://graph.microsoft.com/beta/users/$($u.Id)?select=signInActivity"
            try {
                $result = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop
                Write-Output "Last successful sign in from user $($u.UserPrincipalName) `n $($result.signInActivity.lastSuccessfulSignInDateTime) `n Last successful non interactive sign in `n $($result.signInActivity.lastNonInteractiveSignInDateTime)"
            }
            catch {
                Write-Error "Failed to get last successful sign in for user $($u.UserPrincipalName)"
            }
        }
    }
    else {
        # User lookup
        try {
            $u = Get-MgUser -UserId $user -ErrorAction Stop
        }
        catch {
            Write-Error "Failed to get a user with UPN/ID: $($user)"
            break
        }
        # Getting users last successfull logon
        $uri = "https://graph.microsoft.com/beta/users/$($u.Id)?select=signInActivity"
        try {
            $result = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop
            Write-Output "Last successful sign in from user $($u.UserPrincipalName) `n $($result.signInActivity.lastSuccessfulSignInDateTime) `n Last successful non interactive sign in `n $($result.signInActivity.lastNonInteractiveSignInDateTime)"
        }
        catch {
            Write-Error "Failed to get last successful sign in for user $($u.UserPrincipalName)"
        }
    }
}