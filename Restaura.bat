@echo off
:: Script de restauración de datos para nuevo equipo

echo ========================================================
echo SELECCION DE UNIDAD DE ORIGEN (DONDE ESTA EL BACKUP)
echo ========================================================
set UNIDAD=D:
set /p UNIDAD="Ingrese la letra de unidad donde esta la copia (Ej: D: o E:) [Por defecto D:]: "

:: Asegurar que la letra lleve los dos puntos
if "%UNIDAD:~-1%" NEQ ":" set UNIDAD=%UNIDAD%:

set ORIGEN=%UNIDAD%\Backup_Migracion\%USERNAME%
set DESTINO=%USERPROFILE%

echo.
echo ========================================================
echo RESUMEN DE LA OPERACION DE RESTAURACION
echo ========================================================
echo Usuario actual      : %USERNAME%
echo Directorio Origen   : %ORIGEN%
echo Destino (Profile)   : %DESTINO%
echo.
echo Carpetas a restaurar: Desktop, Documents, Downloads,
echo                       Pictures, Favorites
echo ========================================================
echo.


:: Verificar existencia del directorio de origen
if not exist "%ORIGEN%" (
    echo.
    echo ========================================================
    echo ERROR: No se encuentra la carpeta de respaldo en:
    echo "%ORIGEN%"
    echo Verifique la letra de unidad e inténtelo de nuevo.
    echo ========================================================
    pause
    exit /b
)

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
echo Iniciando proceso de restauración...
echo ========================================================

set PARAMSROBOCOPY=/E /R:1 /W:1 /MT:16 /XJ /NFL /NDL

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
echo Restauración finalizada con éxito.
echo ========================================================
pause