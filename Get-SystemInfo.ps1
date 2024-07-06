
<#
    .SYNOPSIS
    JAMF API data extraction and reporting Samples
 
    .DESCRIPTION
    Collection of sample powershell functions using the JAMF 'Classic' API
    Uses classic calls to create a unique csv output file for each function
    After data extraction a combined xlsx report file is created   
 
    .EXAMPLE
    Multiple options can be used to run script
    - dot source
    - IDE of choice (tested with Powershell ISE and Visual Studio Code)

    .NOTES
    Script tested on Windows 10 20H2
    Requires external module ImportExcel
 
    .LINK
    JAMF Classic API Reference
    https://www.jamf.com/developers/apis/classic/reference/

    ImportExcel Powershell Module
    https://www.powershellgallery.com/packages/ImportExcel/7.1.0
    https://github.com/dfinke/ImportExcel
 
    .INPUTS
    Requires Jamf admin credentials
 
    .OUTPUTS
    Windows -- Output files stored in C:\Scripts\jamfapi\ 
     
#>

## verify OS and check directory structure ##

function script:Get-Prereqs
{
  $script:winPath = "$env:HOMEDRIVE\Scripts\jamfapi"
  $script:platform = [System.Environment]::OSVersion.Platform
   
  If($platform -eq 'Win32NT')
  {
    Write-Host -Object 'script is running on Windows' -ForegroundColor Green
    Write-Host -Object 'Checking directory structure' -ForegroundColor Green
    
    if (!(Test-Path -Path ('{0}' -f $winPath))) 
    {  
      Write-Host -Object ('{0} directory does NOT exist, creating now' -f $winPath) -ForegroundColor Red
      New-Item -ItemType 'directory' -Path ('{0}' -f $winPath) -Force
    } else 
    {
      Write-Host -Object ('verified directory {0} exists' -f $winPath) -ForegroundColor Green
    }    
  } 
 
  
  ## install required modules ##
  Write-Host -Object 'checking required package providers and modules' -ForegroundColor Green

  # Nuget #
  $script:pkgprovider = 'Nuget'
  If(Get-PackageProvider -Name $pkgprovider)
  {
    Write-Host -Object ('{0} installed' -f $pkgprovider) -ForegroundColor Green
  }
  else
  {
    Write-Host -Object ('{0} not found, installing now' -f $pkgprovider) -ForegroundColor DarkYellow
    Install-PackageProvider -Name $pkgprovider -Force
  }
 
  # PSGallery #
  $script:repo = 'PSGallery'
  If(Get-PSRepository -Name $repo)
  {
    Write-Host -Object ('{0} installed' -f $repo) -ForegroundColor Green
  }
  else
  {
    Write-Host -Object ('{0} repo not found, registering now' -f $repo) -ForegroundColor DarkYellow
    Register-PSRepository -Name $repo
  } 
  Write-Host -Object ('Setting {0} installation policy to trusted' -f $repo) -ForegroundColor Green
  Set-PSRepository -Name $repo -InstallationPolicy Trusted 
  
  # ImportExcel #
  $script:mod = 'ImportExcel'
  If(Get-InstalledModule -Name $mod)
  {
    Write-Host -Object ('{0} module installed' -f $mod) -ForegroundColor Green
  }
  else
  {
    Write-Host -Object ('{0} module not found, downloading and installing now' -f $mod) -ForegroundColor Red
    Install-Module -Name $mod  -Confirm:$False -Force -Repository $repo   
  }


  ## create JAMF authentication credentials ##
  $script:Credentials = Get-Credential

  ## set the api url, in this case Jamf Classic ##
  $script:jssurl = 'https://xxxxx.jamfcloud.com/JSSResource'
}  

## api call for basic computer info ##
function Get-BasicComputerInfo 
{
  Write-Host -Object 'getting basic computer info' -ForegroundColor Green
  
  # remove old csv file #
  $outfile = 'jamf-basicComputerInfo.csv'
  if(Test-Path -Path ('{0}/{1}' -f $winPath, $outfile))
  {
    Remove-Item -Path ('{0}/{1}' -f $winPath, $outfile) -Force > $null
  }

  # call the api #
  $computerurl = ('{0}/computers/subset/basic' -f $jssurl)
  $allcomputers = Invoke-RestMethod -Method Get -Uri $computerurl -Credential $Credentials
   
  # create custom object and export csv file #
  $allcomputers.SelectNodes('//computers//computer') |
  ForEach-Object -Process {
    [pscustomobject] @{
      cid      = $_.id
      username = $_.username
      cname    = $_.name
      cmodel   = $_.model
      cserial  = $_.serial_number
      crepdate = $_.report_date_utc
      cudid    = $_.udid
      cmanaged = $_.managed
    }
  } |
  Export-Csv -Path ('{0}/{1}' -f $winPath, $outfile) -NoTypeInformation -Append -Force
} 

function Get-ComputerGroups 
{
  Write-Host -Object 'getting jamf computer groups info' -ForegroundColor Green
  
  $outfile = 'jamf-computerGroups.csv'
  if(Test-Path -Path ('{0}/{1}' -f $winPath, $outfile))
  {
    Remove-Item -Path ('{0}/{1}' -f $winPath, $outfile) -Force > $null
  }

  $cgroupsurl = ('{0}/computergroups' -f $jssurl)
  $cgroups = Invoke-RestMethod -Method Get -Uri $cgroupsurl -Credential $Credentials

  $cgroups.SelectNodes('//computer_groups//computer_group') |
  ForEach-Object -Process {
    [pscustomobject] @{ 
      groupID     = $_.id
      name        = $_.name 
      smart_group = $_.is_smart  
    }
  } |
  Export-Csv -Path ('{0}\{1}' -f $winPath, $outfile) -NoTypeInformation -Append
}  

function Get-Admins 
{
  Write-Host -Object 'getting jamf admins' -ForegroundColor Green
  
  $outfile = 'jamf-admins.csv'
  if (Test-Path -Path ('{0}/{1}' -f $winPath, $outfile))
  {
    Remove-Item -Path ('{0}/{1}' -f $winPath, $outfile) -Force > $null
  }

  $adminsurl = ('{0}/accounts' -f $jssurl)
  $admins = Invoke-RestMethod -Method Get -Uri $adminsurl -Credential $Credentials

  $admins.SelectNodes('//accounts//users//user') |

  ForEach-Object -Process {
    [pscustomobject] @{ 
      acctID = $_.id
      name   = $_.name           
    }
  } |
  Export-Csv -Path ('{0}\{1}' -f $winPath, $outfile) -NoTypeInformation -Append
} 


function Get-Categories 
{
  Write-Host -Object 'getting jamf category list' -ForegroundColor Green
  $outfile = 'jamf-categories.csv'
  if (Test-Path -Path ('{0}/{1}' -f $winPath, $outfile)) 
  {
    Remove-Item -Path ('{0}/{1}' -f $winPath, $outfile) -Force > $null
  }

  $caturl = ('{0}/categories' -f $jssurl)
  $cats = Invoke-RestMethod -Method Get -Uri ('{0}' -f $caturl) -Credential $Credentials

  $cats.SelectNodes('//categories//category') | 
  ForEach-Object -Process {
    [pscustomobject] @{
      catId = $_.id
      name  = $_.name
    }
  } |
  Export-Csv -Path ('{0}\{1}' -f $winPath, $outfile) -NoTypeInformation -Append
}

function Get-CSAttributes 
{
  Write-Host -Object 'getting crowdstrike extended attributes' -ForegroundColor Green
  $outfile = 'jamf-cattributes.csv'
  if (Test-Path -Path ('{0}/{1}' -f $winPath, $outfile)) 
  {
    Remove-Item -Path ('{0}/{1}' -f $winPath, $outfile) -Force > $null
  }

  ## advanced computer seach id 9 is assigned to the cs attributes ##
  $easearchurl = ('{0}/advancedcomputersearches/id/9' -f $jssurl)
  $easearch    = Invoke-RestMethod -Method Get -Uri $easearchurl -Credential $Credentials 
    
  $easearch.SelectNodes('//advanced_computer_search//computers//computer') | 
  ForEach-Object -Process {
    [pscustomobject] @{
      cname          = $_.name
      cserial        = $_.Serial_Number
      osversion      = $_.Operating_System_Version
      clastcheckin   = $_.Last_Check_in
      clastinventory = $_.Last_Inventory_Update
      csversion      = $_.CrowdeStrikeAgentVersion
      csstatus       = $_.CrowdStrikeAgentStatus
      cslastconnect  = $_.CrowdstrikeAgentLastConnect
    }
  } |
  Export-Csv -Path ('{0}\{1}' -f $winPath, $outfile) -NoTypeInformation -Append
} 

function New-Workbook
{
  Write-Host -Object 'creating new excel report' -ForegroundColor Green
  
  $files = Get-ChildItem -Path ('{0}\*.csv' -f $winPath)
  $outfile = 'jamf_report.xlsx'
  if(Test-Path -Path $winPath/$outfile)
  {
    Remove-Item -Path $winPath/$outfile -Force
  }
  
  foreach($file in $files)
  {
    $sheetname = $file.basename
    Import-Csv -Path $file.fullname  | Export-Excel -Path $winPath/$outfile -AutoSize -AutoFilter -FreezeTopRow -WorksheetName $sheetname
  }
}
  
Get-Prereqs
Get-BasicComputerInfo
Get-ComputerGroups
Get-Admins
Get-Categories
Get-CSAttributes
New-Workbook

Invoke-Item -Path $winPath




