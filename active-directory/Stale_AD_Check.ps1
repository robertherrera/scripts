<#
    .SYNOPSIS
        Finds all user folders in a share where the employee doesn't have an AD account.
    .DESCRIPTION
        Finds all user folders in a share where the employee doesn't have an AD account.
        Also helpful for finding user folder names that don't correctly reflect the employee's
        account name.
    .NOTES
        Created by Rob Herrera (rherrera@usbr.gov)
#>
Param(
    # The share UNC path
    [Parameter(Mandatory=$true)]
    [string]
    $Path
)

$userFolders = (Get-ChildItem $Path)
$staleFolders = @()

Import-Module ActiveDirectory

$userFolders | ForEach-Object {

    $user = Get-ADUser -Filter { sAMAccountName -eq $_.Name }

    if($user -eq $null) {
        $staleFolders += $_.Name
    }
}

if($staleFolders.Length -gt 0){
    $staleFolders | Format-List
}
else {
    Write-Host "No stale folders found."
}