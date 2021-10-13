#Automox Policies Report
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
$uri = "https://console.automox.com/api/policies?o=$clientID"
$responses = (Invoke-WebRequest -Method Get -Uri $uri -Headers $headers).Content | ConvertFrom-Json


#ReportVariables
$Output = @()
$UserPath = "$env:UserProfile"
$date = Get-Date -UFormat %m.%d.%Y
$OutputPath = "$UserPath\Documents\AutomoxPoliciesReport.$date.csv"



#Create Report
$responses | % {
$SingleItem = $_
$id = $SingleItem | Select -ExpandProperty 'id'
$name = $SingleItem | Select -ExpandProperty 'name'
$policy_type_name = $SingleItem | Select -ExpandProperty 'policy_type_name'
$organization_id = $SingleItem | Select -ExpandProperty 'organization_id'
$configuration = $SingleItem | Select -ExpandProperty 'configuration'
$schedule_days = $SingleItem | Select -ExpandProperty 'schedule_days'
$schedule_weeks_of_month = $SingleItem | Select -ExpandProperty 'schedule_weeks_of_month'
$schedule_months = $SingleItem | Select -ExpandProperty 'schedule_months'
$schedule_time = $SingleItem | Select -ExpandProperty 'schedule_time'
$next_remediation = $SingleItem | Select -ExpandProperty 'next_remediation'
$notes = $SingleItem | Select -ExpandProperty 'notes'
$create_time = $SingleItem | Select -ExpandProperty 'create_time'
$server_groups = $SingleItem | Select -ExpandProperty 'server_groups'
$server_count = $SingleItem | Select -ExpandProperty 'server_count'


$AllAddress = New-Object PSObject -Property @{
id = "$id"
name = "$name"
policy_type_name = "$policy_type_name"
organization_id = "$organization_id"
configuration = "$configuration"
schedule_days = "$schedule_days"
schedule_weeks_of_month = "$schedule_weeks_of_month"
schedule_months = "$schedule_months"
schedule_time = "$schedule_time"
next_remediation = "$next_remediation"
notes = "$notes"
create_time = "$create_time"
server_groups = "$server_groups"
server_count = "$server_count"

}

$output += $AllAddress
}
#Export Report
$output | Export-CSV $OutputPath -nti