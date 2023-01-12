Import-Module Microsoft.Graph.Users.Actions
Connect-MgGraph -ClientId XXXX -TenantId XXXX -CertificateThumbprint XXXX -ContextScope CurrentUser

function Send-AutomatedEmail {
    param(
        [Parameter (Mandatory = $false)]
        [bool]$Success = $false,
        [Parameter (Mandatory = $true)]
        [string]$Body
    )
    
    $Subject = "XXXX: "
    if ($Success) {
        $Subject = "$($Subject)Success"
    }
    else {
        $Subject = "$($Subject)Failed"
    }
    
    $from = "XXXX@xxxx.com"
    $to = "xxxx@xxxx.com"
    $type = "html"

    $recipients = @()
    $recipients += @{
        emailAddress = @{
            address = $To
        }
    }

    $message = @{
        subject      = $subject
        toRecipients = $recipients
    
        body         = @{
            contentType = $type
            content     = $body
        }
    }
    try {
        Send-MgUserMail -UserId $from -Message $message -ErrorAction Stop
        Write-Output "E-Mail sent to XXXX@XXXX.com!"
    }
    catch {
        Write-Error $Error[0]
    }
}