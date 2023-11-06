return
#todo


$global:ModuleNameAnalyzeIssue = @(
    @{Modules = 'Pester;5.3.0'; Shells = 'powershell,pwsh'; Updatable = $false }
    @{Modules = 'Pester.5.3.0'; Shells = 'powershell,pwsh'; Updatable = $false }
    @{Modules = 'lowercase 1.0.0-beta'; Shells = 'powershell,pwsh'; Updatable = $false }
)

$global:DuplicateSavePathIssue = @(
    #see : https://github.com/potatoqualitee/psmodulecache/issues/54#issuecomment-1740888358
    #todo With this setting we overwrite version 5.3.0
    #We have two versions but only one save directory.
    @{Modules = 'Pester:5.3.0'; PrereleaseModules = 'Pester:5.3.0-beta1'; Shells = 'powershell,pwsh'; Updatable = $false }
)

#plus une amélioration
$global:KeyNameWithoutVersionIssue = @(
    @{Modules = 'Microsoft.Powershell.SecretManagement'; PrereleaseModules = 'Microsoft.Powershell.SecretManagement'; Shells = 'powershell,pwsh'; Updatable = $false }
)


#https://github.com/PowerShell/PSResourceGet/issues/20
#!!une version de 'string' 1.1.3 issue de PSGallery et une dépendance de PSmoduleCache
#!!on enregistre qq chose qui n'est pas utilisé et incohérent.
#todo DOC l'origine de string change si on inverse l'ordre de déclaration
# $Modules = 'psgallery\string,PSModuleCache\string:1.1.3'
# $Modules = 'PSModuleCache\string:1.1.3,psgallery\string'

@{Modules = 'PSModuleCache\string:1.1.3,psgallery\string'; Shells = 'powershell,pwsh'; Updatable = $false }
#2 version de string une dépendance de PSmoduleCache
@{Modules = 'PSGallery\string:1.1.3,PSModuleCache\string'; Shells = 'powershell,pwsh'; Updatable = $false }
@{Modules = 'PSgallery\string'; PrereleaseModules = 'PSModuleCache\String:2.1.0-Beta'; Shells = 'powershell,pwsh'; Updatable = $false }

#todo rappel d'un probleme Powershell/psget
$NugetName = 'wrongnamingrule'
$SavePath = 'C:\temp\CacheTemp'
$version = '1.0.0'
