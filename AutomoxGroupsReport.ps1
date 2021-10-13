#Automox Groups Report
#Run with Powershell
#The CSV report will be created in the Users Documents folder
#API Request Variables
######################################################
#####Update the $apiKey with your API KEY created from the Automox Portal####
$apiKey = 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX'
$clientID = "XXXX"
#####Only update the two Variables in this block######
######################################################


#Api Request
$headers = @{ "Authorization" = "Bearer $apiKey" }
$uri = "https://console.automox.com/api/servergroups?o=$clientID"
$responses = (Invoke-WebRequest -Method Get -Uri $uri -Headers $headers).Content | ConvertFrom-Json


#Variables
$Output = @()
$UserPath = "$env:UserProfile"
$date = Get-Date -UFormat %m.%d.%Y
$OutputPath = "$UserPath\Documents\AutomoxGroupsReport.$date.csv"


#Array Container
$Output = @()

#Translate all arrays to strings
$responses | % {
$lineitem = $_
$id = $lineitem | Select -ExpandProperty 'id'
$organization_id = $lineitem | Select -ExpandProperty 'organization_id'
$name = $lineitem | Select -ExpandProperty 'name'
$refresh_interval = $lineitem | Select -ExpandProperty 'refresh_interval'
$parent_server_group_id = $lineitem | Select -ExpandProperty 'parent_server_group_id'
$ui_color = $lineitem | Select -ExpandProperty 'ui_color'
$notes = $lineitem | Select -ExpandProperty 'notes'
$enable_os_auto_update = $lineitem | Select -ExpandProperty 'enable_os_auto_update'
$server_count = $lineitem | Select -ExpandProperty 'server_count'
$wsus_config = $lineitem | Select -ExpandProperty 'wsus_config'


#Convert all strings to hashtable
$AllAddress = New-Object PSObject -Property @{
id = "$id"
organization_id = "$organization_id"
name = "$name"
refresh_interval = "$refresh_interval"
parent_server_group_id = "$parent_server_group_id"
ui_color = "$ui_color"
notes = "$notes"
enable_os_auto_update = "$enable_os_auto_update"
server_count = "$server_count"
wsus_config = "$wsus_config"
}

#Combine all the outputs
$output += $AllAddress
}

#Export the CSV
$output | Export-CSV $OutputPath -nti