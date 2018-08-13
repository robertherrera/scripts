<#
    .SYNOPSIS
        Robo copy script for remote servers
    .DESCRIPTION
        
    .NOTES
        Created by Rob Herrera (rherrera@usbr.gov)
#>

$User = Read-Host -Prompt 'Input the User Name'

$source      = "C:\Users\$User\Desktop"
$date        = Get-Date -UFormat "%Y%m%d"
$dest        = "\\Server\UserSettings\$User"
$Logfile     = "\\Server\00-LOG\$User-$date.txt"

$what        = @("/MIR")
$options     = @("/LOG:$logfile")
$cmdArgs     = @("$source","$dest",$what,$options) 


## Get Start Time
$startDTM = (Get-Date)

## Create User Folder on the Target Server if it does not exist
$Target = "$dest\$User"

# Create Folder ! does not exist on the Destination PC 
Write-host "Creating Folder....." -fore Green -back black
if(!(Test-Path -Path $Target )){
    New-Item -ItemType directory -Path $Target
}
Write-Host "........................................." -Fore Blue

## Provide Information
Write-host "Copying User Profile into $Target....................." -fore Green -back black
Write-Host "........................................." -Fore Blue

## Kick off the copy with options defined 
robocopy @cmdArgs

## Get End Time
$endDTM = (Get-Date)

## Echo Time elapsed
$Time = "Elapsed Time: $(($endDTM-$startDTM).totalminutes) minutes"

## Provide time it took
Write-host ""
Write-host " Copy User Profile to $Target has been completed......" -fore Green -back black
Write-host " Copy User Profile to $Target took $Time        ......" -fore Blue
