<#
    .SYNOPSIS
        Creates a complex, psuedo-random password.

    .DESCRIPTION
        Creates a complex, psuedo-random password and copies
        it to the clipboard.
#>
Param(
    # The length of the password (default = 14).
    [Parameter(Position=1)]
    [int]
    $Length = 14
)

# Character definitions
$Chars = "absdefghijklmnopqrstuvwxyzABCDEFGHI`
 JKLMNOPQRSTUVWXYZ1234567890!@#$%^&*()_"

# Initilize password string for building
$Password = ""

# Create password
for($i = 0; $i -lt $Length; $i++)
{
    $Password += $Chars.ToCharArray() | Get-Random
}

# Copy to the clipboard and display confirmation message
$Password | clip
Write-Host -BackgroundColor DarkGreen -ForegroundColor White `
 "Your $Length character, complex password has been copied to the clipboard"