param (
   [string[]]$Modules,
   [string]$Type
)

$neededlist = @()
$allmodules = Get-Module -ListAvailable

foreach ($module in $Modules) {
   $item, $version = $module.Split(':')
   if (-not ($allmodules | Where-Object Name -eq $item)) {
      $neededlist += $item
   }
}

switch ($Type) {
   'Needed' {
      Write-Output "$($neededlist -join ', ')"
   }
   'ModulesToCache' {
      $cachethis = @()
      foreach ($module in $Modules) {
         $item, $version = $module.Split(':')
            $cachethis += $item
      }
      Write-Output "$($cachethis -join ', ')"
   }
   'KeyGen' {
      if ($neededlist.count -gt 0) {
         Write-Output "$($PSVersionTable.Platform)-$($neededlist -join '-')"
      }
      else {
         Write-Output "psmodulecache"
      }
   }
   'ModulePath' {
      if ($PSVersionTable.Platform -eq "Win32NT") {
         Write-Output "C:\Users\runneradmin\Documents\PowerShell\Modules\"
      } else {
         Write-Output "/home/runner/.local/share/powershell/Modules/"
      }
   }
}