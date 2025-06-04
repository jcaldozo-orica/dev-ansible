$now=get-date
$hostname=`hostname
$certs=Get-ChildItem -Path cert:\LocalMachine\My -Recurse;
$cert = $certs | Where-Object {$_.Subject -eq 'CN='+$hostname+'.ori.orica.net' -and ($_.Issuer -eq 'CN=Orica-Subordinate-CA2, DC=ori, DC=orica, DC=net' -or $_.Issuer -eq 'CN=Orica-Subordinate-CA1, DC=ori, DC=orica, DC=net') -and $_.NotAfter -gt $now} | sort $_.NotAfter
$CertThumbprint= $cert[0].Thumbprint

[int] $compliancecount=0
set $listener5986=null
$listeners = get-item  -Path WSMan:\LocalHost\Listener\* |Where-Object {$_.Keys -like '*HTTPS*'} | select name
foreach ($listener in $listeners.name) {
 $listener_port = (get-item -path WSMan:\LocalHost\Listener\$listener\Port).value
 $listener_cert = (get-item -path WSMan:\LocalHost\Listener\$listener\CertificateThumbprint).value
 if ($listener_port -eq '5986' -and $listener_cert -eq $CertThumbprint){
	$compliancecount+=1
	}
 elseif ($listener_port -eq '5986' -and $listener_cert -ne $CertThumbprint){
	$listener5986=$listener
	}
 else {
   $compliancecount+=0
 }
}

if ($compliancecount -gt 0){$Compliance = "True"} else {$Compliance = "False"}
$Compliance

##remediation
##should include above script too
if ($compliancecount -eq 0 -and $listener5986 -ne $null -and $cert -ne $null) {
  write-output "Option 1: listener5986 exists but different cert"
  remove-item -Path WSMan:\LocalHost\Listener\$listener5986 -recurse
  New-Item -Path WSMan:\LocalHost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $CertThumbprint -Force;
  netsh advfirewall firewall add rule name="winRM HTTPS" dir=in action=allow protocol=TCP localport=5986

} elseif ($compliancecount -eq 0 -and $listener5986 -eq $null -and $cert -ne $null){
    write-output "Option 2: no listener5986 exists"
  New-Item -Path WSMan:\LocalHost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $CertThumbprint -Force;
  netsh advfirewall firewall add rule name="winRM HTTPS" dir=in action=allow protocol=TCP localport=5986
} elseif ($compliancecount -eq 0 -and $cert -eq $null){
  write-output 'Option 3: machine is not compliant and there is no CA1/CA2 certificate'
} else {
  write-output 'Option 4: machine is compliant'
  netsh advfirewall firewall add rule name="winRM HTTPS" dir=in action=allow protocol=TCP localport=5986
}
