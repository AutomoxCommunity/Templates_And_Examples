<#
.SYNOPSIS
  Check for presence of specified application on the target device

.DESCRIPTION
  Read 32-bit and 64-bit registry to find matching applications

  Exits with 0 for compliance, 1 for Non-Compliance. 
  Non-Compliant devices will run Remediation Code at the Policy's next scheduled date.

.NOTES
  A scriptblock is used to workaround the limitations of 32-bit powershell.exe.
  This allows us to redirect the operations to a 64-bit powershell.exe and read
  the 64-bit registry without .NET workarounds.

.LINK
http://www.automox.com

#REQUIRES -Version 2.0
#>

# The ScriptBlock method used here is to allow a 32-bit agent process to access the 64-bit registry on 64-bit Windows. This is necessary if the application isn't known to be 32-bit only.

#Handle Exit Codes:
trap {  $host.ui.WriteErrorLine($_.Exception); exit 90 }

$scriptblock = {
    #Define Registry Location for the 64-bit and 32-bit Uninstall keys
    $uninstReg = @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall')

    # Define the App Name to look for
    # Look at a machine with the application installed unless you're sure the formatting of the name/version
    # Specifically the DisplayName. This is what you see in Add/Remove Programs. This doesn't have to be exact.
    # Default behavior uses -match which is essentially "DisplayName contains VLC"
    ##################
    $appName = '7-Zip 19.00 (x64 edition)'
    ##################

    # Get all entries that match our criteria. DisplayName matches $appname
    $installed = @(Get-ChildItem $uninstReg -ErrorAction SilentlyContinue | Get-ItemProperty | Where-Object { ($_.DisplayName -match $appName) })

    # If any matches were present, $installed will be populated. If none, then $installed is NULL and this IF statement will be false.
    # The return value here is what the ScriptBlock will send back to us after we run it.
    # 1 for Non-Compliant, 0 for Compliant
    if ($installed) {
        return 0
    } else { return -1 }
}
$exitCode = & "$env:SystemRoot\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy Bypass -WindowStyle Hidden -NoProfile -NonInteractive -Command $scriptblock
Exit $exitCode
