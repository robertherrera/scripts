<#
    .Description
        Delete all Files in certain folders older than 30 minutes
    
    .NOTES
        Created by Rob Herrera (rherrera@usbr.gov)
#>

$Paths = @("\\server\folder")
$DatetoDelete = (Get-Date).AddMinutes(-30)

try {
    foreach ($Path in $Paths) {
        Get-ChildItem $Path -File -Recurse | Where-Object { $_.LastWriteTime -lt $DatetoDelete } | Remove-Item -Force -Recurse 
    }
    $String = -Join( $DatetoDelete, " Completed Script")
    Add-Content C:\log.txt $String
} catch {
    "Error on file deletion in $Path"
}
