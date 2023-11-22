<#
.DESCRIPTION
This script will lookup new company joiners in the old company tenant to set rules automatically.
It will lookup the old account based on information in the Webhookdata, if it finds the correct information it will lookup the user with the employee id.
It Invites the new company account as a guest and adds them to a group that is excluded from Conditional Access and gives access to the information site.
It automatically sets email forwarding, blocking external federation in teams and teams meetings. 
It also adds an autoreply in on the users mailbox and hands out the users credentials in thier old company mailbox.
Uses a App Registration in Entra ID cause the teams module does not worh properly with Managed Identities and -Cs* commands.
#>

param
(
    [Parameter (Mandatory = $false)]
    [object] $WebhookData
)

if ($WebhookData) {
    Write-Output "Header recived:"
    Write-Output $WebhookData.RequestHeader.message
    if ($WebhookData.RequestHeader.message -eq 'Webhook required header') {
        Write-Output "Header has required information"
    }
    else {
        Throw "Header missing required information";
    }
}
else {
    Throw "No webhook data recived"
}
    
$bodyData = ConvertFrom-Json -InputObject $WebHookData.RequestBody
$appid = 'ClientID of the App registration'
$tenantid = 'Entra ID tenant id'
$certthumb = 'Certificate thumbprint for the App registration'
$GroupID = 'ObjectId of Group for the Guest account' ## GuestGroup



Import-Module -Name Microsoft.Graph.Authentication
Import-Module -Name Microsoft.Graph.Identity.Signins
Import-Module -Name Microsoft.Graph.Users.Actions
Import-Module -Name Microsoft.Graph.Users
Import-Module -Name MicrosoftTeams
Import-Module -Name ExchangeOnlineManagement


<#
    Different kind of connections needed
    Graph, ExchangeOnline, MicrosoftTeams
#>

try {
    Connect-MgGraph -Identity -ErrorAction Stop
}
catch {
    Write-Error "Failed to connect to Microsoft Graph, exiting"
    return
}

try {
    Write-Output "Connecting to Exchange Online"
    Connect-ExchangeOnline -ManagedIdentity -Organization yourdomain.onmicrosoft.com -ErrorAction Stop
}
catch {
    Write-Error "Failed to connect to Exchange Online"
    return
}

try {
    Connect-MicrosoftTeams -CertificateThumbprint $certthumb -ApplicationId $appid -TenantId $tenantid -ErrorAction Stop
    Write-Output "Connected to Microsoft Teams"
}
catch {
    Write-Error "Failed to connect to Microsoft Teams"
    return
}

function Send-AutomatedEmail {
    param(
        [Parameter (Mandatory = $true)]
        [string]$Body,
        [Parameter (Mandatory = $true)]
        [string]$to
    )
    
    $Subject = $tosubject
    
    $from = $fromemail
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
        Send-MgUserMail -UserId $from -Message $message -SaveToSentItems:$false -ErrorAction Stop  
    }
    catch {
        Write-Error $Error[0]
    }
}

$users = @()
foreach ($l in $bodyData) { 
    if ($l.ID -like "*COMPANY_*") {
        $empid = ($l.ID).Trim("COMPANY_")
            $u = Get-MgBetaUser -Search "EmployeeId:$($empid)" -ConsistencyLevel eventual
            if ($u.AdditionalProperties.extension_RandomString_CustomAttribute -eq "Redacted") {
                Write-Output "User $($u.UserPrincipalName) has value **Redacted**"
            }
            if ([string]::IsNullOrEmpty($u)) {
                Write-Output "$($l.UPN) is not a synced user."
            } 
            else {
                $users += [PSCustomObject]@{
                    Mail       = $u.UserPrincipalName
                    UserPrincipalName = $l.UPN
                    Password          = $l.Password
                }
            }
    }
    else { 
        Write-Output "User: $($l.UPN) does not have a Company ID"
    }
}

foreach ($user in $users) {
    $tosubject = "Company user information"
    $to = $user.Mail
    $fromemail = $user.Mail
    $body = "Dear Colleague<br><br>
    This email contains your new Company account information and a link to the Company information site, a SharePoint page containing IT guides to help you transition into the new Company IT environment.<br><br>
    Username: $($user.UserPrincipalName)<br>
    Password: $($user.Password)<br><br>
    Link to Company Site: https://company.sharepoint.com/sites/YOURSITE<br><br>
    Kind Regards <br>
    Company IT
    "
    try {
        Send-AutomatedEmail -to $to -Body $body -ErrorAction Stop
    }
    catch {
        Write-Error "Can't send mail to OLDMail: $($user.Mail) - NEWMail: $($user.UserPrincipalName)"        
    }
}

Start-Sleep -Seconds 15
$inviteduser = @()

foreach ($user in $users) {
    try {
        $params = @{
            invitedUserEmailAddress = "$($user.UserPrincipalName)"
            inviteRedirectUrl       = "https://myapplications.microsoft.com/?tenantid=$($tenantid)"
            sendInvitationMessage   = "true"
        }
        New-MgInvitation -BodyParameter $params -ErrorAction Stop
        $inviteduser += [PSCustomObject]@{
            UPN = $user.UserPrincipalName
        }
    }
    catch {
        Write-Error "Failed to invite $($user.UserPrincipalName)"
    }   
}

foreach ($mbx in $users) {
    try {
        Write-Output "Setting forwarding rule on mailbox $($mbx.Mail)"
        Set-Mailbox -Identity $mbx.Mail -ForwardingSmtpAddress $mbx.UserPrincipalName -DeliverToMailboxAndForward $false -ErrorAction Stop 
    }
    catch {
        Write-Error "Failed to set forwarding rule on mailbox $($mbx.Mail)"
    }
    Start-Sleep -Seconds 1
    try {
        Grant-CsExternalAccessPolicy -Identity $mbx.Mail -PolicyName "Company-NoFederation" 
        Write-Output "External Access policy set successfully"
    }
    catch {
        Write-Error "Failed to set External Access policy on $($mbx.Mail)"
    }
    Start-Sleep -Seconds 1
    try {
        Grant-CsTeamsMeetingPolicy -Identity $mbx.Mail -PolicyName "Company-Standard-NoExternalAccess" 
        Write-Output "Meeting Policy set successfully"
    }
    catch {
        Write-Error "Failed to set Meeting policy on $($mbx.Mail)"
    }
    Start-Sleep -Seconds 1
    try {
        Grant-CsTeamsChannelsPolicy -Identity $mbx.Mail -PolicyName "Company-Standard-NoExternalAccess" 
        Write-Output "Channel Policy set successfully"
    }
    catch {
        Write-Error "Failed to set Channel policy on $($mbx.Mail)"
    }
}

foreach ($user in $users) {
    try {
        $h = Get-MgUser -UserId $user.Mail -ErrorAction Stop
    }
    catch {
        Write-Error "Cannot fetch user $($user)"

    }
    foreach ($mail in $h) {
        try {
            $u = Get-Mailbox -Identity $mail.UserPrincipalName
            if ($u.ForwardingSmtpAddress) {
                $Newmail = $u.ForwardingSmtpAddress -replace '^smtp:'
                $message = "<html><body>Thank you for your message. Due to the recent acquisition by new company, my old company email is no longer active and your message has been forwarded to my new company email address: $($Newmail)"
                Set-MailboxAutoReplyConfiguration -Identity $u.SamAccountName -AutoReplyState Enabled -InternalMessage $message -ExternalMessage $message -ExternalAudience All 
                Write-Output "Successfully set autoreply message on user: $($mail.UserPrincipalName)"
            }
            else {
                Write-Error "User: $($mail.UserPrincipalName) does not have a Forwarding address. Autoreply wont be applied."
            }
        }
        catch {
            Write-Error "Failed to get mailbox: $($mail)"
        }
    }
}
$group = Get-MgGroupMember -GroupId $groupid -all
foreach ($iu in $inviteduser) {
    Start-Sleep -Seconds 45
    try {
        $u = Get-MgUser -search "Mail:$($iu.UPN)" -ConsistencyLevel eventual
        if ($u.id -notin $group.Id) {
            New-MgGroupMember -GroupId $GroupID -DirectoryObjectId $u.Id -ErrorAction Stop 
            Write-Output "Added user $($iu.UPN) to group."
        }
        else {
            Write-Output "$($iu.UPN) is already a member of the group"
        }
    }
    catch {
        Write-Error "Failed to add $($iu.UPN) to Group"
    }
}

if ($error -eq $true) {
    $tosubject = "New-UserFlow - Failure in automated flow"
    $fromemail = 'noreply@company.onmicrosoft.com.com'
    $to = 'IAMteam@company.onmicrosoft.com'
    $body = "Dear Identity teammember<br><br>
            One or more actions failed, please check runbook.<br>
            Kind regards<br>
            The Identity team"
    Send-AutomatedEmail -to $to -Body $body -ErrorAction Stop
}
else {
    Write-Output "Workflow run successfully"
}