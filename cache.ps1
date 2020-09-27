param ($Module)
$module = $Module.Split(",")
foreach ($item in $module.Trim()) {
   Install-Module $item -Force
}