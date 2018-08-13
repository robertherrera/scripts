<#
    .SYNOPSIS
        Creates shortcuts for all mapped/network drives for a user.

    .DESCRIPTION
        Creates non-mapped links using the UNC path of a network shares
        as they are currently mapped for the user. Each shortcut will use
        the currently mapped drive letter as the shortcut name.
#>
Get-PSDrive | Where-Object {

    # Consider anything with \\ as a network share
    $_.DisplayRoot -like '\\*'
} | ForEach-Object {

    # Create the link file. Uses the "old" way in case the target
    # computer doesn't have Powershell 5+ installed.
    $wsShell = New-Object -ComObject WScript.Shell

    # Construct and save the lnk file to the desktop.
    $shortcut = $wsShell.CreateShortcut("$($Home)\Desktop\$($_.Name).lnk")
    $shortcut.TargetPath = $_.DisplayRoot
    $shortcut.Save()
}