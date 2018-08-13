<#
    .SYNOPSIS
        Exports a csv of the user accounts home directory in a given AD ou.
    .DESCRIPTION
        Exports a csv of the user accounts home directory in a given AD ou.
    .NOTES
        Created by Rob Herrera (rherrera@usbr.gov)
#>

$default_log = 'C:\Test\Users.csv'
$ou = "OU="
$properties = "SamAccountName,extensionAttribute,homeDirectory,homeDrive,DistinguishedName"
$homeDIR = '\\\\server\\Users'

Get-Aduser -Filter * -Properties $properties -Server "domain" | 
Select-Object $properties  | 
Where-Object { $_.extensionAttribute13 -eq 1 -and $_.DistinguishedName -match $ou -and $_.homeDirectory -match $homeDIR } |
Export-Csv $default_log -NoTypeInformation 

