<#
    This passphrase generator uses the RandomLists API to generate a random passphrase.
    It is completly written with Github Copilot and Chat GPT-3.
#>
function Get-Passphrase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Delimiter
    )
    if (-not $Delimiter) {
        $Delimiter = "-"
    }
    try {
        $uri = "https://www.randomlists.com/data/words.json"
        $json = Invoke-RestMethod -Uri $uri
        $words = $json.data | Get-Random -Count 4
        $passphrase = $words -join $Delimiter
        Write-Output "Passphrase: $passphrase"
    }
    catch {
        Write-Error "Error: $($Error[0].Exception.Message)"
    }
}
