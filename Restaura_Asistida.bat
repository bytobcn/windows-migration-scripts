@echo off
:: Cambiar la codificación de la consola a UTF-8 para corregir tildes y caracteres especiales
chcp 65001 >nul

echo ========================================================
echo RESTAURACION DE COPIA DE SEGURIDAD
echo ========================================================
set UNIDAD=D:
set /p UNIDAD="Ingrese la letra de unidad desde la que restaurar (Ej: D: o E:) [Por defecto D:]: "

:: Normalizar la letra de unidad eliminando comillas, espacios y asegurando los dos puntos
set UNIDAD=%UNIDAD:"=%
set UNIDAD=%UNIDAD: =%
if "%UNIDAD:~-1%" NEQ ":" set UNIDAD=%UNIDAD%:

set ORIGEN=%UNIDAD%\Backup_Migracion\%USERNAME%
set DESTINO=%USERPROFILE%

choice /C SN /M "¿Desea iniciar la RESTAURACIÓN de los datos? [S]i / [N]o"
if errorlevel 2 (
    echo.
    echo ========================================================
    echo Proceso cancelado por el usuario. No se ha restaurado nada.
    echo ========================================================
    pause
    exit /b
)

echo.
echo ========================================================
echo RESUMEN DE LA RESTAURACION
echo ========================================================
echo Usuario detectado : %USERNAME%
echo Directorio Origen  : %ORIGEN%
echo Destino (Perfil)   : %DESTINO%
echo ========================================================
echo.

if not exist "%ORIGEN%" (
    echo ERROR: No se encontró la carpeta de respaldo para el usuario %USERNAME% en:
    echo %ORIGEN%
    echo.
    pause
    exit /b
)

:: Parámetros optimizados de Robocopy
set PARAMSROBOCOPY=/E /R:1 /W:1 /MT:16 /XJ /NFL /NDL

echo Iniciando proceso de restauración...
echo.

if exist "%ORIGEN%\Desktop" (
    echo Restaurando Desktop...
    robocopy "%ORIGEN%\Desktop" "%DESTINO%\Desktop" %PARAMSROBOCOPY%
)

if exist "%ORIGEN%\Documents" (
    echo Restaurando Documents...
    robocopy "%ORIGEN%\Documents" "%DESTINO%\Documents" %PARAMSROBOCOPY%
)

if exist "%ORIGEN%\Downloads" (
    echo Restaurando Downloads...
    robocopy "%ORIGEN%\Downloads" "%DESTINO%\Downloads" %PARAMSROBOCOPY%
)

if exist "%ORIGEN%\Pictures" (
    echo Restaurando Pictures...
    robocopy "%ORIGEN%\Pictures" "%DESTINO%\Pictures" %PARAMSROBOCOPY%
)

if exist "%ORIGEN%\Favorites" (
    echo Restaurando Favorites...
    robocopy "%ORIGEN%\Favorites" "%DESTINO%\Favorites" %PARAMSROBOCOPY%
)

echo.
echo ========================================================
echo Restauración de %USERNAME% finalizada con éxito.
echo ========================================================
pause
