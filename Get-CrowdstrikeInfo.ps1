
 
## set paths depending on platform ##

#$winPath = 'C:\Scripts\jamfapi' 
#Set-Location $winPath

$macPath = '/users/cbc/desktop/jamf_work/posh/csv' 
Set-Location $macPath
 
## get JAMF REST API account credentials and create credentials object
$Credentials = Get-Credential
$jssurl = 'https://xxxxx.jamfcloud.com/JSSResource'

function Get-BasicComputerInfo {
  $outfile = 'jamf-basicComputerInfo.csv'
  if(Test-Path -Path "$macPath/$outfile"){Remove-Item -Path "$macPath/$outfile" -Force > $null}

  $computerurl = "$jssurl/computers/subset/basic"
  $allcomputers = Invoke-RestMethod -Method Get -Uri $computerurl -Credential $Credentials 

  $allcomputers.SelectNodes('//computers//computer') |
  ForEach-Object { [pscustomobject] @{ 
      cid      = $_.id
      username = $_.username 
      cname    = $_.name
      cmodel   = $_.model 
      cserial  = $_.serial_number
      crepdate = $_.report_date_utc
      cudid    = $_.udid
      cmanaged = $_.managed 
    }
  } | Export-Csv -Path "$macPath/$outfile" -nti -Append -Force
}  

function Get-ComputerGroups {
  $outfile = 'jamf-computerGroups.csv'
  if(Test-Path -Path "$macPath/$outfile"){Remove-Item -Path "$macPath/$outfile" -Force > $null}

  $cgroupsurl = "$jssurl/computergroups"
  $cgroups = Invoke-RestMethod -Method Get -Uri $cgroupsurl -Credential $Credentials

  $cgroups.SelectNodes('//computer_groups//computer_group') |
  ForEach-Object { [pscustomobject] @{ 
      groupID     = $_.id
      name        = $_.name 
      smart_group = $_.is_smart  
    }
  } | Export-Csv -Path "$macPath\$outfile" -nti -Append
}  

function Get-Admins {
  $outfile = 'jamf-admins.csv'
  if (Test-Path -Path "$macPath/$outfile"){Remove-Item -Path "$macPath/$outfile" -Force > $null}

  $adminsurl = "$jssurl/accounts"
  $admins = Invoke-RestMethod -Method Get -Uri $adminsurl -Credential $Credentials

  $admins.SelectNodes('//accounts//users//user') |

  ForEach-Object { [pscustomobject] @{ 
      acctID = $_.id
      name   = $_.name           
    }
  } | Export-Csv -Path "$macPath\$outfile" -nti -Append
} 

function Get-Categories {
  $outfile = 'jamf-categories.csv'
  if (Test-Path -Path "$macPath/$outfile") { Remove-Item -Path "$macPath/$outfile" -Force > $null }

  $caturl = "$jssurl/categories"
  $cats = Invoke-RestMethod -Method Get -Uri "$caturl" -Credential $Credentials

  $cats.SelectNodes('//categories//category') | 
  ForEach-Object { [pscustomobject] @{
      catId = $_.id
      name  = $_.name
    }
  } | Export-Csv -Path "$macPath\$outfile" -nti -Append

}

function Get-CSAttributes {
  $outfile = 'jamf-cattributes.csv'
  if (Test-Path -Path "$macPath/$outfile") { Remove-Item -Path "$macPath/$outfile" -Force > $null }

  ## advanced computer seach id 9 is assigned to the cs attributes ##
  $easearchurl = "$jssurl/advancedcomputersearches/id/9"
  $easearch    = Invoke-RestMethod -Method Get -Uri $easearchurl -Credential $Credentials 
    
  $easearch.SelectNodes('//advanced_computer_search//computers//computer') | 
    ForEach-Object { [pscustomobject] @{
        cname          = $_.name
        cserial        = $_.Serial_Number
        osversion      = $_.Operating_System_Version
        clastcheckin   = $_.Last_Check_in
        clastinventory = $_.Last_Inventory_Update
        csversion      = $_.CrowdeStrikeAgentVersion
        csstatus       = $_.CrowdStrikeAgentStatus
        cslastconnect  = $_.CrowdstrikeAgentLastConnect
      }
    } | Export-Csv -Path "$macPath\$outfile" -nti -Append
  } 

  function New-Workbook
{
  
  $files = Get-ChildItem -Path ('{0}\*.csv' -f $macPath)
  $outfile = 'jamf_report.xlsx'
  if(Test-Path $macPath/$outfile){Remove-Item -Path $macPath/$outfile -Force}
  
  foreach($file in $files)
  {
    $sheetname = $file.basename
    Import-Csv -Path $file.fullname  | Export-Excel -Path ('{0}' -f $outfile) -AutoSize -AutoFilter -FreezeTopRow -WorksheetName $sheetname
  }
}
  

Get-BasicComputerInfo
Get-ComputerGroups
Get-Admins
Get-Categories
Get-CSAttributes





