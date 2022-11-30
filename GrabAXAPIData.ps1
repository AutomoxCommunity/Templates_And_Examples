# Update these variables with your API Key, orgID & save directory/filename 
# This script expects the C:\temp\ path to already exist and will overwrite an existing file

$apiKey = '<YOUR_KEY_HERE>'
$orgID = '<YOUR_ORG_HERE>'
$page = 0
$limit = 500
$headers = @{"Authorization" = "Bearer $apiKey"}
#############################################################################################################


#HealthReport

$expDir = 'C:\Temp\health.csv'
$servers = @()


while($true) {

    $uri = "https://console.automox.com/api/servers?o=$orgID&api_key=$apiKey&l=$limit&p=$page"

    $resp = (Invoke-WebRequest -Method GET -Uri $uri -UseBasicParsing).Content | ConvertFrom-Json | Select-Object results

    $OutputVol = $resp.results `
        | Select-Object Name, agent_version, needs_reboot, last_disconnect_time, last_refresh_time, pending_patches, patches, `
            last_update_time, os_family, os_name, os_version, id, server_group_id, create_time -ExpandProperty detail `
        | Where-Object VOLUME -NE $null

    $resp = (Invoke-WebRequest -Method GET -Uri $uri -UseBasicParsing).Content | ConvertFrom-Json | Select-Object results

    $OutputNoVol = $resp.results `
        | Select-Object Name, agent_version, needs_reboot, last_disconnect_time, last_refresh_time, pending_patches, patches, `
            last_update_time, os_family, os_name, os_version, id, server_group_id, create_time -ExpandProperty detail `
        | Where-Object VOLUME -EQ $null

    $Output =  $OutputVol `
        | Select-Object Name, agent_version, PS_VERSION, AUTO_UPDATE_OPTIONS, WSUS_CONFIG, UPDATE_SOURCE_CHECK, WMI_INTEGRITY_CHECK, needs_reboot, `
            last_disconnect_time, last_refresh_time, pending_patches, patches, last_update_time, os_family, os_name, os_version, id, server_group_id, create_time -ExpandProperty VOLUME `
        | Select-Object Name, agent_version, PS_VERSION, AUTO_UPDATE_OPTIONS, WSUS_CONFIG, UPDATE_SOURCE_CHECK, WMI_INTEGRITY_CHECK, needs_reboot, `
            last_disconnect_time, last_refresh_time, pending_patches, patches, last_update_time, os_family, os_name, os_version, id, server_group_id, create_time, IS_SYSTEM_DISK `
            ,@{
                Name = 'Free (GB)'
                Expression = { ($_.FREE/1000000000).ToString("#####.#") }
            } | Where-Object IS_SYSTEM_DISK -EQ True | Sort-Object Name 

    $servers += $Output
    $servers += $OutputNoVol
    $page += 1

    if($resp.results.Count -lt $limit) {
        break
    }

}        

$servers | Export-Csv -Path $expDir -NoTypeInformation -Force



#####################################
#Get packages
##Reset Variables
$page = 0
$filepath = "C:\Temp\packages.csv"

while($true) {
   
    $urlPackages = "https://console.automox.com/api/orgs/$orgID/packages?o=$orgID&l=$limit&p=$page"
    $response = (Invoke-WebRequest -Method Get -Uri $urlPackages -Headers $headers).Content | ConvertFrom-Json
   
    Write-Output $page
    $data += $response
    $page += 1

    if($response.count -lt $limit) {
        break
    }
}
$data | Group-Object display_name | Sort-Object name | Select-Object Count,name `
      | Export-Csv -Path $filepath -NoTypeInformation


#Get SoftwareInv
$page = 0
$filepath = 'C:\Temp\SoftwareInv.csv'
Set-Content $filepath -Value "Computer,display_name,version"

$apiInstance = 'https://console.automox.com/api/'
$apiTable = 'servers'
$orgAndKey = "?o=$orgID&api_key=$apiKey"

# Put components together
$getURI = $apiInstance + $apiTable + $orgAndKey

# Get the json body of the Web Request
$jsonReturn = (Invoke-WebRequest -UseBasicParsing -Method Get -Uri $getURI).Content

# Convert to object with manipulatable properties/values
$servers = $jsonReturn | ConvertFrom-Json
$servers = $servers | Sort-Object name

# Check each server for software
foreach ($server in $servers) {

    $serverID = $server.id
    $serverName = $server.name
    
    Write-Output $serverName
    
    $orgAndKey = "/$serverID/packages?o=$orgID"

    # Put components together
    $getURI = $apiInstance + $apiTable + $orgAndKey

    $headers = @{ "Authorization" = "Bearer $apiKey" }
    $response = (Invoke-WebRequest -Method Get -Uri $getURI -Headers $headers).Content | ConvertFrom-Json

    $response | Where-Object {$_.installed -EQ $true} | Select-Object @{label="Computer"; Expression= {"$serverName"}},Display_Name,Version `
              | Sort-Object Display_Name | Export-Csv -Path $filepath -NoTypeInformation -Append -Force

}

##Servers.Endpoints
##Reset Variables
$page = 0
$data = @()

while($true) {
    $url = "https://console.automox.com/api/servers?o=$orgID&limit=$limit&page=$page"
    $resp = (Invoke-WebRequest -Method Get -Uri $url -Headers $headers).Content 
    $data += $resp

    if($resp.results.count -lt $limit) {
        break
    }
    $page += 1
}

Write-Host "Creating Servers json..."
$data | Out-File C:\Temp\Servers.json


##ServerGroups
Start-Sleep -Seconds 5
##Reset Variables
$page = 0
$data = @()

while($true) {
    $url = "https://console.automox.com/api/servergroups?o=$orgID&limit=$limit&page=$page"
    $resp = (Invoke-WebRequest -Method Get -Uri $url -Headers $headers).Content 
    $data += $resp

    if($resp.results.count -lt $limit) {
        break
    }
    $page += 1
}

Write-Host "Creating Servergroups json..."

$data | Out-File C:\Temp\ServerGroups.json



##Prepatch Report
Start-Sleep -Seconds 5
##Reset Variables
$page = 0
$data = @()

while($true) {
    $url = "https://console.automox.com/api/reports/prepatch?o=$orgID&limit=$limit&page=$page"
    $resp = (Invoke-WebRequest -Method Get -Uri $url -Headers $headers).Content
    $data += $resp

    if($resp.results.count -lt $limit) {
        break
    }
    $page += 1
}

Write-Host "Creating PrePatch json..."

$data | Out-File C:\Temp\PrePatch.json


##PolicyStats
Start-Sleep -Seconds 5
##Reset Variables
$page = 0
$data = @()

while($true) {
    $url = "https://console.automox.com/api/policystats?o=$orgID&limit=$limit&page=$page"
    $resp = (Invoke-WebRequest -Method Get -Uri $url -Headers $headers).Content
    $data += $resp

    if($resp.results.count -lt $limit) {
        break
    }
    $page += 1
}

Write-Host "Creating PolicyStats json..."

$data | Out-File C:\Temp\PolicyStats.json



##PackagesWaiting
Start-Sleep -Seconds 5
##Reset Variables
$page = 0
$data = @()

while($true) {
    $url = "https://console.automox.com/api/orgs/$orgID/packages?o=$orgID&awaiting=1&limit=$limit&page=$page"
    $resp = (Invoke-WebRequest -Method Get -Uri $url -Headers $headers).Content
    $data += $resp

    if($resp.results.count -lt $limit) {
        break
    }
    $page += 1
}

Write-Host "Creating PackagesWaiting json..."

$data | Out-File C:\Temp\PackagesWaiting.json




##Policies
Start-Sleep -Seconds 5
##Reset Variables
$page = 0
$data = @()

while($true) {
    $url = "https://console.automox.com/api/policies?o=$orgID&limit=$limit&page=$page"
    $resp = (Invoke-WebRequest -Method Get -Uri $url -Headers $headers).Content
    $data += $resp

    if($resp.results.count -lt $limit) {
        break
    }
    $page += 1
}

Write-Host "Creating Policys json..."

$data | Out-File C:\Temp\Policies.json



