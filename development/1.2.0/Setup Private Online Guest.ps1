param([string]$Server='100.66.211.73')
$ErrorActionPreference='Stop'
$root=Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$rpcnYml=Join-Path $root 'config\rpcn.yml'
if(-not (Test-Path $rpcnYml)){ throw 'Brak config\rpcn.yml' }
if([string]::IsNullOrWhiteSpace($Server)){ $Server='100.66.211.73' }
if($Server -notmatch '^[A-Za-z0-9\.\-:]+$'){ throw 'Nieprawidlowy adres serwera.' }

$admin=([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if(-not $admin){
  Start-Process powershell.exe -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File',('"'+$MyInvocation.MyCommand.Path+'"'),'-Server',('"'+$Server+'"')
  exit
}

$hostsPath="$env:SystemRoot\System32\drivers\etc\hosts"
$lines=Get-Content -LiteralPath $hostsPath
$lines=$lines | Where-Object {$_ -notmatch '(?i)\s+(patch|rpcn)\.tekkenbtb\.online\s*$'}
$lines += '127.0.0.1 patch.tekkenbtb.online'
Set-Content -LiteralPath $hostsPath -Value $lines -Encoding ascii
ipconfig /flushdns | Out-Null

$y=Get-Content -LiteralPath $rpcnYml -Raw
$y=[regex]::Replace($y,'(?m)^Host:.*$',('Host: '+$Server))
$y=[regex]::Replace($y,'(?m)^Hosts:.*$',('Hosts: Tekken Revolution Private Online|'+$Server))
Set-Content -LiteralPath $rpcnYml -Value $y -Encoding utf8

Write-Host ''
Write-Host ('TRYB GOSC GOTOWY. RPCN: '+$Server)
Write-Host 'Backend gry pozostaje lokalny.'
Write-Host 'Kazdy gracz musi uzywac osobnego konta RPCN na tym wspolnym serwerze.'
Read-Host 'Nacisnij Enter'
