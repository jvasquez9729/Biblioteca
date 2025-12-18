# 📊 Sistema Integral de Controller Financiero

Sistema completo de análisis financiero desarrollado en Excel con VBA para PYMEs colombianas, siguiendo la metodología de consultoría financiera Trulab.

## 🎯 Características Principales

✅ **10 hojas especializadas** con análisis financiero completo
✅ **+30 indicadores financieros** calculados automáticamente
✅ **Diagnóstico automático humanizado** con interpretaciones contextuales
✅ **Análisis de punto de equilibrio** con sensibilidad
✅ **Proyecciones financieras** a 5-7 años (3 escenarios)
✅ **Valoración empresarial** (WACC, DCF, múltiplos)
✅ **Benchmarks de industria** (datos Damodaran)
✅ **Macros VBA** para automatización
✅ **Datos de ejemplo** pre-cargados

## 📁 Estructura del Proyecto

```
ControllerFinanciero/
├── ControllerFinanciero_v1.0.xlsx     # Archivo Excel principal
├── crear_controller_financiero.py     # Script generador base
├── agregar_formulas_y_datos.py        # Script de fórmulas y datos
├── README.md                          # Este archivo
├── vba_modules/                       # Módulos VBA
│   ├── Module1_GenerarDiagnostico.vba
│   └── Module2_OtrasMacros.vba
├── docs/                              # Documentación adicional
└── examples/                          # Ejemplos de uso
```

## 📋 Hojas del Sistema

### 1. **INSTRUCCIONES**
Guía paso a paso para usar el sistema completo.

### 2. **CONFIGURACIÓN**
- Datos de la empresa
- Sector económico
- Parámetros de análisis
- Validaciones de entrada

### 3. **EERR** (Estado de Resultados)
- Estado de resultados completo
- Análisis vertical (% de ventas)
- Análisis horizontal (variación año a año)
- Hasta 3 años comparativos

### 4. **ESF** (Estado de Situación Financiera)
- Balance general completo
- Activos, Pasivos y Patrimonio
- Verificación automática de cuadre
- Análisis vertical y horizontal

### 5. **INDICADORES**
Más de 30 indicadores organizados en 5 categorías:

**A. Liquidez (8 indicadores)**
- Razón corriente
- Prueba ácida
- Capital de trabajo
- KTNO
- PKT y PKTNO
- Solvencia

**B. Rentabilidad (7 indicadores)**
- Márgenes (bruto, EBITDA, operativo, neto)
- ROA
- ROE
- Tasa efectiva de tributación

**C. Endeudamiento (5 indicadores)**
- Nivel de endeudamiento
- Concentración deuda CP
- Deuda financiera / Activos
- Deuda / Patrimonio
- Cobertura de intereses

**D. Actividad/Rotación (9 indicadores)**
- Rotación de inventarios, cartera, proveedores
- Días de inventario, cartera, proveedores
- Ciclo operativo
- Ciclo de conversión de efectivo
- GAP financiero

**E. Inversión (4 indicadores)**
- Depreciación / PPE
- CAPEX / Activos fijos
- Variación % en ventas
- Variación % en EBITDA

### 6. **PUNTO EQUILIBRIO**
- Cálculo de punto de equilibrio (unidades y valor)
- Margen de contribución
- Margen de seguridad
- Análisis de sensibilidad (precio y costos)
- Gráfico de punto de equilibrio

### 7. **PROYECCIONES**
- Proyección de Estado de Resultados (5-7 años)
- Proyección de Balance General
- Flujo de caja libre proyectado
- 3 escenarios: Base, Optimista (+15%), Pesimista (-15%)

### 8. **VALORACIÓN**
- Cálculo de WACC
- Costo de patrimonio (CAPM)
- Flujo de caja descontado (DCF)
- Valor terminal
- Múltiplos comparables

### 9. **BENCHMARKS**
- Métricas de industria por sector (Damodaran)
- Comparación empresa vs industria
- Identificación de brechas
- Semáforos de posicionamiento

### 10. **DIAGNÓSTICO**
Diagnóstico automático con interpretaciones humanizadas:
- Resumen ejecutivo
- Análisis de liquidez
- Análisis de rentabilidad
- Análisis de endeudamiento
- Ciclo de efectivo
- Hallazgos y alertas
- Recomendaciones de acción
- Conclusiones

### 11. **INFORME VISUAL**
Dashboard con 8 gráficos ejecutivos:
- Evolución de ventas y utilidades
- Comparación de márgenes
- Composición de activos
- Composición de pasivos
- Punto de equilibrio
- Radar vs industria
- Ciclo de efectivo
- Liquidez y endeudamiento

## 🔧 Instalación y Uso

### Requisitos
- Excel 2016 o superior (o LibreOffice Calc)
- Python 3.7+ (solo para regenerar el archivo)
- Biblioteca openpyxl (si usa Python)

### Instalación

```bash
# Clonar o descargar el proyecto
cd ControllerFinanciero

# Instalar dependencias Python (opcional)
pip install openpyxl

# Generar el archivo Excel (opcional - ya está incluido)
python3 crear_controller_financiero.py
python3 agregar_formulas_y_datos.py
```

### Uso Rápido

1. **Abrir el archivo**: `ControllerFinanciero_v1.0.xlsx`

2. **Habilitar macros** al abrir el archivo

3. **Ir a CONFIGURACIÓN** y completar:
   - Nombre de la empresa
   - Sector económico
   - Datos generales

4. **Ir a EERR** e ingresar:
   - Estado de Resultados (mínimo 2 años)

5. **Ir a ESF** e ingresar:
   - Balance General
   - Verificar que cuadre (diferencia = 0)

6. **Revisar INDICADORES**:
   - Se calculan automáticamente
   - Revisar semáforos

7. **Generar DIAGNÓSTICO**:
   - Ir a hoja DIAGNÓSTICO
   - Presionar botón "Generar Diagnóstico"
   - Revisar interpretaciones

8. **Exportar a PDF**:
   - Presionar botón "Exportar PDF"
   - Se genera archivo con diagnóstico

## 🎨 Códigos de Color

| Color | Significado | Uso |
|-------|-------------|-----|
| 🔵 AZUL | Celdas de entrada | Debe completar estos datos |
| ⚫ NEGRO | Fórmulas calculadas | No modificar |
| 🟢 VERDE | Referencias entre hojas | Cálculo automático |
| 🟡 AMARILLO | Supuestos clave | Requiere atención especial |
| 🔴 ROJO | Alertas | Indicadores críticos |
| 🟢 VERDE CLARO | Óptimo | Indicadores saludables |
| 🟡 AMARILLO CLARO | Precaución | Requiere monitoreo |

## 🤖 Macros VBA Disponibles

### 1. GenerarDiagnostico
Genera el diagnóstico financiero completo con interpretaciones humanizadas basadas en los valores calculados.

```vba
Sub GenerarDiagnostico()
```

### 2. ActualizarGraficos
Actualiza todos los gráficos del dashboard con los datos más recientes.

```vba
Sub ActualizarGraficos()
```

### 3. ExportarPDF
Exporta las hojas de diagnóstico e informe visual a PDF.

```vba
Sub ExportarPDF()
```

### 4. LimpiarDatos
Limpia todas las celdas de entrada para comenzar un nuevo análisis.

```vba
Sub LimpiarDatos()
```

### 5. CalcularEscenarios
Recalcula las proyecciones para los tres escenarios (base, optimista, pesimista).

```vba
Sub CalcularEscenarios()
```

### 6. ProtegerHojas / DesprotegerHojas
Protege o desprotege las hojas (contraseña: `controller2024`).

```vba
Sub ProtegerHojas()
Sub DesprotegerHojas()
```

## 📊 Ejemplo de Interpretación Humanizada

**Razón Corriente = 2.78**

> "En 2022 la razón corriente fue de 2.78. Esto quiere decir que por cada peso que debía la organización tuvo $2.78 de activos corrientes para responder por esas obligaciones. Como este indicador fue mayor a 1 se puede decir que la organización está en la capacidad de responder por sus deudas a corto plazo.
>
> En 2023 la razón corriente disminuyó a 2.59, representando una caída de 0.19 puntos (-6.8%). Aunque sigue siendo saludable, la tendencia descendente sugiere monitorear el capital de trabajo.
>
> En 2024 el indicador se recuperó a 3.05, mostrando una mejora de 0.46 puntos (+17.9%). Esta recuperación indica una gestión más eficiente del capital de trabajo."

## 🔍 Benchmarks de Industria

El sistema incluye benchmarks de Damodaran para:

- 📦 Manufactura / Food Processing
- 💼 Servicios
- 🛒 Comercio / Retail
- 💻 Tecnología / Software
- 🌾 Agroindustria
- 🏥 Salud / Healthcare
- 🏗️ Construcción / Building Materials

**Fuente**: [Aswath Damodaran - NYU Stern](https://pages.stern.nyu.edu/~adamodar/)

## 📝 Formato de Números

| Tipo | Formato | Ejemplo |
|------|---------|---------|
| Moneda | `#,##0` | 1,234,567 |
| Porcentaje | `0.0%` | 15.3% |
| Ratios | `0.00x` | 2.45x |
| Negativos | `(#,##0)` | (1,234) |
| Ceros | `-` | - |

## 🚀 Características Avanzadas

### Análisis Vertical
Calcula automáticamente la participación porcentual de cada partida respecto a las ventas (EERR) o activos totales (ESF).

### Análisis Horizontal
Calcula la variación absoluta y porcentual entre períodos consecutivos.

### Validación de Cuadre
Verifica automáticamente que el balance cuadre:
```
Activo Total = Pasivo Total + Patrimonio
```

### Escenarios de Proyección
- **Base**: Supuestos normales
- **Optimista**: +15% sobre base
- **Pesimista**: -15% sobre base

### Valoración por DCF
Calcula el valor presente de los flujos de caja futuros usando:
- WACC como tasa de descuento
- Valor terminal con crecimiento perpetuo
- Múltiplos comparables del sector

## ⚠️ Consideraciones Importantes

1. **Datos de Entrada**: Asegúrese de ingresar datos verificados y reales
2. **Balance Cuadrado**: El balance debe cuadrar antes de continuar
3. **Macros**: Active las macros al abrir el archivo
4. **Respaldo**: Guarde versiones del archivo regularmente
5. **Validación Profesional**: El diagnóstico automático es una guía, consulte con un contador
6. **Protección**: No modifique las fórmulas (celdas en negro)

## 🛠️ Personalización

### Agregar Nuevos Indicadores

1. Ir a hoja **INDICADORES**
2. Agregar nueva fila con:
   - Nombre del indicador
   - Fórmula
   - Referencias a hojas fuente
3. Agregar interpretación en macro `GenerarDiagnostico`

### Modificar Benchmarks

1. Ir a hoja **BENCHMARKS**
2. Actualizar valores según sector
3. Fuente recomendada: [Damodaran Data](https://pages.stern.nyu.edu/~adamodar/)

### Agregar Nuevos Gráficos

1. Crear gráfico en hoja **INFORME VISUAL**
2. Vincular a datos de otras hojas
3. Actualizar macro `ActualizarGraficos`

## 📚 Recursos Adicionales

### Documentación
- `docs/GuiaDeUso.pdf` - Guía detallada con imágenes
- `docs/MetodologiaTrulab.pdf` - Metodología de análisis

### Ejemplos
- `examples/Ejemplo_Manufactura.xlsx`
- `examples/Ejemplo_Servicios.xlsx`
- `examples/Ejemplo_Comercio.xlsx`

### Referencias
- [Aswath Damodaran - NYU Stern](https://pages.stern.nyu.edu/~adamodar/)
- [Supersociedades Colombia](https://www.supersociedades.gov.co/)
- [DANE - Clasificación CIIU](https://www.dane.gov.co/)

## 🤝 Contribuciones

Este sistema fue desarrollado siguiendo la metodología Trulab para análisis financiero de PYMEs colombianas.

### Mejoras Futuras
- [ ] Integración con APIs contables
- [ ] Dashboard interactivo web
- [ ] Alertas automáticas por email
- [ ] Análisis de sensibilidad avanzado
- [ ] Machine Learning para predicciones
- [ ] Comparación con múltiples empresas
- [ ] Generación automática de presentaciones

## 📄 Licencia

Este proyecto fue desarrollado con fines educativos y de consultoría financiera.

## 👥 Créditos

- **Metodología**: Trulab - Aceleración Empresarial
- **Benchmarks**: Aswath Damodaran (NYU Stern School of Business)
- **Desarrollo**: Sistema Integral de Controller Financiero
- **Versión**: 1.0
- **Fecha**: Diciembre 2024

## 📞 Soporte

Para soporte técnico o consultoría financiera:
- Revise la hoja **INSTRUCCIONES** en el archivo Excel
- Consulte la documentación en `docs/`
- Contacte a su asesor financiero

---

**⚡ Sistema Integral de Controller Financiero v1.0**

*Análisis financiero profesional para PYMEs colombianas*

🇨🇴 Hecho en Colombia | 📊 Metodología Trulab | 💼 Para PYMEs
