# Copia y restauración de perfil de usuario

Este proyecto contiene scripts de Windows para preparar una migración manual de las carpetas principales del perfil de usuario:

- `Copia.bat`: versión inicial que simula la copia de todas las carpetas e informa sobre el equipo.
- `copia2.bat`: permite elegir qué carpetas respaldar y si se quiere simular o realizar la copia; también recopila información del equipo.
- `Restaura.bat` y `Restaura2.bat`: restauran las carpetas disponibles del respaldo al perfil del usuario que ejecuta el script.

## Requisitos

- Windows con `robocopy` y Windows PowerShell disponibles.
- Acceso a una unidad con espacio suficiente para guardar el respaldo.
- Para restaurar, la unidad que contiene el respaldo debe estar conectada y accesible.

Ejecuta los archivos `.bat` desde el Explorador o desde una consola de Windows. Revisa la unidad y las rutas mostradas antes de confirmar cada operación.

## Crear el respaldo con `copia2.bat`

1. Ejecuta `copia2.bat`.
2. Revisa el tamaño calculado de cada carpeta y responde **S** o **N** para seleccionar `Desktop`, `Documents`, `Downloads`, `Pictures` y `Favorites`. Si no seleccionas ninguna, el proceso se cancela.
3. Indica la letra de la unidad de destino (por ejemplo, `D:` o `E:`). Si no escribes una, se usa `D:`.
4. Elige el modo de Robocopy: **S** para simulación o **R** para copia real. La simulación es la opción predeterminada y se selecciona automáticamente tras 10 segundos.
5. Revisa el resumen y confirma con **S** para continuar; con **N** se cancela.

El destino se construye así:

```text
<unidad>:\Backup_Migracion\<nombre-de-usuario>\
```

El script usa el nombre de usuario de Windows (`%USERNAME%`) y crea en el destino las carpetas seleccionadas. También genera informes sobre configuración IP, unidades de almacenamiento y de red, adaptadores, ubicaciones de red, certificados del usuario e impresoras.

### Simulación y copia real

En `copia2.bat`, la simulación ejecuta Robocopy con `/L`: solo muestra qué archivos copiaría y **no copia los archivos**. Para crear el respaldo, elige **R (Copia Real)** y confirma la operación. `Copia.bat` es la versión inicial y siempre ejecuta Robocopy en modo de simulación; no crea una copia real de los archivos personales.

## Restaurar el respaldo con `Restaura2.bat`

1. Conecta la unidad donde está el respaldo y ejecuta `Restaura2.bat` en el nuevo equipo. También puedes usar `Restaura.bat`; ambos scripts restauran las mismas carpetas.
2. Indica la letra de la unidad de origen. Si no escribes una, se usa `D:`.
3. El script busca el respaldo en:

   ```text
   <unidad>:\Backup_Migracion\<nombre-de-usuario-actual>\
   ```

4. Revisa el resumen y confirma con **S** para iniciar; con **N** se cancela.

Se restauran `Desktop`, `Documents`, `Downloads`, `Pictures` y `Favorites` dentro de `%USERPROFILE%`, si esas carpetas existen en el respaldo. La restauración incluye subdirectorios, también los vacíos; no elimina archivos que ya existan en el perfil pero no estén en el respaldo. Los archivos coincidentes pueden actualizarse según el comportamiento predeterminado de Robocopy.

El nombre de usuario usado para localizar el respaldo es el del equipo actual. Si el usuario nuevo tiene un nombre distinto al anterior, el script no encontrará automáticamente la carpeta del usuario anterior: renombra la carpeta del respaldo o adapta la ruta antes de ejecutarlo.

Los dos scripts de restauración no comprueban los códigos de salida de Robocopy y muestran un mensaje de finalización incluso si una operación falla. Verifica que los archivos esperados estén en el perfil después de restaurar.

## Informes y privacidad

Los informes se guardan en la raíz del respaldo, por ejemplo `Configuracion_IP.txt`, `unidades_red.txt`, `unidades_almacenamiento.txt`, `dispositivos_red.txt`, `ubicaciones_red.txt`, `certificados.txt` e `impresoras.txt`. Pueden contener direcciones IP, nombres de equipos y servidores, rutas de red, identificadores de certificados e información de impresoras. `ubicaciones_red.txt` registra las ubicaciones de red guardadas, pero no exporta contraseñas.

Guarda el respaldo en un lugar seguro y comparte sus informes solo con personas de confianza. Estos scripts recopilan información del equipo, pero no transfieren por sí mismos el respaldo a través de la red.

## Migración de certificados

### 1. Certificado digital personal (FNMT)

El certificado personal identificado en este equipo tiene estos datos:

- **Subject:** `CN=xxxxx - DNI...`
- **Issuer:** `CN=AC FNMT Usuarios, OU=Ceres, O=FNMT-RCM, C=ES`
- **Caducidad:** 26/12/2028
- **Diagnóstico:** certificado personal de la **FNMT** con clave privada (`HasPrivateKey = True`).

Para migrarlo al equipo nuevo:

1. Abre la consola de certificados con `Win + R` y ejecuta `certmgr.msc`.
2. Ve a **Personal** -> **Certificados**.
3. Haz clic derecho sobre el certificado de la **FNMT** y selecciona **Todas las tareas** -> **Exportar...**.
4. En el asistente, selecciona **Sí, exportar la clave privada**.

   Si la opción de exportar la clave privada aparece deshabilitada, el certificado no se instaló como exportable y no se podrá extraer de ese equipo. En ese caso, solicita un duplicado o un nuevo certificado en la web de la FNMT, o impórtalo desde el archivo `.pfx` original.

5. Asigna una contraseña al archivo `.pfx` y guárdalo en la unidad de respaldo, por ejemplo `E:\Backup_Migracion\Certificado`.
6. En el equipo nuevo, haz doble clic en el archivo `.pfx` para instalarlo en **Usuario actual**.

El archivo `.pfx` contiene la clave privada: protégelo con una contraseña segura, limita el acceso y no lo compartas junto con esa contraseña.

### 2. Certificados autogenerados y del sistema

Los certificados con nombres como `CN=trust_...`, `CN=15cc...` y `CN=usu` corresponden, en este equipo, a certificados autofirmados (*self-signed*) generados por aplicaciones o herramientas de desarrollo, como OneDrive, IIS Express, Docker, Visual Studio Code o procesos de sincronización.

En general, no es necesario exportarlos ni migrarlos: las aplicaciones que los necesitan suelen generarlos de nuevo al iniciar sesión o configurar el equipo nuevo.

### 3. Certificados intermedios y entidades de raíz de confianza (CAs personalizadas)

Estos certificados pueden pertenecer a entidades emisoras corporativas o de redes internas, por ejemplo, entornos universitarios, VPN corporativas o proxies de seguridad como Fortinet o Zscaler.

- **Ubicación en el almacén del usuario actual:**
  - `Cert:\CurrentUser\Root`: entidades de certificación raíz de confianza.
  - `Cert:\CurrentUser\CA`: entidades de certificación intermedias.
- **Características:** normalmente no contienen clave privada (`HasPrivateKey = False`); contienen la clave pública usada para validar conexiones o firmas.

Para exportar un certificado público en formato `.cer` o `.crt`:

1. Ejecuta `certmgr.msc`.
2. Abre **Entidades de certificación raíz de confianza** -> **Certificados** para una raíz, o **Entidades de certificación intermedias** -> **Certificados** para una entidad intermedia.
3. Haz clic derecho en el certificado y selecciona **Todas las tareas** -> **Exportar...**.
4. Selecciona **X.509 codificado en DER (.cer)** o **Base-64 (.cer)**. Estos formatos no incluyen una clave privada y no requieren contraseña.

Antes de instalar un certificado raíz o intermedio en otro equipo, confirma que procede de una fuente de confianza y que realmente se necesita: instalar una CA cambia qué certificados y conexiones considera confiables Windows.

#### Importar mediante el asistente de Windows (interfaz gráfica)

1. Haz doble clic en el archivo del certificado (`.cer`, `.crt` o `.pem`).
2. En la ventana que se abre, haz clic en **Instalar certificado...**.
3. Selecciona la ubicación del almacén:
   - **Usuario actual:** afecta solo a tu cuenta.
   - **Equipo local:** afecta a todos los usuarios y requiere permisos de administrador. Úsalo solo si es necesario.
4. Selecciona **Colocar todos los certificados en el siguiente almacén** y haz clic en **Examinar...**:
   - Para certificados raíz, elige **Entidades de certificación raíz de confianza**.
   - Para certificados intermedios, elige **Entidades de certificación intermedias**.
5. Haz clic en **Siguiente** y luego en **Finalizar**.
6. Si importas una raíz de confianza, Windows puede mostrar un aviso de seguridad. Continúa solo si has verificado que el certificado y su entidad emisora son de confianza.