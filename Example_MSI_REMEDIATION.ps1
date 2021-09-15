# REQUIRES -Version 2.0
<#
.SYNOPSIS
    This script allows an admin to install 7-Zip 19.00 x64 via Automox
.DESCRIPTION
    This script installs 7-zip
    This script may not work on all systems. Modify to fit your needs
.NOTES
    File Name	:7zip1900x64_Install.ps1
    Author	:Automox
    Prerequisite	:Minimum PowerShell V2,  Window 7
.LINK
    http://www.automox.com
#>

#Handle Exit Codes:
trap {  $host.ui.WriteErrorLine($_.Exception); exit 90 }

try {
    Start-Process -FilePath 'msiexec.exe' -ArgumentList ('/i', '7z1900-x64.msi', '/qn') -Wait -Passthru
    Exit 0
} catch { $Exception = $error[0].Exception.Message + "`nAt Line " + $error[0].InvocationInfo.ScriptLineNumber
    Write-Error $Exception
    Exit -1
}
