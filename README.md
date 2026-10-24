# Copia y restauración de perfil de usuario

Este proyecto contiene dos scripts de Windows para preparar una migración manual de las carpetas principales del perfil de usuario:

- `Copia.bat`: genera un respaldo en una unidad elegida y recopila información del equipo.
- `Restaura.bat`: copia las carpetas del respaldo al perfil del usuario que ejecuta el script.

## Requisitos

- Windows con `robocopy` y Windows PowerShell disponibles.
- Acceso a una unidad con espacio suficiente para guardar el respaldo.
- Para restaurar, la unidad que contiene el respaldo debe estar conectada y accesible.

Ejecuta los archivos `.bat` desde el Explorador o desde una consola de Windows. Revisa la unidad y las rutas mostradas antes de confirmar cada operación.

## Crear el respaldo

1. Ejecuta `Copia.bat`.
2. Indica la letra de la unidad de destino (por ejemplo, `D:` o `E:`). Si no escribes una, se usa `D:`.
3. Revisa el resumen y confirma con **S** para continuar; con **N** se cancela.

El destino se construye así:

```text
<unidad>:\Backup_Migracion\<nombre-de-usuario>\
```

El script usa el nombre de usuario de Windows (`%USERNAME%`) y prepara las carpetas `Desktop`, `Documents`, `Downloads`, `Pictures` y `Favorites`. También genera informes sobre configuración IP, unidades de almacenamiento y de red, adaptadores, ubicaciones de red, certificados del usuario e impresoras.

### Importante: la copia de archivos actualmente es una simulación

En `Copia.bat`, Robocopy se ejecuta con la opción `/L`, que solo muestra qué archivos copiaría: **no copia los archivos**. Aunque el script cree las carpetas de destino, genere los informes y termine mostrando un mensaje de finalización, no se habrá creado un respaldo de los archivos personales. Antes de usarlo para una migración real, hay que quitar `/L` de `PARAMSROBOCOPY` y probar el resultado con cuidado.

## Restaurar el respaldo

1. Conecta la unidad donde está el respaldo y ejecuta `Restaura.bat` en el nuevo equipo.
2. Indica la letra de la unidad de origen. Si no escribes una, se usa `D:`.
3. El script busca el respaldo en:

   ```text
   <unidad>:\Backup_Migracion\<nombre-de-usuario-actual>\
   ```

4. Revisa el resumen y confirma con **S** para iniciar; con **N** se cancela.

Se restauran `Desktop`, `Documents`, `Downloads`, `Pictures` y `Favorites` dentro de `%USERPROFILE%`, si esas carpetas existen en el respaldo. La restauración incluye subdirectorios, también los vacíos; no elimina archivos que ya existan en el perfil pero no estén en el respaldo. Los archivos coincidentes pueden actualizarse según el comportamiento predeterminado de Robocopy.

El nombre de usuario usado para localizar el respaldo es el del equipo actual. Si el usuario nuevo tiene un nombre distinto al anterior, el script no encontrará automáticamente la carpeta del usuario anterior: renombra la carpeta del respaldo o adapta la ruta antes de ejecutarlo.

`Restaura.bat` no comprueba los códigos de salida de Robocopy y muestra un mensaje de finalización incluso si una operación falla. Verifica que los archivos esperados estén en el perfil después de restaurar.

## Informes y privacidad

Los informes se guardan en la raíz del respaldo, por ejemplo `Configuracion_IP.txt`, `unidades_red.txt`, `dispositivos_red.txt`, `ubicaciones_red.txt`, `certificados.txt` e `impresoras.txt`. Pueden contener direcciones IP, nombres de equipos y servidores, rutas de red, identificadores de certificados e información de impresoras. `ubicaciones_red.txt` indica si se detecta una credencial guardada para ciertos servidores, pero no exporta las contraseñas.

Guarda el respaldo en un lugar seguro y comparte sus informes solo con personas de confianza. Estos scripts recopilan información del equipo, pero no transfieren por sí mismos el respaldo a través de la red.