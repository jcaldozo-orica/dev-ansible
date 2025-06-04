[Net.ServicePointManager]::SecurityProtocol = 'tls12, tls11';
$ProgressPreference                         = 'SilentlyContinue';
[string]$ScriptFile                         = 'C:\Users\Public\IcingaForWindows.ps1';

Invoke-WebRequest `
    -UseBasicParsing `
    -Uri 'https://icinga.ori.orica.net/IcingaForWindows/IcingaForWindows.ps1' `
    -OutFile $ScriptFile;

& $ScriptFile `
    -ModuleDirectory 'C:\Program Files\WindowsPowerShell\Modules\' `
	-IcingaRepository 'https://icinga.ori.orica.net/IcingaForWindows/stable/ifw.repo.json' `
    -SkipWizard;

Add-IcingaRepository -Name 'Icinga Stable' -RemotePath 'https://icinga.ori.orica.net/IcingaForWindows/stable/ifw.repo.json' -force

Install-IcingaComponent -Name Framework -confirm -force;
Install-IcingaComponent -Name Plugins -confirm -force;

Stop-ScheduledTask  -taskpath "\Icinga\Icinga for Windows\" -taskname  "Management Task";
Stop-ScheduledTask  -taskpath "\Icinga\Icinga for Windows\" -taskname  "Renew Certificate";
disable-scheduledtask -taskpath "\Icinga\Icinga for Windows\" -taskname "Renew Certificate";
disable-scheduledtask -taskpath "\Icinga\Icinga for Windows\" -taskname  "Management Task";