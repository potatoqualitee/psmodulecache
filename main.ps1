param (
   [string[]]$Module,
   [ValidateSet("KeyGen","ModulePath", "SaveModule")]
   [string]$Type,
   [ValidateSet("pwsh","powershell")]
   [string]$Shell
)

switch ($Type) {
   'KeyGen' {
      if ($Shell -eq "powershell" -and $PSVersionTable.Platform -eq "Win32NT") {
         $versiontable = Invoke-Command -ScriptBlock { 
            powershell -command { $PSVersionTable } 
         }
      } else {
         $versiontable = $PSVersionTable
      }
      if ($versiontable.OS) {
         $platform = $versiontable.Platform
      } else {
         $platform = "Windows"
      }
      Write-Output "v2-$env:RUNNER_OS-$platform-$($versiontable.PSVersion)-$($Module.Split(",") -join '-')"
   }
   'ModulePath' {
      if ($env:RUNNER_OS -eq "Windows") {
         $modpath = ($env:PSModulePath.Split(";") | Select-Object -First 1)
         if ($Shell -eq "powershell") {
            $modpath = $modpath.Replace("PowerShell","WindowsPowerShell")
         }
         Write-Output $modpath
      } else {
         Write-Output ($env:PSModulePath.Split(":") | Select-Object -First 1)
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
         Write-Output "Installing module $module on PowerShell $($PSVersionTable.PSVersion)"
         $item, $version = $module.Split(":")
         if ($version) {
            Save-Module $item -RequiredVersion $version -ErrorAction Stop -Force:$force -AllowPrerelease:$allowprerelease -Path $moduleinfo.ModulePath
         } else {
            Save-Module $item -ErrorAction Stop -Force:$force -AllowPrerelease:$allowprerelease -Path $moduleinfo.ModulePath
         }
      }
   }
}