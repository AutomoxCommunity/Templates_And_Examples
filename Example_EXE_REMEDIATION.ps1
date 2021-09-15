# REQUIRES -Version 2.0
<#
.SYNOPSIS
    This script allows an admin to install Dell Data Protection via Automox
.DESCRIPTION
    This script installs Dell Data Protection
    This script may not work on all systems. Modify to fit your needs
.NOTES
    File Name	:DellDP_Install.ps1
    Author	:Automox
    Prerequisite	:Minimum PowerShell V2,  Window 7
.LINK
    http://www.automox.com
#>

#Handle Exit Codes:
trap {  $host.ui.WriteErrorLine($_.Exception); exit 90 }

function DellDP_Install_Rem {
    <#
    .SYNOPSIS
        This function allows automox to Install the Dell DP on Windows .
    .DESCRIPTION
    .EXAMPLE
        DellDP_Install_Rem
    #REQUIRES -Version 2.0
    #>
    #############Change the settings in this block#######################
    $fileName = 'YOUR_INSTALLER_NAME.exe'
    $arg = "/S /v`"/norestart /qn`""
   ###############################################################    
#Handle Exit Codes:
trap {  $host.ui.WriteErrorLine($_.Exception); exit 90 }

#Install
    Try {$process = Start-Process -FilePath "$fileName" -ArgumentList "$arg" -PassThru -ErrorAction Stop
         Write-Output "Dell Data Protection Install Finished...`n"
    }
    Catch { $Exception = $error[0].Exception.Message + "`nAt Line " + $error[0].InvocationInfo.ScriptLineNumber
            Write-Output $Exception
            exit 90
    }
}
DellDP_Install_Rem
