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


$originallist = @()
foreach ($module in $Modules) {
      $item, $version = $module.Split(':')
      $originallist += $item
}

switch ($Type) {
   'Needed' {
      Write-Output "$($neededlist -join ', ')"
   }
   'ModulesToCache' {
      Write-Output "$($originallist -join ', ')"
   }
   'KeyGen' {
      if ($originallist.count -gt 0) {
         Write-Output "$($PSVersionTable.Platform)-$($originallist -join '-')"
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