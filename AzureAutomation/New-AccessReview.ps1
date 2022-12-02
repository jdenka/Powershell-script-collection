# This creates an Access Review with quarterly reviews for a specific group.
# It has been tested to run in Azure Automation with Powershell 7.1
# Application permissions needed in the App Registrations are the following:
# Microsoft Graph. AccessReview.ReadWrite.All Group.Read.All User.Read.All 
# Store the application secret as a encrypted Automation Variable to make it more secure.
param
(
  [Parameter (Mandatory = $True)]
 	[string] $GroupName,

  [Parameter (Mandatory = $True)]
  [string] $DisplayName,

  [Parameter (Mandatory = $True)]
  [string] $Reviewer1,

  [Parameter (Mandatory = $True)]
  [string] $Reviewer2
)

# Connection details for the tenant.
$AppId = 'Application ID goes here'
$AppSecret = Get-AutomationVariable -Name 'AppSecret'
$Scope = "https://graph.microsoft.com/.default"
$TenantName = "Tenant domain goes here"

$Url = "https://login.microsoftonline.com/$TenantName/oauth2/v2.0/token"


# Add System.Web for urlencode
Add-Type -AssemblyName System.Web

# Create body for the exposed API
$Body = @{
  client_id     = $AppId
  client_secret = $AppSecret
  scope         = $Scope
  grant_type    = 'client_credentials'
}

# Splat the parameters for Invoke-Restmethod for cleaner code
$PostSplat = @{
  ContentType = 'application/x-www-form-urlencoded'
  Method      = 'POST'
  # Create string by joining bodylist with '&'
  Body        = $Body
  Uri         = $Url
}

# Request the token!
$Request = Invoke-RestMethod @PostSplat

$Header = @{
  Authorization = "$($Request.token_type) $($Request.access_token)"
}

# Get ObjectIds from Group and Reviewers
$grp = Invoke-RestMethod -Headers $header -uri "https://graph.microsoft.com/beta/groups?filter=(displayName +eq+ '$($groupname)')"
$rw1 = Invoke-RestMethod -Headers $header -uri "https://graph.microsoft.com/beta/users/$($Reviewer1)"
$rw2 = Invoke-RestMethod -Headers $header -uri "https://graph.microsoft.com/beta/users/$($Reviewer2)"

# Json code to create the review
$body = @"
{
  "displayName": "$($DisplayName)",
  "descriptionForAdmins": "New scheduled access review for group $($grp.value.DisplayName)",
  "descriptionForReviewers": "Review members of group $($grp.value.DisplayName)",
  "scope": {
    "@odata.type": "#microsoft.graph.accessReviewQueryScope",
    "query": "/groups/$($grp.value.id)/transitiveMembers",
    "queryType": "MicrosoftGraph"
  },
  "reviewers": [
    {
      "query": "/users/$($rw1.id)",
      "queryType": "MicrosoftGraph"
    },
    {
      "query": "/users/$($rw2.id)",
      "queryType": "MicrosoftGraph"
    }
  ],
  "settings": {
    "mailNotificationsEnabled": true,
    "reminderNotificationsEnabled": true,
    "justificationRequiredOnApproval": true,
    "defaultDecisionEnabled": false,
    "defaultDecision": "None",
    "instanceDurationInDays": 14,
    "recommendationsEnabled": true,
    "recurrence": {
      "pattern": {
        "type": "absoluteMonthly",
        "dayOfMonth": 0,
        "interval": 3
      },
      "range": {
        "type": "noEnd",
        "startDate": "2020-09-08T12:02:30.667Z"
      }
    }
  }
}
"@

# Uri to post json to
$apiUri = "https://graph.microsoft.com/beta/identityGovernance/accessReviews/definitions"

# Command to send everything and create the access review
Invoke-RestMethod -Headers $Header -Uri $apiUri -Body $body -Method POST -ContentType 'application/json'