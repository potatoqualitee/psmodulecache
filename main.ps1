param (
   [string[]]$Module,
   [string]$Type
)

$neededlist = @()
$allmodules = Get-Module -ListAvailable

foreach ($item in $Module) {
   if (-not ($allmodules | Where-Object Name -eq $item)) {
      $neededlist += $item
   }
}
switch ($Type) {
   'Needed' {
      Write-Output "$($neededlist -join ', ')"
   }
   'KeyGen' {
      if ($neededlist.count -gt 0) {
         if ($PSVersionTable.OS) {
            $os = $PSVersionTable.OS.Replace(' ','').Replace('#','')
            $platform = $PSVersionTable.Platform
         } else {
            $os = $platform = "Windows"
         }
         Write-Output "$os-$platform-$($PSVersionTable.PSVersion)-$($neededlist -join '-')"
      } else {
         Write-Output "psmodulecache"
      }
   }
   'ModulePath' {
      Write-Output ($env:PSModulePath.Split(";") | Select-Object -First 1)
   }
}