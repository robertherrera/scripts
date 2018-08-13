<#
    .SYNOPSIS
        Started a module for setting Home dir
    .DESCRIPTION
        
    .NOTES
        Created by Rob Herrera (rherrera@usbr.gov)
#>

$UserList = Import-Csv -Path C:\test\Users.csv

foreach ($User in $UserList) {
    Get-ADUser -Filter "SamAccountName -eq '$User.SamAccountName'"  | 
    Set-ADUser -HomeDirectory $null -HomeDrive $null

}