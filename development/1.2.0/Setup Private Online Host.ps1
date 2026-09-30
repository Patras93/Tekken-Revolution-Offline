param([switch]$NoFirewall)
$ErrorActionPreference='Stop'
$root=Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$rpcnDir=Join-Path $root 'local_rpcn'
$rpcnExe=Join-Path $rpcnDir 'rpcn.exe'
$rpcnYml=Join-Path $root 'config\rpcn.yml'
if(-not (Test-Path $rpcnExe)){ throw 'Brak local_rpcn\rpcn.exe' }
if(-not (Test-Path $rpcnYml)){ throw 'Brak config\rpcn.yml' }

$admin=([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if(-not $admin){
  Start-Process powershell.exe -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File',('"'+$MyInvocation.MyCommand.Path+'"')
  exit
}

$hostsPath="$env:SystemRoot\System32\drivers\etc\hosts"
$lines=Get-Content -LiteralPath $hostsPath
$lines=$lines | Where-Object {$_ -notmatch '(?i)\s+(patch|rpcn)\.tekkenbtb\.online\s*$'}
$lines += '127.0.0.1 patch.tekkenbtb.online'
$lines += '127.0.0.1 rpcn.tekkenbtb.online'
Set-Content -LiteralPath $hostsPath -Value $lines -Encoding ascii
ipconfig /flushdns | Out-Null

$y=Get-Content -LiteralPath $rpcnYml -Raw
$y=[regex]::Replace($y,'(?m)^Host:.*$','Host: rpcn.tekkenbtb.online')
$y=[regex]::Replace($y,'(?m)^Hosts:.*$','Hosts: Tekken Revolution Private Online|rpcn.tekkenbtb.online')
Set-Content -LiteralPath $rpcnYml -Value $y -Encoding utf8

if(-not $NoFirewall){
  netsh advfirewall firewall delete rule name="Tekken Revolution RPCN TCP 31313" | Out-Null
  netsh advfirewall firewall delete rule name="Tekken Revolution RPCN UDP 3657" | Out-Null
  netsh advfirewall firewall add rule name="Tekken Revolution RPCN TCP 31313" dir=in action=allow protocol=TCP localport=31313 program="$rpcnExe" | Out-Null
  netsh advfirewall firewall add rule name="Tekken Revolution RPCN UDP 3657" dir=in action=allow protocol=UDP localport=3657 program="$rpcnExe" | Out-Null
}

$ips=Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object {$_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*'} | Select-Object -ExpandProperty IPAddress
Write-Host ''
Write-Host 'TRYB HOST GOTOWY.'
Write-Host 'Backend gry: lokalny.'
Write-Host 'RPCN: ten komputer.'
Write-Host 'Porty wymagane dla gry przez internet: TCP 31313 i UDP 3657.'
Write-Host 'Adresy tego komputera:'
$ips | ForEach-Object { Write-Host ('  '+$_) }
Write-Host ''
Write-Host 'Kolezanka uruchamia Setup Private Online Guest.ps1 i wpisuje adres tego komputera lub adres VPN.'
Read-Host 'Nacisnij Enter'
