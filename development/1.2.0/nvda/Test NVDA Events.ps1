$dir=Join-Path $env:LOCALAPPDATA 'TekkenRevolutionAccess'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$event=Join-Path $dir 'event.txt'
$messages=@(
  'Menu główne. Online.',
  'Pokój prywatny. Oczekiwanie na drugiego gracza.',
  'Wybór postaci. Eliza.',
  'Przeciwnik gotowy.',
  'Rematch.'
)
foreach($m in $messages){
  [IO.File]::WriteAllText($event,$m,(New-Object Text.UTF8Encoding($false)))
  Start-Sleep -Seconds 2
}
