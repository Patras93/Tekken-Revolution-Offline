$ErrorActionPreference='Stop'
$root=Split-Path -Parent $MyInvocation.MyCommand.Path
$game=Join-Path $root 'dev_hdd0\game\NPUB31250\USRDIR\EBOOT.BIN'
if(-not (Test-Path $game)){ Write-Host 'BRAK GRY: NPUB31250'; exit 2 }

function PortOpen([int]$p){
  try { return [bool](Get-NetTCPConnection -State Listen -LocalPort $p -ErrorAction Stop) } catch { return $false }
}

$backend=Join-Path $root 'tr_local_backend\server.ps1'
if(-not (PortOpen 443)){
  Start-Process powershell.exe -WindowStyle Hidden -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File',('"'+$backend+'"')
}

$rpcnDir=Join-Path $root 'tr_local_rpcn\server_1.8.7'
$rpcnExe=Join-Path $rpcnDir 'rpcn.exe'
if(-not (PortOpen 31313)){
  Start-Process -FilePath $rpcnExe -WorkingDirectory $rpcnDir -WindowStyle Hidden
}

$deadline=(Get-Date).AddSeconds(8)
while((Get-Date) -lt $deadline -and ((-not (PortOpen 443)) -or (-not (PortOpen 31313)))){
  Start-Sleep -Milliseconds 250
}
if((-not (PortOpen 443)) -or (-not (PortOpen 31313))){
  Write-Host ('Backend 443: '+(PortOpen 443))
  Write-Host ('RPCN 31313: '+(PortOpen 31313))
  exit 4
}

Start-Process -FilePath (Join-Path $root 'rpcs3.exe') -ArgumentList ('"'+$game+'"') -WorkingDirectory $root
