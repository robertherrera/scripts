<#
    .SYNOPSIS
        Changes mapped printers to a new server location.
    
    .DESCRIPTION
        Changes mapped printers to a new server location. Assumes
        all printer share names remain the same.
    
    .PARAMETER CurrentServer
        The name of the current print server (required).
    
    .PARAMETER TargetServer
        The name of the target server containing the printers to map (required).

    .EXAMPLE
        .\MigratePrinters.ps1 PRINTSRV01 PRINTSRV02
#>
Param(
    # Current Server
    [Parameter(Position = 1, Mandatory = $true)]
    [string]
    $CurrentServer,

    # Destination Server
    [Parameter(Position = 2, Mandatory = $true)]
    [string]
    $TargetServer
)

# Only get printers that are mapped to the current server name
Get-Printer | Where-Object { 
    $_.ComputerName -like "*$CurrentServer*" 

} | ForEach-Object {

    # Map with new server/share name
    # Command errors on \ chars but still does what it needs
    # so silently continue
    Add-Printer -ConnectionName "\\$($TargetServer)\$($_.ShareName)".ToString()`
     -ErrorAction SilentlyContinue

    # Remove current mapping
    Remove-Printer $_.Name
}