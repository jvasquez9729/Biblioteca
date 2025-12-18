# 📋 INSTRUCCIONES DE INSTALACIÓN Y USO

## Sistema Integral de Controller Financiero

---

## ⚠️ IMPORTANTE: El archivo correcto a usar es el .xlsx

El archivo **ControllerFinanciero_v1.0.xlsx** tiene todas las fórmulas funcionando correctamente.
Para agregar las macros VBA, sigue estos pasos:

---

## 🔧 PASO A PASO - INSTALACIÓN COMPLETA

### 1️⃣ Descargar Archivos

Descarga estos 3 archivos del repositorio:

1. ✅ **ControllerFinanciero_v1.0.xlsx** (archivo principal)
2. ✅ **vba_modules/Module1_GenerarDiagnostico.vba**
3. ✅ **vba_modules/Module2_OtrasMacros.vba**

**Link directo:**
https://github.com/jvasquez9729/Biblioteca/tree/claude/financial-controller-excel-5gKoq/ControllerFinanciero

---

### 2️⃣ Abrir el Archivo Excel

1. Abre **ControllerFinanciero_v1.0.xlsx** en Microsoft Excel
2. El archivo se abrirá normalmente (puede que aparezca una advertencia de seguridad, haz clic en "Habilitar edición")

✅ **Verifica que las fórmulas funcionan:**
   - Ve a la hoja **EERR**
   - Deberías ver datos de ejemplo
   - Los totales deben estar calculados automáticamente

---

### 3️⃣ Guardar como .xlsm (Habilitado para Macros)

**IMPORTANTE:** Antes de agregar macros, debes guardar el archivo con el formato correcto.

1. En Excel, ve a: **Archivo → Guardar como**
2. En "Tipo de archivo" selecciona: **Libro de Excel habilitado para macros (*.xlsm)**
3. Cambia el nombre a: **ControllerFinanciero_v1.0.xlsm**
4. Haz clic en **Guardar**
5. Cierra el archivo .xlsx original
6. Abre el nuevo archivo **.xlsm** que acabas de guardar

---

### 4️⃣ Importar las Macros VBA

Ahora que tienes el archivo .xlsm, puedes agregar las macros:

1. **Abre el Editor VBA:**
   - Presiona **Alt + F11** (Windows)
   - O ve a: **Desarrollador → Visual Basic**

   📌 *Si no ves la pestaña "Desarrollador":*
   - Archivo → Opciones → Personalizar cinta de opciones
   - Marca la casilla "Desarrollador"

2. **Importar Módulo 1:**
   - En el Editor VBA, ve a: **File → Import File**
   - Busca y selecciona: **Module1_GenerarDiagnostico.vba**
   - Haz clic en **Abrir**

3. **Importar Módulo 2:**
   - En el Editor VBA, ve a: **File → Import File**
   - Busca y selecciona: **Module2_OtrasMacros.vba**
   - Haz clic en **Abrir**

4. **Verificar que se importaron:**
   - En el panel izquierdo del Editor VBA, expande "VBAProject (ControllerFinanciero_v1.0.xlsm)"
   - Expande "Módulos"
   - Deberías ver: **Module1** y **Module2**

5. **Guardar:**
   - Presiona **Ctrl + S** para guardar
   - Cierra el Editor VBA

---

### 5️⃣ Crear Botones para las Macros (Opcional pero Recomendado)

Para facilitar el uso, crea botones:

#### Botón "Generar Diagnóstico":

1. Ve a la hoja **DIAGNÓSTICO**
2. Ve a: **Desarrollador → Insertar → Botón (Control de formulario)**
3. Dibuja un botón donde quieras
4. En la ventana "Asignar macro", selecciona: **GenerarDiagnostico**
5. Haz clic derecho en el botón → **Modificar texto**
6. Escribe: **"Generar Diagnóstico"**

#### Otros botones útiles:

Crea botones similares para:
- **ActualizarGraficos** (en hoja INFORME VISUAL)
- **ExportarPDF** (en hoja DIAGNÓSTICO)
- **LimpiarDatos** (en hoja CONFIGURACIÓN)
- **CalcularEscenarios** (en hoja PROYECCIONES)

---

### 6️⃣ Configurar Seguridad de Macros

Para que las macros funcionen:

1. Ve a: **Archivo → Opciones → Centro de confianza**
2. Haz clic en: **Configuración del Centro de confianza**
3. Ve a: **Configuración de macros**
4. Selecciona: **"Habilitar todas las macros"** (solo para este archivo)

   ⚠️ **O mejor:** Selecciona "Deshabilitar todas las macros con notificación"
   Y cada vez que abras el archivo, haz clic en "Habilitar contenido"

---

## ✅ VERIFICACIÓN - ¿Todo Funciona?

### Prueba las Fórmulas:

1. Ve a la hoja **CONFIGURACIÓN**
2. Completa el nombre de la empresa
3. Ve a la hoja **EERR**
4. Ingresa valores en las celdas azules (inputs)
5. Verifica que los totales se calculan automáticamente

### Prueba las Macros:

1. Ve a la hoja **DIAGNÓSTICO**
2. Haz clic en el botón **"Generar Diagnóstico"** (o presiona Alt+F8 → GenerarDiagnostico → Ejecutar)
3. Debería aparecer un mensaje: "Diagnóstico financiero generado exitosamente"
4. La hoja DIAGNÓSTICO debe llenarse con texto automático

---

## 🎯 MACROS DISPONIBLES

### 1. **GenerarDiagnostico**
- Genera el diagnóstico financiero completo
- Analiza los indicadores y crea interpretaciones humanizadas
- Ejecutar desde: Hoja DIAGNÓSTICO

### 2. **ActualizarGraficos**
- Actualiza todos los gráficos con los datos más recientes
- Ejecutar desde: Hoja INFORME VISUAL

### 3. **ExportarPDF**
- Exporta el diagnóstico e informe visual a PDF
- Guarda en la misma carpeta del archivo Excel
- Ejecutar desde: Hoja DIAGNÓSTICO

### 4. **LimpiarDatos**
- Limpia todas las celdas de entrada (azules)
- Útil para comenzar un nuevo análisis
- ⚠️ Pregunta confirmación antes de ejecutar

### 5. **CalcularEscenarios**
- Recalcula las proyecciones en 3 escenarios
- Base, Optimista (+15%), Pesimista (-15%)
- Ejecutar desde: Hoja PROYECCIONES

### 6. **ProtegerHojas / DesprotegerHojas**
- Protege o desprotege las hojas
- Contraseña: `controller2024`
- Solo permite editar celdas de entrada (azules)

---

## 🆘 SOLUCIÓN DE PROBLEMAS

### ❌ "Excel no puede abrir el archivo porque el formato no es válido"
**Solución:** Estás intentando abrir un .xlsm creado incorrectamente.
- Usa el archivo **.xlsx** original
- Guárdalo como .xlsm desde Excel (Paso 3)

### ❌ "Las macros no aparecen"
**Solución:** No se importaron los módulos VBA correctamente.
- Abre el Editor VBA (Alt+F11)
- Verifica que existan Module1 y Module2
- Si no están, importa los archivos .vba (Paso 4)

### ❌ "Error de compilación al ejecutar macro"
**Solución:** Las referencias del código VBA no coinciden.
- Verifica que las hojas tengan los nombres correctos
- Nombres requeridos: CONFIGURACIÓN, EERR, ESF, INDICADORES, DIAGNÓSTICO, etc.

### ❌ "El diagnóstico no se genera"
**Solución:** Faltan datos de entrada.
- Completa al menos las hojas CONFIGURACIÓN, EERR y ESF
- Verifica que el balance cuadre (ESF, verificación debe ser 0)

### ❌ "Fórmulas muestran #DIV/0! o #VALUE!"
**Solución:** Esto NO debería pasar porque todas las fórmulas usan IFERROR.
- Si ocurre, ejecuta el script Python: `python3 crear_xlsm_completo.py`
- O descarga nuevamente el archivo .xlsx

---

## 📞 CONTACTO Y SOPORTE

Si tienes problemas:

1. Revisa esta guía paso a paso
2. Verifica que descargaste todos los archivos necesarios
3. Asegúrate de estar usando Microsoft Excel (no Google Sheets o LibreOffice)
4. Consulta el README.md para documentación completa

---

## 📌 RESUMEN RÁPIDO

```
1. Descarga ControllerFinanciero_v1.0.xlsx
2. Abre en Excel
3. Guardar como → .xlsm
4. Alt+F11 → Importar archivos .vba
5. Crear botones (opcional)
6. ¡Listo para usar!
```

---

**✨ Sistema Integral de Controller Financiero v1.0**

*Análisis financiero profesional para PYMEs colombianas*

🇨🇴 Hecho en Colombia | 📊 Metodología Trulab
