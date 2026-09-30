$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$log = Join-Path $root 'server.log'
"START $(Get-Date -Format o)" | Set-Content -LiteralPath $log -Encoding utf8

$thumbprint = '8C8CEEC481DCF881CAEC1124F13DC4099B6BAEF3'
$cert = Get-Item "Cert:\CurrentUser\My\$thumbprint" -ErrorAction Stop
$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback,443)
$listener.Start()
"LISTEN 127.0.0.1:443 thumbprint=$($cert.Thumbprint)" | Add-Content -LiteralPath $log

function Send-Response($ssl,[int]$status,[string]$ctype,[byte[]]$body,[hashtable]$extra){
    $reason = if($status -eq 200){'OK'}elseif($status -eq 404){'Not Found'}else{'Error'}
    $crlf = [char]13 + [char]10
    $hdr = "HTTP/1.1 $status $reason$crlf" + "Content-Type: $ctype$crlf" + "Content-Length: $($body.Length)$crlf" + "Connection: close$crlf"
    if($extra){ foreach($k in $extra.Keys){ $hdr += "$($k): $($extra[$k])$crlf" } }
    $hdr += $crlf
    $hb = [System.Text.Encoding]::ASCII.GetBytes($hdr)
    $ssl.Write($hb,0,$hb.Length)
    if($body.Length -gt 0){ $ssl.Write($body,0,$body.Length) }
    $ssl.Flush()
}

while($true){
    $client = $listener.AcceptTcpClient()
    try{
        $ssl = [System.Net.Security.SslStream]::new($client.GetStream(),$false)
        $ssl.AuthenticateAsServer($cert,$false,[System.Security.Authentication.SslProtocols]::Tls12,$false)
        $reader = [System.IO.StreamReader]::new($ssl,[System.Text.Encoding]::ASCII,$false,1024,$true)
        $line = $reader.ReadLine()
        if([string]::IsNullOrWhiteSpace($line)){ continue }
        $parts = $line.Split(' ')
        $method = $parts[0]
        $path = $parts[1]
        while(($h = $reader.ReadLine()) -ne $null -and $h -ne ''){}
        "$(Get-Date -Format o) $method $path" | Add-Content -LiteralPath $log
        $extra = @{}
        switch -Regex ($path) {
            '^/resolve/NPUB31250$' {
                $body=[IO.File]::ReadAllBytes((Join-Path $root 'resolve_NPUB31250.json'))
                Send-Response $ssl 200 'application/json' $body $extra
            }
            '^/patches/tr$' {
                $body=[IO.File]::ReadAllBytes((Join-Path $root 'patches_tr.bin'))
                $extra=@{'x-comm-id'='NPWR04645';'x-sub-id'='01';'x-title-id'='NPUB31250'}
                Send-Response $ssl 200 'application/octet-stream' $body $extra
            }
            '^/modules/tr/manifest$' {
                $body=[IO.File]::ReadAllBytes((Join-Path $root 'modules_tr_manifest.json'))
                Send-Response $ssl 200 'application/json' $body $extra
            }
            '^/modules/tr/tr_logic\.dll$' {
                $body=[IO.File]::ReadAllBytes((Join-Path $root 'tr_logic.dll'))
                Send-Response $ssl 200 'application/octet-stream' $body $extra
            }
            '^/launcher/config$' {
                $body=[IO.File]::ReadAllBytes((Join-Path $root 'launcher_config.json'))
                Send-Response $ssl 200 'application/json' $body $extra
            }
            '^/launcher/restart_epoch$' {
                $body=[IO.File]::ReadAllBytes((Join-Path $root 'restart_epoch.json'))
                Send-Response $ssl 200 'application/json' $body $extra
            }
            '^/launcher/hook/windows$' {
                $body=[IO.File]::ReadAllBytes((Join-Path $root 'version.dll.original'))
                Send-Response $ssl 200 'application/octet-stream' $body $extra
            }
            '^/launcher/updater/windows/binary$' {
                $body=[IO.File]::ReadAllBytes((Join-Path $root 'tr_updater.exe'))
                Send-Response $ssl 200 'application/octet-stream' $body $extra
            }
            '^/launcher/update/windows/manifest$' {
                $body=[IO.File]::ReadAllBytes((Join-Path $root 'launcher_update_windows_manifest.json'))
                Send-Response $ssl 200 'application/json' $body $extra
            }
            default {
                $body=[Text.Encoding]::UTF8.GetBytes('{"detail":"Not Found"}')
                Send-Response $ssl 404 'application/json' $body $extra
            }
        }
    } catch {
        "$(Get-Date -Format o) ERROR $($_.Exception.Message)" | Add-Content -LiteralPath $log
    } finally {
        try{$ssl.Dispose()}catch{}
        $client.Close()
    }
}
