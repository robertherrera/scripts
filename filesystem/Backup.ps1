<#
    .SYNOPSIS
        Script to keep a local backup of server logs
    .NOTES
        Created by Rob Herrera (rherrera@usbr.gov)
#>

Get-ChildItem *.logs -Path '\\server\folder\' | Copy-Item -Destination 'C:\'

