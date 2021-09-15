# REQUIRES -Version 2.0

#Handle Exit Codes:
trap {  $host.ui.WriteErrorLine($_.Exception); exit 90 }

$scriptblock = {
    YOUR_CODE_GOES_HERE
}
$runScriptBlock = & "$env:SystemRoot\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy Bypass -WindowStyle Hidden -NoProfile -NonInteractive -Command $scriptblock
