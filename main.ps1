param (
   [string[]]$Module,
   [ValidateSet("KeyGen","ModulePath", "SaveModule")]
   [string]$Type,
   [string]$Shell
)
$Shell = $Shell.Replace(" ","")
$shellarray = $Shell -split ","
switch ($Type) {
   'KeyGen' {
      # all this splitting and joining accomodates for powershell and pwsh
      Write-Output "$env:RUNNER_OS-$platform-$($shellarray -join "-")-$(($Module.Split(",") -join '-').Replace(' ',''))"
   }
   'ModulePath' {
      if ($env:RUNNER_OS -eq "Windows") {
         $modpaths = @()
         $modpath = ($env:PSModulePath.Split(";") | Select-Object -First 1)
         if ($shellarray -contains "powershell") {
            $modpaths += $modpath.Replace("PowerShell","WindowsPowerShell")
         }
         if ($shellarray -contains "pwsh") {
            $modpaths += $modpath.Replace("PowerShell","WindowsPowerShell")
         }
         Write-Output ($modpaths -join "`n            ")
      } else {
         ($env:PSModulePath.Split(":") | Select-Object -First 1)
      }
   }
   'SaveModule' {
      $moduleinfo = Import-CliXml -Path (Join-Path $home -ChildPath cache.xml)
      Write-Output "Trusting PSGallery"
      Set-PSRepository PSGallery -InstallationPolicy Trusted

      $modulelist = $moduleinfo.Modules
      Write-Output "Saving modules $modulelist to $($moduleinfo.ModulePath)"
      $modules = $modulelist.Split(",").Trim()
      $force = [bool]($moduleinfo.force)
      $allowprerelease = [bool]($moduleinfo.allowprerelease)

      foreach ($module in $modules) {
         foreach ($psshell in $shellarray) {
            Write-Output "Installing module $module on $psshell"
            $modpath = ($env:PSModulePath.Split(";") | Select-Object -First 1)
            if ($psshell -eq "powershell") {
               $modpath = $modpath.Replace("PowerShell","WindowsPowerShell")
            }
            $item, $version = $module.Split(":")
            if ($version) {
               Save-Module $item -RequiredVersion $version -ErrorAction Stop -Force:$force -AllowPrerelease:$allowprerelease -Path $modpath
            } else {
               Save-Module $item -ErrorAction Stop -Force:$force -AllowPrerelease:$allowprerelease -Path $modpath
            }
         }
      }
   }
}