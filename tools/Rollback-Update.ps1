param(
  [Parameter(Mandatory=$true)][string]$BackupDir
)
$ErrorActionPreference='Stop'
$root=Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Get-ChildItem -LiteralPath $BackupDir -Recurse -File | ForEach-Object {
  $rel=$_.FullName.Substring($BackupDir.Length).TrimStart('\')
  $dst=Join-Path $root $rel
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst) | Out-Null
  Copy-Item -LiteralPath $_.FullName -Destination $dst -Force
}
Write-Host 'Przywrocono backup.'
