<#
.SYNOPSIS
This passphrase generator uses the RandomLists API to generate a random passphrase.

.DESCRIPTION
Get a random passphrase using https://www.randomlists.com/data/words.json as a source.
It then combines 4 random words from the list with a random number between 100 and 1000.
It is partly written with Github Copilot and GPT-3

.PARAMETER Delimiter
This parameter identifies what kind of delimiter to use between the words.

.PARAMETER Count
This parameter identifies how many passphrases to generate.

.EXAMPLE
1) Get-Passphrase -Delimiter "_" -Count 10 | Out-File -FilePath "C:\temp\passphrases.txt"
Will generate a file with 10 passphrases separated by an underscore.
2) Get-Passphrase 
Will generate a single passphrase separated by a dash by default, if you are using the default values.
The script will ask about delimiter and how many passphrases to generate.

.NOTES
Author: Dennis Johansson
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
            $end = Get-Random -Maximum 1000 -Minimum 100
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
        $end = Get-Random -Maximum 1000 -Minimum 100
        foreach ($word in $words) {
            $word = $word.Substring(0, 1).ToUpper() + $word.Substring(1)
            $capitalized += $word
        }
        $passphrase = $capitalized -join $Delimiter
        Write-Output "$($passphrase + $end)"
    }
}
Get-Passphrase