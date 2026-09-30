param(
  [switch]$CheckOnly,
  [string]$Repo = 'Patras93/Tekken-Revolution-Offline'
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Assert-SafeRelativePath([string]$Path) {
  if ([string]::IsNullOrWhiteSpace($Path)) { throw 'Pusta sciezka w manifeście.' }
  if ([IO.Path]::IsPathRooted($Path)) { throw ('Niedozwolona sciezka absolutna: ' + $Path) }
  $parts = $Path -split '[\\/]'
  if ($parts -contains '..') { throw ('Niedozwolone .. w sciezce: ' + $Path) }
}

$here = $PSScriptRoot
$leaf = Split-Path -Leaf $here
if ($leaf -eq 'tools' -or $leaf -eq 'custom_updates') {
  $root = Split-Path -Parent $here
} else {
  $root = $here
}
$apiBase = "https://api.github.com/repos/$Repo"
$headers = @{ 'User-Agent' = 'Tekken-Revolution-Custom-Updater' }

Write-Host 'Sprawdzanie aktualizacji Tekken Revolution...'

$dirs = Invoke-RestMethod -Uri "$apiBase/contents/releases" -Headers $headers
$versions = @()
foreach ($d in $dirs) {
  if ($d.type -eq 'dir' -and $d.name -match '^\d+\.\d+\.\d+$') {
    try {
      $versions += [pscustomobject]@{ Text=$d.name; Version=[version]$d.name }
    } catch {}
  }
}
if (-not $versions) { throw 'Nie znaleziono wersji w repozytorium.' }

$latest = $versions | Sort-Object Version -Descending | Select-Object -First 1
$installedFile = Join-Path $root 'custom_updates\installed_update.json'
$current = [version]'0.0.0'
if (Test-Path $installedFile) {
  try {
    $installed = Get-Content -LiteralPath $installedFile -Raw | ConvertFrom-Json
    if ($installed.version) { $current = [version]$installed.version }
  } catch {}
}

Write-Host ('Zainstalowana wersja: ' + $current)
Write-Host ('Najnowsza wersja: ' + $latest.Version)

if ($latest.Version -le $current) {
  Write-Host 'Masz najnowsza wersje.'
  exit 0
}
if ($CheckOnly) {
  Write-Host ('Dostepna aktualizacja: ' + $latest.Text)
  exit 10
}

$releaseRoot = Join-Path $root ('custom_updates\downloads\' + $latest.Text)
if (Test-Path $releaseRoot) { Remove-Item -LiteralPath $releaseRoot -Recurse -Force }
New-Item -ItemType Directory -Force -Path $releaseRoot | Out-Null

$manifestUrl = "https://raw.githubusercontent.com/$Repo/main/releases/$($latest.Text)/manifest.json"
$manifestPath = Join-Path $releaseRoot 'manifest.json'
Invoke-WebRequest -UseBasicParsing -Uri $manifestUrl -Headers $headers -OutFile $manifestPath
$m = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
if ($m.version -ne $latest.Text) { throw 'Wersja manifestu nie zgadza sie z katalogiem release.' }

foreach ($f in $m.files) {
  Assert-SafeRelativePath $f.source
  Assert-SafeRelativePath $f.target
  $srcRel = ($f.source -replace '\\','/')
  $src = Join-Path $releaseRoot $f.source
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $src) | Out-Null
  $url = "https://raw.githubusercontent.com/$Repo/main/releases/$($latest.Text)/$srcRel"
  Invoke-WebRequest -UseBasicParsing -Uri $url -Headers $headers -OutFile $src
}

Get-Process rpcs3 -ErrorAction SilentlyContinue | Stop-Process -Force

$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backupRoot = Join-Path $root ('custom_updates\backup\' + $m.version + '_' + $stamp)
New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null

$state = [ordered]@{
  version = $m.version
  installed_at = (Get-Date).ToString('s')
  backup_dir = $backupRoot
  files = @()
}

foreach ($f in $m.files) {
  $src = Join-Path $releaseRoot $f.source
  $dst = Join-Path $root $f.target
  $existed = Test-Path $dst
  if ($existed) {
    $b = Join-Path $backupRoot $f.target
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $b) | Out-Null
    Copy-Item -LiteralPath $dst -Destination $b -Force
  }
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst) | Out-Null
  Copy-Item -LiteralPath $src -Destination $dst -Force
  $state.files += [pscustomobject]@{
    target = $f.target
    existed_before = [bool]$existed
  }
}

$m | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $installedFile -Encoding UTF8
$state | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $root 'custom_updates\install_state.json') -Encoding UTF8

Write-Host ('Zainstalowano update ' + $m.version)
Write-Host ('Backup: ' + $backupRoot)
Write-Host 'Uruchom ponownie RPCS3.'
