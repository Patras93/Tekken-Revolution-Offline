param(
  [string]$StateFile
)

$ErrorActionPreference='Stop'

$here = $PSScriptRoot
$leaf = Split-Path -Leaf $here
if ($leaf -eq 'tools' -or $leaf -eq 'custom_updates') {
  $root = Split-Path -Parent $here
} else {
  $root = $here
}

if ([string]::IsNullOrWhiteSpace($StateFile)) {
  $StateFile = Join-Path $root 'custom_updates\install_state.json'
}
if (-not (Test-Path $StateFile)) { throw 'Brak install_state.json.' }

$state = Get-Content -LiteralPath $StateFile -Raw | ConvertFrom-Json
Get-Process rpcs3 -ErrorAction SilentlyContinue | Stop-Process -Force

foreach ($f in $state.files) {
  $dst = Join-Path $root $f.target
  if ($f.existed_before) {
    $src = Join-Path $state.backup_dir $f.target
    if (-not (Test-Path $src)) { throw ('Brak pliku backup: ' + $src) }
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst) | Out-Null
    Copy-Item -LiteralPath $src -Destination $dst -Force
  } else {
    if (Test-Path $dst) { Remove-Item -LiteralPath $dst -Force }
  }
}

Write-Host ('Cofnieto update ' + $state.version)
Write-Host 'Uruchom ponownie RPCS3.'
