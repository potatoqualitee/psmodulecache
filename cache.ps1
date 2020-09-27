param ($Module)
$module = $Module.Split(",")
foreach ($item in $module.Trim()) {
    Write-Output $item
}