####Save a CSV to your Desktop. The CSV should only contain 2 columns.####
####The Headers in your CSV need to only contain the headers (Parent, Child)####
####Populate the CSV with Parent and Child Folder Names####
####Update $csvname with the name of your CSV created prior to running this script####
####Update the DefaultFolderIDNumber number with the Primary Default Parent Folders ID Number#####

####Only Change these Variables####
$apiKey = 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX'
$orgid = "XXXXX"
$csvname = "XXXXXXXXXXXXX.csv"
$DefaultFolderIDNumber = "XXXXX"
#######################################################################################

#Read the CSV and Import
$csvpath = "$env:UserProfile\Desktop\$csvname"
$CSV = Import-CSV -path "$csvpath"

#Select The Unique Parent Names
$PrimaryGroup = ($CSV.Parent | Select -unique)
#For Each Parent Create the Parent
$PrimaryGroup | % {
$Primary = $_
$headers = @{
    "Authorization" = "Bearer $apiKey"
    "Content-Type" = "application/json"
  }
$body = @"
  {
      "name": "$Primary",
      "refresh_interval": 1440,
      "parent_server_group_id": "$DefaultFolderIDNumber",
      "ui_color": "#3C18EF",
      "notes": "$Primary",
      "enable_os_auto_update": false,
      "enable_wsus": false
  }
"@

$url = "https://console.automox.com/api/servergroups?o=$orgid"

Invoke-WebRequest -Method Post -Uri $url -Headers $headers -Body $body

#Wait a sec
Start-sleep 
#Call the new folders ID and store it in $parentid
$headers = @{ "Authorization" = "Bearer $apiKey" }
$url = "https://console.automox.com/api/servergroups?o=$orgid"
$response = (Invoke-WebRequest -Method Get -Uri $url -Headers $headers).Content | ConvertFrom-JSon
$parentid = ($response | ? {$_ -match "$Primary"} | Select -ExpandProperty id)

#Select all Unique SubFolders that belong to the current Parent Folder
$SubFolder = (($CSV | ? {$_.Parent -match "$Primary"} | Select -ExpandProperty Child ) | Select -unique)

#Skip if the count is 0
If ($SubFolder.count -ge 1){

#Create all the child groups of the current Parent
$SubFolder | % {
    $ChildFolder = $_
$headers = @{
    "Authorization" = "Bearer $apiKey"
    "Content-Type" = "application/json"
  }
$body = @"
 {
      "name": "$ChildFolder",
      "refresh_interval": 1440,
      "parent_server_group_id": "$parentid",
      "ui_color": "#3C18EF",
      "notes": "$Primary_Child_$ChildFolder",
      "enable_os_auto_update": false,
      "enable_wsus": false
  }
"@

$url = "https://console.automox.com/api/servergroups?o=$orgid"

Invoke-WebRequest -Method Post -Uri $url -Headers $headers -Body $body
}
}else{
#If the count was "0" above, then write that the Parent had no Children    
    Write-Host "$Primary has no SubFolders"
}
}
Write-Host "You have now created the needed groups and they should be availble within the admin console"
