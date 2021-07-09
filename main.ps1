param (
   [string[]]$Module,
   [ValidateSet("KeyGen","ModulePath", "SaveModule")]
   [string]$Type,
   [string]$Shell
)
$shells = $Shell.Split(",").Trim()
switch ($Type) {
   'KeyGen' {
      # all this splitting and joining accomodates for powershell and pwsh
      Write-Output "$env:RUNNER_OS-v3.5test-$($shells -join "-")-$(($Module.Split(",") -join '-').Replace(' ',''))"
   }
   'ModulePath' {
      if ($env:RUNNER_OS -eq "Windows") {
         $modpath = ($env:PSModulePath.Split(";") | Select-Object -First 1)
         if ($Shell -eq "powershell") {
            return $modpath.Replace("PowerShell","WindowsPowerShell")
         }
         if ($Shell -eq "pwsh") {
            return $modpath
         }
         if ($shells -contains "pwsh" -and $shells -contains "powershell") {
            return $modpath.Replace("PowerShell","*PowerShell*")
         }
      } else {
         ($env:PSModulePath.Split(":") | Select-Object -First 1)
      }
   }
   'SaveModule' {
      $moduleinfo = Import-CliXml -Path (Join-Path $home -ChildPath cache.xml)
      Write-Output "Trusting repository PSGallery"
      Set-PSRepository PSGallery -InstallationPolicy Trusted
      $modules = $moduleinfo.Modules.Split(",").Trim()
      $shells = $moduleinfo.Shell.Split(",").Trim()
      $force = [bool]($moduleinfo.force)
      $allowprerelease = [bool]($moduleinfo.allowprerelease)

      foreach ($module in $modules) {
         foreach ($psshell in $shells) {
            if ($env:RUNNER_OS -eq "Windows") {
               $modpath = ($env:PSModulePath.Split(";") | Select-Object -First 1)
               if ($psshell -eq "powershell") {
                  $modpath = $modpath.Replace("PowerShell","WindowsPowerShell")
               }
            } else {
               $modpath = ($env:PSModulePath.Split(":") | Select-Object -First 1)
            } 
            Write-Output "Saving module $module on $psshell to $modpath"
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