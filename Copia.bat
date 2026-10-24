@echo off
:: Cambiar la codificación de la consola a UTF-8 para corregir tildes y caracteres especiales
chcp 65001 >nul
:: Script de respaldo local para migración del usuario 
:: Definir USUARIO y DESTINO

echo ========================================================
echo SELECCION DE UNIDAD DE DESTINO
echo ========================================================
set UNIDAD=D:
set /p UNIDAD="Ingrese la letra de unidad para el respaldo (Ej: D: o E:) [Por defecto D:]: "

:: Asegurar que la letra lleve los dos puntos
if "%UNIDAD:~-1%" NEQ ":" set UNIDAD=%UNIDAD%:

set DESTINO=%UNIDAD%\Backup_Migracion\%USERNAME%

echo ========================================================
echo RESUMEN DE LA OPERACION
echo ========================================================
echo Usuario detectado  : %USERNAME%
echo Origen (Profile)   : %USERPROFILE%
echo Directorio Destino : %DESTINO%
echo.
echo Carpetas a copiar  : Desktop, Documents, Downloads,
echo                      Pictures, Favorites
echo ========================================================
echo.

:: Solicitar confirmación antes de continuar
choice /C SN /M "¿Desea iniciar la copia de seguridad? [S]i / [N]o"
:: Si la respuesta es NO (Opción 2 de choice), cancelar
if errorlevel 2 (
    echo.
    echo ========================================================
    echo Proceso cancelado por el usuario. No se ha copiado nada.
    echo ========================================================
    pause
    exit /b
)

:: Si la respuesta es SI, continuar con el proceso
echo.
echo ========================================================
echo Iniciando proceso de copia...
echo ========================================================

:: Crear las carpetas de destino en inglés
if not exist "%DESTINO%\Desktop"   mkdir "%DESTINO%\Desktop"
if not exist "%DESTINO%\Documents" mkdir "%DESTINO%\Documents"
if not exist "%DESTINO%\Downloads" mkdir "%DESTINO%\Downloads"
if not exist "%DESTINO%\Pictures"  mkdir "%DESTINO%\Pictures"
if not exist "%DESTINO%\Favorites" mkdir "%DESTINO%\Favorites"

:: Parámetros de Robocopy:
:: /E     : Copia subdirectorios, incluidos los vacíos
:: /R:1   : 1 reintento si el archivo está bloqueado
:: /W:1   : Tiempo de espera de 1 segundo entre reintentos
:: /MT:8  : Multihilo (8 hilos paralelos)
:: /XJ    : Excluye puntos de unión (junction points) para evitar bucles infinitos
:: /NFL   : (Opcional) No muestra lista de archivos en el log para agilizar la consola
:: /NDL   : (Opcional) No muestra nombres de carpetas en el log
:: Parámetros optimizados para Robocopy
:: /L : List only - Simula la copia, no crea ni copia ningún archivo
set PARAMSROBOCOPY=/L /E /R:1 /W:1 /MT:16 /XJ /NFL /NDL
echo Copiando Desktop... %ORIGEN%\Desktop -> %DESTINO%\Desktop
robocopy "%USERPROFILE%\Desktop" "%DESTINO%\Desktop" %PARAMSROBOCOPY%

echo Copiando Documents...
robocopy "%USERPROFILE%\Documents" "%DESTINO%\Documents" %PARAMSROBOCOPY%

echo Copiando Downloads...
robocopy "%USERPROFILE%\Downloads" "%DESTINO%\Downloads" %PARAMSROBOCOPY%

echo Copiando Pictures...
robocopy "%USERPROFILE%\Pictures" "%DESTINO%\Pictures" %PARAMSROBOCOPY%

echo Copiando Favorites...
robocopy "%USERPROFILE%\Favorites" "%DESTINO%\Favorites" %PARAMSROBOCOPY%

:: Registro red equipo original
echo Guardando configuracion de red...
ipconfig /all > "%DESTINO%\Configuracion_IP.txt"

:: Registro de unidades de red mapeadas
echo.
echo ========================================================
echo UNIDADES DE RED MAPEADAS
echo ========================================================
powershell -NoProfile -Command "[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; Get-CimInstance Win32_NetworkConnection | Select-Object @{N='Unidad';E={$_.LocalName}}, @{N='Estado';E={$_.State}}, @{N='Ruta Completa (UNC)';E={$_.RemoteName}}, @{N='Servidor';E={if($_.RemoteName -match '^\\\\([^\\]+)'){ $Matches[1] } else { '-' }}} | Format-Table -AutoSize" > "%DESTINO%\unidades_red.txt"
type "%DESTINO%\unidades_red.txt"

:: Registro de TODAS las unidades de almacenamiento (Locales, Removibles/USB, Red, Ópticas)
echo.
echo ========================================================
echo TODAS LAS UNIDADES DE ALMACENAMIENTO (LOCALES, USB Y RED)
echo ========================================================
powershell -NoProfile -Command "[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; Get-CimInstance Win32_LogicalDisk | Select-Object DeviceID, VolumeName, @{N='TipoUnidad';E={ switch($_.DriveType){ 2{'Removible/USB'} 3{'Disco Local'} 4{'Unidad de Red'} 5{'Disco Optico'} default{'Desconocido'} } }}, FileSystem, @{N='Tamaño(GB)';E={[math]::Round($_.Size/1GB,2)}}, @{N='Libre(GB)';E={[math]::Round($_.FreeSpace/1GB,2)}}, @{N='Ruta/Servidor Remoto';E={if($_.ProviderName){$_.ProviderName}else{'-'}}} | Format-Table -AutoSize" > "%DESTINO%\unidades_almacenamiento.txt"
type "%DESTINO%\unidades_almacenamiento.txt"

:: Registro de TODOS los adaptadores y dispositivos de red (Físicos y Virtuales)
echo.
echo ========================================================
echo ADAPTADORES Y DISPOSITIVOS DE RED CONECTADOS
echo ========================================================
powershell -NoProfile -Command "[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; Get-NetAdapter | Where-Object Status -ne 'Not Present' | ForEach-Object { $adapter = $_; $config = Get-NetIPConfiguration -InterfaceIndex $adapter.InterfaceIndex -ErrorAction SilentlyContinue 2>$null; $ipv4 = if($config.IPv4Address){ \"$($config.IPv4Address.IPAddress)/$($config.IPv4Address.PrefixLength)\" }else{ '-' }; $gw = if($config.IPv4DefaultGateway){ $config.IPv4DefaultGateway.NextHop }else{ '-' }; $dnsList = ($config.DNSServer.ServerAddresses | Where-Object { $_ -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$' }) -join ', '; $dns = if($dnsList){ $dnsList }else{ '-' }; [PSCustomObject]@{ 'Dispositivo' = $adapter.Name; 'Estado' = $adapter.Status; 'MAC' = $adapter.MacAddress; 'IPv4' = $ipv4; 'Gateway' = $gw; 'DNS' = $dns } } | Format-Table -AutoSize" > "%DESTINO%\dispositivos_red.txt"
type "%DESTINO%\dispositivos_red.txt"

powershell -NoProfile -Command "[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object IPEnabled -eq $true | ForEach-Object { $adapter = $_; [PSCustomObject]@{ 'Dispositivo' = $adapter.Description; 'MAC' = $adapter.MACAddress; 'IPv4' = $adapter.IPAddress[0]; 'Mascara' = $adapter.IPSubnet[0]; 'Gateway' = if($adapter.DefaultIPGateway){$adapter.DefaultIPGateway[0]}else{'-'}; 'DNS' = ($adapter.DNSServerSearchOrder -join ', ') } } | Format-Table -AutoSize" > "%DESTINO%\dispositivos_red2.txt"
type "%DESTINO%\dispositivos_red2.txt"


:: Registro de Ubicaciones de Red Guardadas con detalles extendidos (Protocolo, Servidor, Credenciales)
echo.
echo ========================================================
echo UBICACIONES DE RED GUARDADAS Y CONEXIONES
echo ========================================================
powershell -NoProfile -Command "[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; $netPath = [Environment]::GetFolderPath('NetworkShortcuts'); $wsh = New-Object -ComObject WScript.Shell; $shortcuts = Get-ChildItem -Path $netPath -ErrorAction SilentlyContinue | ForEach-Object { $item = $_; $target = '-'; if($item.PSIsContainer){ $targetLnk = Get-ChildItem -Path $item.FullName -Filter '*.lnk' -Recurse -ErrorAction SilentlyContinue -Force | Select-Object -First 1; if(!$targetLnk){ $targetLnk = Get-ChildItem -Path $item.FullName -Filter '*.lnk' -ErrorAction SilentlyContinue | Select-Object -First 1 }; if($targetLnk){ $target = $wsh.CreateShortcut($targetLnk.FullName).TargetPath } else { $ini = Get-Content -Path (Join-Path $item.FullName 'desktop.ini') -ErrorAction SilentlyContinue | Select-String 'URL='; if($ini){ $target = ($ini -split '=')[1] } } } else { if($item.Extension -match '\.(lnk|url)$'){ $target = $wsh.CreateShortcut($item.FullName).TargetPath } }; $proto = if($target -match '^(ftp|ftps|http|https)://'){ $Matches[1].ToUpper() } elseif($target -match '^\\\\'){ 'SMB/UNC' } else { 'LOCAL/OTRO' }; $hostName = if($target -match '^(?:ftp|ftps|http|https)://([^/:]+)'){ $Matches[1] } elseif($target -match '^\\\\([^\\]+)'){ $Matches[1] } else { '-' }; $hasCred = if($hostName -ne '-'){ $cmd = cmd /c \"keymgr /display\" 2`>$null; if($cmd -match [regex]::Escape($hostName)){ 'Sí' } else { 'No' } } else { 'No' }; [PSCustomObject]@{ 'Nombre' = $item.BaseName; 'Protocolo' = $proto; 'Servidor/Host' = $hostName; 'Ruta/URL Real' = if($target -ne '-'){ $target } else { $item.FullName }; 'Credencial Guardada' = $hasCred; 'Modificado' = $item.LastWriteTime.ToString('dd/MM/yyyy') } }; if($shortcuts){ $shortcuts | Format-Table -AutoSize } else { Write-Output 'No se encontraron accesos directos a ubicaciones de red guardadas.' }" > "%DESTINO%\ubicaciones_red.txt"
powershell -NoProfile -Command "[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; Add-Content -Path '%DESTINO%\ubicaciones_red.txt' -Value \"`n--- SESIONES Y CONEXIONES DE RED ACTIVAS ---\"`n; Get-SmbMapping | Select-Object LocalPath, RemotePath, Status | Format-Table -AutoSize | Out-String | Add-Content -Path '%DESTINO%\ubicaciones_red.txt'" 2>$null
type "%DESTINO%\ubicaciones_red.txt"

powershell -NoProfile -Command "[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; $netPath = [Environment]::GetFolderPath('NetworkShortcuts'); $sh = New-Object -ComObject Shell.Application; $shortcuts = Get-ChildItem -Path $netPath -ErrorAction SilentlyContinue | ForEach-Object { $item = $_; $target = '-'; if($item.PSIsContainer){ $targetLnk = Get-ChildItem -Path $item.FullName -Filter '*.lnk' -Recurse -Force -ErrorAction SilentlyContinue | Select-Object -First 1; if($targetLnk){ try { $folder = $sh.NameSpace($targetLnk.DirectoryName); $shortcutItem = $folder.ParseName($targetLnk.Name); $target = $shortcutItem.GetLink.Path } catch {} }; if($target -eq '-' -or [string]::IsNullOrWhiteSpace($target)){ $ini = Get-Content -Path (Join-Path $item.FullName 'desktop.ini') -ErrorAction SilentlyContinue | Select-String 'URL='; if($ini){ $target = ($ini -split '=')[1] } } } else { if($item.Extension -match '\.(lnk|url)$'){ try { $folder = $sh.NameSpace($item.DirectoryName); $shortcutItem = $folder.ParseName($item.Name); $target = $shortcutItem.GetLink.Path } catch {} } }; if(!$target -or $target -eq '-'){ $target = $item.Name }; $proto = if($target -match '^(ftp|ftps|http|https)://'){ $Matches[1].ToUpper() } elseif($target -match '^\\\\'){ 'SMB/UNC' } elseif($target -match 'ftp'){ 'FTP' } else { 'RED/SHELL' }; $hostName = if($target -match '^(?:ftp|ftps|http|https)://([^/:]+)'){ $Matches[1] } elseif($target -match '^\\\\([^\\]+)'){ $Matches[1] } else { $item.BaseName }; [PSCustomObject]@{ 'Nombre' = $item.BaseName; 'Protocolo' = $proto; 'Servidor/Host' = $hostName; 'Ruta/URL Real' = $target; 'Modificado' = $item.LastWriteTime.ToString('dd/MM/yyyy') } }; if($shortcuts){ $shortcuts | Format-Table -AutoSize } else { Write-Output 'No se encontraron accesos directos a ubicaciones de red guardadas.' }" > "%DESTINO%\ubicaciones_red2.txt"
powershell -NoProfile -Command "Add-Content -Path '%DESTINO%\ubicaciones_red.txt' -Value \"`n--- SESIONES Y CONEXIONES DE RED ACTIVAS ---\"`n; Get-SmbMapping | Select-Object LocalPath, RemotePath, Status | Format-Table -AutoSize | Out-String | Add-Content -Path '%DESTINO%\ubicaciones_red2.txt'" 2>$null
type "%DESTINO%\ubicaciones_red2.txt"


:: Obtener y guardar información de certificados personales
echo.
echo ========================================================
echo CERTIFICADOS PERSONALES DEL USUARIO
echo ========================================================
powershell -NoProfile -Command "[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; Get-ChildItem Cert:\CurrentUser\My | Select-Object Subject, Issuer, NotAfter, HasPrivateKey, EnhancedKeyUsageList | Format-Table -AutoSize" > "%DESTINO%\certificados.txt"
type "%DESTINO%\certificados.txt"

:: Registro de impresoras instaladas y puertos/IP
echo.
echo ========================================================
echo CONFIGURACION DE IMPRESORAS Y PUERTOS
echo ========================================================
powershell -NoProfile -Command "[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; Get-CimInstance Win32_Printer | ForEach-Object { $p = $_; $port = Get-CimInstance Win32_TCPIPPrinterPort -Filter \"Name = '$($p.PortName)'\" -ErrorAction SilentlyContinue; [PSCustomObject]@{ 'Impresora' = $p.Name; 'Driver' = $p.DriverName; 'Puerto' = $p.PortName; 'IP/Host' = if($port){$port.HostAddress}else{'Local/USB'}; 'Protocolo' = if($port){if($port.Protocol -eq 1){'RAW (1)'}else{'LPR (2)'}}else{'-'}; 'Puerto TCP' = if($port){$port.PortNumber}else{'-'}; 'LPR Queue' = if($port -and $port.Queue){$port.Queue}else{'-'}; 'Compartida' = $p.Shared } } | Format-Table -AutoSize" > "%DESTINO%\impresoras.txt"
type "%DESTINO%\impresoras.txt"

echo ========================================================
echo Copia de seguridad de %USERNAME% finalizada con éxito.
echo ========================================================
pause