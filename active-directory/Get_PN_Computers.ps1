<#
    .SYNOPSIS
        Exports a csv of the computers in a given AD ou.
    .DESCRIPTION
        Exports a csv of the computers in a given AD ou.
    .NOTES
        Created by Rob Herrera (rherrera@usbr.gov)
#>

import-module activedirectory

$default_log = "C:\Test\Computers.csv"
$filter = "*"
$ou = "OU=" 
$properties = "Name, OperatingSystem, Modified, IPv4Address, LastLogonDate, DistinguishedName"

Get-Adcomputer -Filter $filter -Properties $properties -Server "domain" | 
Select-Object $properties | 
Where-Object { $_.DistinguishedName -match $ou } |
Export-Csv $default_log -NoTypeInformation 

