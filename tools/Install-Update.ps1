param(
  [Parameter(Mandatory=$true)][string]$UpdateDir
)
$ErrorActionPreference='Stop'
$root=Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$manifest=Join-Path $UpdateDir 'manifest.json'
if(-not (Test-Path $manifest)){ throw 'Brak manifest.json' }
$m=Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json
$stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
$backupRoot=Join-Path $root ('custom_updates\backup\'+$m.version+'_'+$stamp)
New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null
foreach($f in $m.files){
  $src=Join-Path $UpdateDir $f.source
  $dst=Join-Path $root $f.target
  if(-not (Test-Path $src)){ throw ('Brak pliku update: '+$src) }
  if(Test-Path $dst){
    $b=Join-Path $backupRoot $f.target
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $b) | Out-Null
    Copy-Item -LiteralPath $dst -Destination $b -Force
  }
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst) | Out-Null
  Copy-Item -LiteralPath $src -Destination $dst -Force
}
$m | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $root 'custom_updates\installed_update.json') -Encoding utf8
Write-Host ('Zainstalowano update '+$m.version)
Write-Host ('Backup: '+$backupRoot)
