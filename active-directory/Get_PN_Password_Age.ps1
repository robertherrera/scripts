<#
    .SYNOPSIS
        Exports a csv of the service accounts in a given AD ou.
    .DESCRIPTION
        Exports a csv of the service accounts in a given AD ou.
    .NOTES
        Created by Rob Herrera (rherrera@usbr.gov)
#>

import-module activedirectory

$todaysDate = Get-date
$expireDate = $todaysDate.AddDays(-60) #add number of days for account to expire or check
$ou = "OU="
$default_log = "C:\Test\Service_Acount_Password_Age.csv"
$attributes = "1" #Service account attributes
$filter = ($attributes | ForEach-Object { "extensionattribute -eq '$_'" }) -join ' -or '
$properties = "SamAccountName,extensionAttribute,PasswordLastSet,DistinguishedName"

Get-AdUser -Filter $filter -Properties $properties -Server "domain" | 
Select-Object $properties  | #orders the columns for style purposes
Where-Object { $_.DistinguishedName -match $ou -and $_.PasswordLastSet -lt $expireDate } |
Export-Csv $default_log -NoTypeInformation 
