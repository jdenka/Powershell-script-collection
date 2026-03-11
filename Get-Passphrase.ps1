<#
.SYNOPSIS
This passphrase generator uses a local wordlist to generate a random passphrase.

.DESCRIPTION
Get a random passphrase using a bundled local wordlist (20,000 words).
It combines 4 random words with a random number between 100 and 1000.
No external API calls required - works offline and is more secure.

.PARAMETER Delimiter
This parameter identifies what kind of delimiter to use between the words.
Default is "-".

.PARAMETER Count
This parameter identifies how many passphrases to generate.
Default is 1.

.PARAMETER WordCount
Number of words to include in the passphrase.
Default is 4.

.PARAMETER NoNumber
Skip adding the random number suffix.

.EXAMPLE
Get-Passphrase -Delimiter "_" -Count 10 | Out-File -FilePath "C:\temp\passphrases.txt"
Will generate a file with 10 passphrases separated by an underscore.

.EXAMPLE
Get-Passphrase
Will generate a single passphrase separated by a dash by default.

.EXAMPLE
Get-Passphrase -WordCount 5 -NoNumber
Generates a 5-word passphrase without the number suffix.

.NOTES
Author: Dennis Johansson
Updated: 2026-03-11 - Replaced external API with local wordlist for security
#>
function Get-Passphrase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Delimiter = "-",
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 100)]
        [int]$Count = 1,
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(3, 8)]
        [int]$WordCount = 4,
        
        [Parameter(Mandatory = $false)]
        [switch]$NoNumber
    )
    
    # Determine wordlist path (same directory as script)
    $scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
    $wordlistPath = Join-Path $scriptDir "wordlist.txt"
    
    # Load wordlist
    if (-not (Test-Path $wordlistPath)) {
        Write-Error "Wordlist not found at: $wordlistPath. Please ensure wordlist.txt exists in the same directory as this script."
        return
    }
    
    try {
        $wordlist = Get-Content $wordlistPath -ErrorAction Stop
        if ($wordlist.Count -lt 1000) {
            Write-Warning "Wordlist contains only $($wordlist.Count) words. Recommended minimum is 1000 for security."
        }
    }
    catch {
        Write-Error "Failed to load wordlist: $($_.Exception.Message)"
        return
    }
    
    # Generate passphrases
    for ($i = 1; $i -le $Count; $i++) {
        $words = $wordlist | Get-Random -Count $WordCount
        
        # Capitalize first letter of each word
        $capitalized = foreach ($word in $words) {
            $word.Substring(0, 1).ToUpper() + $word.Substring(1).ToLower()
        }
        
        $passphrase = $capitalized -join $Delimiter
        
        # Add random number suffix unless -NoNumber specified
        if (-not $NoNumber) {
            $suffix = Get-Random -Minimum 100 -Maximum 1000
            $passphrase = "$passphrase$suffix"
        }
        
        Write-Output $passphrase
    }
}

# Only run interactively if script is executed directly (not dot-sourced)
if ($MyInvocation.InvocationName -ne '.') {
    Get-Passphrase
}
