@echo off
:: Cambiar la codificación de la consola a UTF-8 para corregir tildes y caracteres especiales
chcp 65001 >nul

echo ========================================================
echo CALCULANDO TAMAÑO DE CARPETAS DEL PERFIL...
echo ========================================================
echo Espere un momento mientras se analizan los directorios...
echo.

:: Crear un archivo temporal con los tamaños formateados en es-ES
powershell -NoProfile -Command ^
  "$culture = [System.Globalization.CultureInfo]::GetCultureInfo('es-ES'); " ^
  "$folders = @('Desktop','Documents','Downloads','Pictures','Favorites'); " ^
  "foreach ($f in $folders) { " ^
  "  $path = Join-Path $env:USERPROFILE $f; " ^
  "  $size = 0; " ^
  "  if (Test-Path $path) { " ^
  "    $size = (Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum; " ^
  "    if ($null -eq $size) { $size = 0 }; " ^
  "  }; " ^
  "  $mbNum = [math]::Round($size / 1MB, 2); " ^
  "  $gbNum = [math]::Round($size / 1GB, 2); " ^
  "  $mbStr = $mbNum.ToString('N2', $culture); " ^
  "  $gbStr = $gbNum.ToString('N2', $culture); " ^
  "  if ($size -ge 1GB) { $display = \"$gbStr GB ($mbStr MB)\" } else { $display = \"$mbStr MB\" }; " ^
  "  Write-Output \"$f=$size=$display\"; " ^
  "}" > "%TEMP%\backup_sizes.tmp"

:: Cargar los tamaños en variables de Batch
for /f "tokens=1,2,* delims==" %%A in (%TEMP%\backup_sizes.tmp) do (
    set "SIZE_BYTES_%%A=%%B"
    set "SIZE_TEXT_%%A=%%C"
)
del "%TEMP%\backup_sizes.tmp" 2>nul

echo ========================================================
echo SELECCION DE CARPETAS A RESPALDAR
echo ========================================================
echo Indique qué carpetas desea incluir en la copia:
echo.

set CARPETAS_BATCH=
set CARPETAS_PS=
set LISTA_MOSTRAR=

:: --- DESKTOP ---
choice /C SN /M "¿Copiar Escritorio (Desktop) [%SIZE_TEXT_Desktop%]?"
if errorlevel 2 (
    echo    - Desktop: OMITIDO
) else (
    set CARPETAS_BATCH=%CARPETAS_BATCH% Desktop
    set CARPETAS_PS=%CARPETAS_PS% 'Desktop',
    set LISTA_MOSTRAR=%LISTA_MOSTRAR% Desktop,
)
echo.

:: --- DOCUMENTS ---
choice /C SN /M "¿Copiar Documentos (Documents) [%SIZE_TEXT_Documents%]?"
if errorlevel 2 (
    echo    - Documents: OMITIDO
) else (
    set CARPETAS_BATCH=%CARPETAS_BATCH% Documents
    set CARPETAS_PS=%CARPETAS_PS% 'Documents',
    set LISTA_MOSTRAR=%LISTA_MOSTRAR% Documents,
)
echo.

:: --- DOWNLOADS ---
choice /C SN /M "¿Copiar Descargas (Downloads) [%SIZE_TEXT_Downloads%]?"
if errorlevel 2 (
    echo    - Downloads: OMITIDO
) else (
    set CARPETAS_BATCH=%CARPETAS_BATCH% Downloads
    set CARPETAS_PS=%CARPETAS_PS% 'Downloads',
    set LISTA_MOSTRAR=%LISTA_MOSTRAR% Downloads,
)
echo.

:: --- PICTURES ---
choice /C SN /M "¿Copiar Imágenes (Pictures) [%SIZE_TEXT_Pictures%]?"
if errorlevel 2 (
    echo    - Pictures: OMITIDO
) else (
    set CARPETAS_BATCH=%CARPETAS_BATCH% Pictures
    set CARPETAS_PS=%CARPETAS_PS% 'Pictures',
    set LISTA_MOSTRAR=%LISTA_MOSTRAR% Pictures,
)
echo.

:: --- FAVORITES ---
choice /C SN /M "¿Copiar Favoritos (Favorites) [%SIZE_TEXT_Favorites%]?"
if errorlevel 2 (
    echo    - Favorites: OMITIDO
) else (
    set CARPETAS_BATCH=%CARPETAS_BATCH% Favorites
    set CARPETAS_PS=%CARPETAS_PS% 'Favorites',
    set LISTA_MOSTRAR=%LISTA_MOSTRAR% Favorites,
)
echo.

:: Verificar si no se seleccionó ninguna carpeta
if "%CARPETAS_BATCH%"=="" (
    echo ========================================================
    echo No ha seleccionado ninguna carpeta para copiar.
    echo Cancelando el proceso...
    echo ========================================================
    pause
    exit /b
)

:: Eliminar la última coma de la cadena de PowerShell
set CARPETAS_PS=%CARPETAS_PS:~0,-1%

:: Calcular total seleccionado mediante PowerShell
powershell -NoProfile -Command ^
  "$culture = [System.Globalization.CultureInfo]::GetCultureInfo('es-ES'); " ^
  "$folders = @(%CARPETAS_PS%); " ^
  "$total = 0; " ^
  "foreach ($f in $folders) { " ^
  "  $path = Join-Path $env:USERPROFILE $f; " ^
  "  if (Test-Path $path) { " ^
  "    $s = (Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum; " ^
  "    if ($s) { $total += $s }; " ^
  "  } " ^
  "}; " ^
  "$gbStr = ([math]::Round($total / 1GB, 2)).ToString('N2', $culture); " ^
  "$mbStr = ([math]::Round($total / 1MB, 2)).ToString('N2', $culture); " ^
  "Write-Host ('--------------------------------------------------------'); " ^
  "Write-Host ('  TAMAÑO TOTAL SELECCIONADO: ' + $gbStr + ' GB (' + $mbStr + ' MB)'); " ^
  "Write-Host ('--------------------------------------------------------')"

echo.
echo ========================================================
echo SELECCION DE UNIDAD DE DESTINO
echo ========================================================
set UNIDAD=D:
set /p UNIDAD="Ingrese la letra de unidad para el respaldo (Ej: D: o E:) [Por defecto D:]: "

:: Normalizar la letra de unidad eliminando comillas, espacios y asegurando los dos puntos
set UNIDAD=%UNIDAD:"=%
set UNIDAD=%UNIDAD: =%
if "%UNIDAD:~-1%" NEQ ":" set UNIDAD=%UNIDAD%:

set DESTINO=%UNIDAD%\Backup_Migracion\%USERNAME%

echo.
echo ========================================================
echo MODO DE EJECUCION DE ROBOCOPY
echo ========================================================
echo [S] Simulacion (/L) - Solo muestra lo que se copiaria, sin escribir cambios (Por defecto)
echo [R] Copia Real     - Copia los archivos fisicamente en el destino
echo ========================================================
choice /C SR /D S /T 10 /M "Seleccione el modo [S]imulacion / Copia [R]eal (espera 10s -> S): "

if errorlevel 2 (
    set MODO_L=
    set MODO_TEXTO=COPIA REAL
) else (
    set MODO_L=/L
    set MODO_TEXTO=SIMULACION (No se copiaran archivos)
)

echo.
echo ========================================================
echo RESUMEN DE LA OPERACION
echo ========================================================
echo Usuario detectado   : %USERNAME%
echo Origen (Profile)    : %USERPROFILE%
echo Directorio Destino  : %DESTINO%
echo Modo seleccionado   : %MODO_TEXTO%
echo Carpetas a copiar   : %LISTA_MOSTRAR%
echo ========================================================
echo.

:: Solicitar confirmación antes de continuar
choice /C SN /M "¿Desea iniciar el proceso? [S]i / [N]o"
if errorlevel 2 (
    echo.
    echo ========================================================
    echo Proceso cancelado por el usuario.
    echo ========================================================
    pause
    exit /b
)

echo.
echo ========================================================
echo Iniciando proceso [%MODO_TEXTO%]...
echo ========================================================

:: Crear directorio base
if not exist "%DESTINO%" mkdir "%DESTINO%"

:: Parámetros optimizados para Robocopy
set PARAMSROBOCOPY=%MODO_L% /E /R:1 /W:1 /MT:16 /XJ /NFL /NDL

:: Iterar dinámicamente y copiar solo las carpetas seleccionadas (sin comillas literales)
for %%F in (%CARPETAS_BATCH%) do (
    echo Copiando %%F...
    robocopy "%USERPROFILE%\%%F" "%DESTINO%\%%F" %PARAMSROBOCOPY%
)

echo.
echo ========================================================
echo Guardando información de red e infraestructura...
echo ========================================================

:: Registro IP tradicional
ipconfig /all > "%DESTINO%\Configuracion_IP.txt"

:: Registro de unidades de red mapeadas
powershell -NoProfile -Command "[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; Get-CimInstance Win32_NetworkConnection | Select-Object @{N='Unidad';E={$_.LocalName}}, @{N='Estado';E={$_.State}}, @{N='Ruta Completa (UNC)';E={$_.RemoteName}}, @{N='Servidor';E={if($_.RemoteName -match '^\\\\([^\\]+)'){ $Matches[1] } else { '-' }}} | Format-Table -AutoSize" > "%DESTINO%\unidades_red.txt"

:: Registro de todas las unidades de almacenamiento
powershell -NoProfile -Command "[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; Get-CimInstance Win32_LogicalDisk | Select-Object DeviceID, VolumeName, @{N='TipoUnidad';E={ switch($_.DriveType){ 2{'Removible/USB'} 3{'Disco Local'} 4{'Unidad de Red'} 5{'Disco Optico'} default{'Desconocido'} } }}, FileSystem, @{N='Tamaño(GB)';E={[math]::Round($_.Size/1GB,2)}}, @{N='Libre(GB)';E={[math]::Round($_.FreeSpace/1GB,2)}}, @{N='Ruta/Servidor Remoto';E={if($_.ProviderName){$_.ProviderName}else{'-'}}} | Format-Table -AutoSize" > "%DESTINO%\unidades_almacenamiento.txt"

:: Registro de adaptadores y dispositivos de red
powershell -NoProfile -Command "[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; Get-NetAdapter | Where-Object Status -ne 'Not Present' | ForEach-Object { $adapter = $_; $config = Get-NetIPConfiguration -InterfaceIndex $adapter.InterfaceIndex -ErrorAction SilentlyContinue 2>$null; $ipv4 = if($config.IPv4Address){ \"$($config.IPv4Address.IPAddress)/$($config.IPv4Address.PrefixLength)\" }else{ '-' }; $gw = if($config.IPv4DefaultGateway){ $config.IPv4DefaultGateway.NextHop }else{ '-' }; $dnsList = ($config.DNSServer.ServerAddresses | Where-Object { $_ -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$' }) -join ', '; [PSCustomObject]@{ 'Dispositivo' = $adapter.Name; 'Estado' = $adapter.Status; 'MAC' = $adapter.MacAddress; 'IPv4' = $ipv4; 'Gateway' = $gw; 'DNS' = if($dnsList){ $dnsList }else{ '-' } } } | Format-Table -AutoSize" > "%DESTINO%\dispositivos_red.txt"

:: Registro de Ubicaciones de Red Guardadas
powershell -NoProfile -Command "[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; $netPath = [Environment]::GetFolderPath('NetworkShortcuts'); $wsh = New-Object -ComObject WScript.Shell; Get-ChildItem -Path $netPath -ErrorAction SilentlyContinue | ForEach-Object { $item = $_; $target = '-'; if($item.PSIsContainer){ $targetLnk = Get-ChildItem -Path $item.FullName -Filter '*.lnk' -Recurse -ErrorAction SilentlyContinue -Force | Select-Object -First 1; if($targetLnk){ $target = $wsh.CreateShortcut($targetLnk.FullName).TargetPath } else { $ini = Get-Content -Path (Join-Path $item.FullName 'desktop.ini') -ErrorAction SilentlyContinue | Select-String 'URL='; if($ini){ $target = ($ini -split '=')[1] } } } else { if($item.Extension -match '\.(lnk|url)$'){ $target = $wsh.CreateShortcut($item.FullName).TargetPath } }; $proto = if($target -match '^(ftp|ftps|http|https)://'){ $Matches[1].ToUpper() } elseif($target -match '^\\\\'){ 'SMB/UNC' } else { 'LOCAL/OTRO' }; $hostName = if($target -match '^(?:ftp|ftps|http|https)://([^/:]+)'){ $Matches[1] } elseif($target -match '^\\\\([^\\]+)'){ $Matches[1] } else { '-' }; [PSCustomObject]@{ 'Nombre' = $item.BaseName; 'Protocolo' = $proto; 'Servidor/Host' = $hostName; 'Ruta/URL Real' = if($target -ne '-'){ $target } else { $item.FullName }; 'Modificado' = $item.LastWriteTime.ToString('dd/MM/yyyy') } } | Format-Table -AutoSize" > "%DESTINO%\ubicaciones_red.txt"

:: Registro de Certificados Personales
powershell -NoProfile -Command "[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; Get-ChildItem Cert:\CurrentUser\My | Select-Object Subject, Issuer, NotAfter, HasPrivateKey | Format-Table -AutoSize" > "%DESTINO%\certificados.txt"

:: Registro de Impresoras instaladas
powershell -NoProfile -Command "[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; Get-CimInstance Win32_Printer | ForEach-Object { $p = $_; $port = Get-CimInstance Win32_TCPIPPrinterPort -Filter \"Name = '$($p.PortName)'\" -ErrorAction SilentlyContinue; [PSCustomObject]@{ 'Impresora' = $p.Name; 'Driver' = $p.DriverName; 'Puerto' = $p.PortName; 'IP/Host' = if($port){$port.HostAddress}else{'Local/USB'}; 'Protocolo' = if($port){if($port.Protocol -eq 1){'RAW (1)'}else{'LPR (2)'}}else{'-'}; 'Puerto TCP' = if($port){$port.PortNumber}else{'-'}; 'Compartida' = $p.Shared } } | Format-Table -AutoSize" > "%DESTINO%\impresoras.txt"

echo.
echo ========================================================
echo Proceso de %USERNAME% [%MODO_TEXTO%] finalizado con éxito.
echo Los archivos de configuración se guardaron en:
echo %DESTINO%
echo ========================================================
pause