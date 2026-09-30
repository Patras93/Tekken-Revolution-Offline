$ErrorActionPreference='Stop'
$root=Split-Path -Parent $MyInvocation.MyCommand.Path
$game=Join-Path $root 'dev_hdd0\game\NPUB31250\USRDIR\EBOOT.BIN'
if(-not (Test-Path $game)){ Write-Host 'BRAK GRY: NPUB31250'; Read-Host 'Nacisnij Enter'; exit 2 }

function PortOpenLocal([int]$p){
  try { return [bool](Get-NetTCPConnection -State Listen -LocalPort $p -ErrorAction Stop) } catch { return $false }
}
function TcpReachable([string]$host,[int]$port){
  try { return (Test-NetConnection -ComputerName $host -Port $port -InformationLevel Quiet -WarningAction SilentlyContinue) } catch { return $false }
}

$backend=Join-Path $root 'local_backend\server.ps1'
if(-not (PortOpenLocal 443)){
  Start-Process powershell.exe -WindowStyle Hidden -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File',('"'+$backend+'"')
}

$rpcnYml=Join-Path $root 'config\rpcn.yml'
$rpcnHost='rpcn.tekkenbtb.online'
if(Test-Path $rpcnYml){
  $m=Select-String -LiteralPath $rpcnYml -Pattern '^Host:\s*(.+)$' | Select-Object -First 1
  if($m){ $rpcnHost=$m.Matches[0].Groups[1].Value.Trim() }
}
$resolved=@()
try { $resolved=[Net.Dns]::GetHostAddresses($rpcnHost) | ForEach-Object {$_.IPAddressToString} } catch {}
$useLocalRpcn=($rpcnHost -in @('127.0.0.1','localhost','rpcn.tekkenbtb.online')) -and (($resolved -contains '127.0.0.1') -or $rpcnHost -in @('127.0.0.1','localhost'))

if($useLocalRpcn){
  $rpcnDir=Join-Path $root 'local_rpcn'
  if(-not (PortOpenLocal 31313)){ Start-Process -FilePath (Join-Path $rpcnDir 'rpcn.exe') -WorkingDirectory $rpcnDir -WindowStyle Hidden }
}else{
  if(-not (TcpReachable $rpcnHost 31313)){
    Write-Host ('Nie mozna polaczyc ze wspolnym RPCN: '+$rpcnHost+':31313')
    Write-Host 'Sprawdz VPN/router/firewall oraz czy host uruchomil gre.'
    Read-Host 'Nacisnij Enter'
    exit 5
  }
}

$deadline=(Get-Date).AddSeconds(8)
while((Get-Date) -lt $deadline -and (-not (PortOpenLocal 443))){ Start-Sleep -Milliseconds 250 }
if(-not (PortOpenLocal 443)){ Write-Host 'Nie uruchomil sie lokalny backend na porcie 443.'; Read-Host 'Nacisnij Enter'; exit 4 }

Start-Process -FilePath (Join-Path $root 'rpcs3.exe') -ArgumentList ('"'+$game+'"') -WorkingDirectory $root
