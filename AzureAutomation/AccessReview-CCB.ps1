# Application permissions needed in the App Registrations are the following:
# Microsoft Graph. AccessReview.ReadWrite.All Group.Read.All User.Read.All 
# Store the application secret as a encrypted Automation Variable to make it more secure.
param
(
    [Parameter (Mandatory = $True)]
    [string] $GroupName
)

# Connection details for the tenant.
$AppId = 'AppID med behörigheter'
$AppSecret = 'Förslår att använda Azure automation encrypted variable'
$Scope = "https://graph.microsoft.com/.default"
$TenantName = "Ändra till tenantnamn"

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

# Get ObjectIds from Group 
$grp = Invoke-RestMethod -Headers $header -uri "https://graph.microsoft.com/beta/groups?filter=(displayName +eq+ '$($groupname)')"

# Set the Notification group
$NotificationGroup = 'Users-Sec-Gov'
$notgrp = Invoke-RestMethod -Headers $header -uri "https://graph.microsoft.com/beta/groups?filter=(displayName +eq+ '$($NotificationGroup)')"


# Json code to create the review
$body = @"
{
    "displayName": "Guest access review for Team: $($grp.value.DisplayName)",
    "descriptionForAdmins": "Guest access review for Team: $($grp.value.DisplayName)",
    "descriptionForReviewers": "Guest access review for Team: $($grp.value.DisplayName)",
    "scope": {
        "@odata.type": "#microsoft.graph.accessReviewQueryScope",
        "query": "/beta/groups/$($grp.value.id)/transitiveMembers/microsoft.graph.user/?$count=true&$filter=(userType eq 'Guest')",
        "queryType": "MicrosoftGraph",
        "queryRoot": null
    },
    "reviewers": [
        {
            "query": "./owners",
            "queryType": "MicrosoftGraph",
            "queryRoot": null
        }
    ],
    "settings": {
        "mailNotificationsEnabled": true,
        "reminderNotificationsEnabled": true,
        "justificationRequiredOnApproval": true,
        "defaultDecisionEnabled": true,
        "defaultDecision": "Recommendation",
        "instanceDurationInDays": 14,
        "autoApplyDecisionsEnabled": true,
        "recommendationsEnabled": true,
        "recurrence": {
            "pattern": {
                "type": "absoluteMonthly",
                "interval": 3,
                "month": 0,
                "dayOfMonth": 0,
                "daysOfWeek": [],
                "firstDayOfWeek": "sunday",
                "index": "first"
            },
            "range": {
                "type": "noEnd",
                "numberOfOccurrences": 0,
                "recurrenceTimeZone": null,
                "startDate": "2021-02-10",
                "endDate": "9999-12-21"
            }
        },
        "applyActions": [
            {
                "@odata.type": "#microsoft.graph.removeAccessApplyAction"
            }
        ]
    },
    "additionalNotificationRecipients": [
        {
            "notificationTemplateType": "CompletedAdditionalRecipients",
            "notificationRecipientScope": {
                "@odata.type": "#microsoft.graph.accessReviewNotificationRecipientQueryScope",
                "query": "/v1.0/groups/$($notgrp.value.id)/transitiveMembers/microsoft.graph.user",
                "queryType": "MicrosoftGraph",
                "queryRoot": null
            }
        }
    ]
}
"@

# Uri to post json to
$apiUri = "https://graph.microsoft.com/beta/identityGovernance/accessReviews/definitions"

# Command to send everything and create the access review
Invoke-RestMethod -Headers $Header -Uri $apiUri -Body $body -Method POST -ContentType 'application/json'