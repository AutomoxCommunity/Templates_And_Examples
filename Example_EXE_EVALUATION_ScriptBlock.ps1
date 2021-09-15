 #REQUIRES -Version 2.0

#Handle Exit Codes:
trap {  $host.ui.WriteErrorLine($_.Exception); exit 90 }

#### Check Registry with ScriptBlock

$scriptBlock = {
    # Define registry key path, registry value, and the desired value data
    #############################################
    $regPath = "HKLM:SOFTWARE\Dell\Dell Data Protection"
    $regProperty = "EEVersion"
    $desiredValue = '10.5.0.1'
    #############################################
 
    # Retrieve current value for comparison
    $currentValue = (Get-ItemProperty -Path $regPath -Name $regProperty).$regProperty
    return $currentValue
}

# Execute the ScriptBlock in a 64-bit shell, 
# No need to assign to a variable if you don't 
# have a return value. In most cases, you will.
$currentValue = & "$env:SystemRoot\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy Bypass -WindowStyle Hidden -NoProfile -NonInteractive -Command $scriptBlock

# Compare current with desired and exit accordingly.
# 0 for Compliant, 1 for Non-Compliant
if ($currentValue -eq $desiredValue) {
   Exit 0
} else { Exit 1 }
