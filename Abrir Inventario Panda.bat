@echo off
setlocal
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$client = New-Object System.Net.Sockets.TcpClient; $running = $false; try { $client.Connect('127.0.0.1',3000); $running = $true } catch { $running = $false } finally { $client.Dispose() }; if (-not $running) { Start-Process -FilePath 'npm.cmd' -ArgumentList 'run','dev' -WorkingDirectory (Get-Location).Path -WindowStyle Hidden; Start-Sleep -Seconds 8 }; Start-Process 'http://localhost:3000'"
endlocal
