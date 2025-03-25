# Update these variables with your API Key, orgID & save directory/filename
# This script expects the C:\temp\ path to already exist and will overwrite an existing file

$apiKey = '<YOUR_KEY_HERE>'
$orgID = '<YOUR_ORG_HERE>'
$page = 0
$limit = 500
$expDir = 'C:\Temp\'
################################################

################################################
# Do not edit below this line
################################################
$headers = @{"Authorization" = "Bearer $apiKey"}
$baseUrl = "https://console.automox.com/api"
$healthFile = Join-Path "$expDir" "health.csv"
$packagesFile = Join-Path "$expDir" "packages.csv"
$softwareInvFile = Join-Path "$expDir" "SoftwareInv.csv"
$serverFile = Join-Path "$expDir" "servers.json"
$serverGroupsFile = Join-Path "$expDir" "ServerGroups.json"
$prePatchFile = Join-Path "$expDir" "PrePatch.json"
$policyStatsFile = Join-Path "$expDir" "PolicyStats.json"
$packagesWaitingFile = Join-Path "$expDir" "PackagesWaiting.json"
$policiesFile = Join-Path "$expDir" "Policies.json"
################################################

function Request {
    param(
        [Parameter( Mandatory = $true)] [ String ] $Method,
        [Parameter( Mandatory = $true)] [ String ] $Uri,
        [Parameter( Mandatory = $true)] [ PSCustomObject ] $Params
    )

    $resp = (Invoke-WebRequest -Method $Method -Uri $Uri -Headers $headers -Body $Params -UseBasicParsing)
    
    return $resp
}

function Paginate {
    param(
        [Parameter( Mandatory = $true)] [ String ] $Method,
        [Parameter( Mandatory = $true)] [ String ] $Path,
        [Parameter( Mandatory = $true)] [ PSCustomObject ] $Params
    )

    $output = @()

    $Uri = $baseUrl + $Path

    while($true) {
        $resp = Request $Method $Uri $Params
        if ( $resp.StatusCode -eq 200) {
            $output += $resp
        } else {
            Write-Error "Web request failed, exiting"
            Exit 1
        }

        if ((ConvertFrom-Json -InputObject $resp.Content).psobject.Properties.name -match "results") {
            if ((ConvertFrom-Json -InputObject $resp.Content).results.length -lt $limit) {
                break
            }
        } else {
            if ((ConvertFrom-Json -InputObject $resp.Content).length -lt $limit) {
                break
            }
        }

        if ($Params.psobject.Properties.name -match "p") {
            $Params.p += 1
        } elseif ($Params.psobject.Properties.name -match "offset") {
            $Params.offset += $Params.l
        } else {
            break
        }

    }
    return $output
}

################################################
# Generate the Health Report
################################################
$servers = @()
$serversHealth = @()

$Params = @{
    o = $orgId
    l = $limit
    p = $page
}

$output = Paginate "GET" "/servers" $Params
foreach ($resp in $output) {
    $results = $resp.Content | ConvertFrom-Json | Select-Object results
    $OutputVol = $results.results `
        | Select-Object Name, agent_version, needs_reboot, last_disconnect_time, last_refresh_time, pending_patches, patches, `
            last_update_time, os_family, os_name, os_version, id, server_group_id, create_time -ExpandProperty detail `
        | Where-Object VOLUME -NE $null

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

    $servers += $results
    $serversHealth += $Output
    $serversHealth += $OutputNoVol
}

$serversHealth | Export-Csv -Path $healthFile -NoTypeInformation -Force
write-host "Generated Health Report CSV"

################################################
# Generate Packages Output
################################################
$packages = @()

$Params = @{
    o = $orgId
    l = $limit
    p = $page
}

$output = Paginate "GET" "/orgs/$orgId/packages" $Params
foreach ($results in $output) {
    $packages += $results.Content | ConvertFrom-Json
}
$packages | Group-Object display_name | Sort-Object name | Select-Object Count,name | Export-Csv -Path $packagesFile -NoTypeInformation

################################################
# Generate Software Inventory Output
################################################
$softwareInv = foreach ($package in ($packages | Where-Object {$_.installed -EQ $true})) {
    $device = $servers | Where-Object { $_.id -eq $package.server_id }
    $record = [PSCustomObject]@{
        computer = $device.name
        display_name = $package.display_name
        version = $package.version
    }
    $record
}
$softwareInv | Sort-Object Display_Name | Export-Csv -Path $softwareInvFile -NoTypeInformation -Append -Force

################################################
# Generate Servers Output
################################################
Write-Host "Creating Servers json..."
$servers.results | ConvertTo-Json -Depth 10 -Compress | Out-File $serverFile

################################################
# Generate Server Groups JSON Output
################################################
$serverGroups = @()

$Params = @{
    o = $orgId
    l = $limit
    p = $page
}

$output = Paginate "GET" "/servergroups" $Params
foreach ($results in $output) {
    $serverGroups += $results.Content
}

Write-Host "Creating Servergroups json..."

$serverGroups | Out-File $serverGroupsFile

################################################
# Generate Prepatch Report Output
################################################
$prePatchData = @()

if ( $limit -gt 250 ) {
    $adjustedLimit = 250
} else {
    $adjustedLimit = $limit
}

$Params = @{
    o = $orgId
    l = $adjustedLimit
    offset = 0
}

$output = Paginate "GET" "/reports/prepatch" $Params
foreach ($results in $output) {
    $prePatchData += $results.Content
}

Write-Host "Creating PrePatch json..."

$prePatchData | Out-File $prePatchFile

################################################
# Generate Policy Stats JSON Output
################################################
$policyStats = @()

$Params = @{
    o = $orgId
    l = $limit
    p = $page
}

$output = Paginate "GET" "/policystats" $Params
foreach ($results in $output) {
    $policyStats += $results.Content
}

Write-Host "Creating Policy Stats json..."

$policyStats | Out-File $policyStatsFile

################################################
# Generate Packages Awaiting Output
################################################
Write-Host "Creating PackagesWaiting json..."
$packages | ConvertTo-Json -Depth 10 -Compress | Out-File $packagesWaitingFile

################################################
# Generate Policies JSON Output
################################################
$policies = @()

$Params = @{
    o = $orgId
    l = $limit
    p = $page
}

$output = Paginate "GET" "/policies" $Params
foreach ($results in $output) {
    $policies += $results.Content
}

Write-Host "Creating Policies json..."

$policies | Out-File $policiesFile
