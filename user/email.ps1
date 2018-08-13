<#
    .SYNOPSIS
        Function that can be called for email
    .DESCRIPTION
        
    .NOTES
        Created by Rob Herrera (rherrera@usbr.gov)
#>

# Function to create report email
function SendNotification {
    $Msg = New-Object Net.Mail.MailMessage
    $Smtp = New-Object Net.Mail.SmtpClient($ExchangeServer)
    $Msg.From = $FromAddress
    $Msg.To.Add($ToAddress)
    $Msg.Subject = "Important information about your U: Drive."
    $Msg.Body = $EmailBody
    $Msg.IsBodyHTML = $false
    $Smtp.Send($Msg)
   }
    
   # Define local Exchange server info for message relay. Ensure that any servers running this script have permission to relay.
   $ExchangeServer = "smtpi.server"
   $FromAddress = "me"
    
   # Import user list and information from .CSV file
   $Users = Import-Csv UserList.csv
    
   # Send notification to each user in the list
   Foreach ($User in $Users) {
    $ToAddress = $User.Email + "@gmail.com"
    $Name = $User.FolderSize

    $EmailBody =  Here is your $User.FolderSize


    Write-Host "Sending notification to $Name ($ToAddress)" -ForegroundColor Yellow
    SendNotification
    }