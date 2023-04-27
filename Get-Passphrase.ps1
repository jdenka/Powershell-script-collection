<#
    This passphrase generator uses the RandomLists API to generate a random passphrase.
    It is completly written with Github Copilot and Chat GPT-3.
#>
function Get-Passphrase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Delimiter,
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Count
    )
    $DefaultDelimiter = "-"
    if (-not $Delimiter) {
        if (($result = Read-Host "Select a delimiter (default: $DefaultDelimiter)") -eq '') {
            $Delimiter = $DefaultDelimiter
        }
        else {
            $Delimiter = $result
        }
    }
    else {
        ## Do nothing
    }
    $DefaultCount = 1
    if (-not $Count) {
        if (($cresult = Read-Host "Select a count (default: $DefaultCount)") -eq '') {
            $Count = $DefaultCount
        }
        else {
            $Count = $cresult
        }
    }
    else {
        ## Do nothing
    }
    try {
        $uri = "https://www.randomlists.com/data/words.json"
        $json = Invoke-RestMethod -Uri $uri
    }
    catch {
        Write-Error "Error: $($Error[0].Exception.Message)"
    }
    if ($Count -gt 1) {
        foreach ($i in 1..$Count) {
            $words = $json.data | Get-Random -Count 4
            $end = Get-Random -Maximum 100
            $capitalized = @()
            foreach ($word in $words) {
                $word = $word.Substring(0, 1).ToUpper() + $word.Substring(1)
                $capitalized += $word
            }
            $passphrase = $capitalized -join $Delimiter
            Write-Output "$($passphrase + $end)"
        }
    }
    else {
        $words = $json.data | Get-Random -Count 4
        $capitalized = @()
        $end = Get-Random -Maximum 100
        foreach ($word in $words) {
            $word = $word.Substring(0, 1).ToUpper() + $word.Substring(1)
            $capitalized += $word
        }
        $passphrase = $capitalized -join $Delimiter
        Write-Output "$($passphrase + $end)"
    }
}
Get-Passphrase