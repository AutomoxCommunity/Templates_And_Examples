$apiKey = 'your_automox_api_key'
$orgId = 'your_organization_id'

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Content-Type", "application/json")
$headers.Add("Authorization", "Bearer $apiKey")

$body = "{
`n    `"name`": `"TEMPLATE-Servicing-Stack-Policy`",
`n    `"policy_type_name`": `"patch`",
`n    `"organization_id`": $orgId,
`n    `"configuration`": {
`n      `"filter_type`": `"include`",
`n      `"patch_rule`": `"filter`",
`n      `"filters`": [`"*Servicing Stack Update*`"],
`n      `"auto_patch`": true,
`n      `"auto_reboot`": false,
`n      `"missed_patch_window`": true,
`n      `"notify_user`": false,
`n      `"include_optional`": false
`n    },
`n    `"notes`": `"`",
`n    `"schedule_days`": 0,
`n    `"schedule_weeks_of_month`": 0,
`n    `"schedule_months`": 0,
`n    `"schedule_time`": `"02:00`"
`n}"

$response = Invoke-RestMethod -UseBasicParsing "https://console.automox.com/api/policies?o=$orgId" -Method 'POST' -Headers $headers -Body $body
$response | ConvertTo-Json