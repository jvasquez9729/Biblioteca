Attribute VB_Name = "Module1_GenerarDiagnostico"
Option Explicit

'====================================================================================
' MÓDULO 1: GENERAR DIAGNÓSTICO AUTOMÁTICO
' Sistema Integral de Controller Financiero
' Este módulo genera el diagnóstico financiero con interpretaciones humanizadas
'====================================================================================

Sub GenerarDiagnostico()
    '
    ' GenerarDiagnostico Macro
    ' Genera el diagnóstico financiero completo con interpretaciones contextuales
    '

    Dim wsDiag As Worksheet
    Dim wsConfig As Worksheet
    Dim wsInd As Worksheet
    Dim wsEERR As Worksheet
    Dim wsESF As Worksheet

    Dim nombreEmpresa As String
    Dim sectorEmpresa As String
    Dim añoBase As String
    Dim fechaHoy As String

    ' Desactivar actualización de pantalla para mayor velocidad
    Application.ScreenUpdating = False
    Application.Calculation = xlCalculationManual

    On Error GoTo ErrorHandler

    ' Referenciar hojas
    Set wsDiag = ThisWorkbook.Sheets("DIAGNÓSTICO")
    Set wsConfig = ThisWorkbook.Sheets("CONFIGURACIÓN")
    Set wsInd = ThisWorkbook.Sheets("INDICADORES")
    Set wsEERR = ThisWorkbook.Sheets("EERR")
    Set wsESF = ThisWorkbook.Sheets("ESF")

    ' Obtener datos de configuración
    nombreEmpresa = wsConfig.Range("B5").Value
    If nombreEmpresa = "" Then nombreEmpresa = "LA EMPRESA"

    sectorEmpresa = wsConfig.Range("B7").Value
    If sectorEmpresa = "" Then sectorEmpresa = "NO ESPECIFICADO"

    añoBase = wsConfig.Range("B11").Value
    If añoBase = "" Then añoBase = Year(Date)

    fechaHoy = Format(Date, "dd/mm/yyyy")

    ' Limpiar diagnóstico anterior
    wsDiag.Range("A2:H200").ClearContents

    ' Generar encabezado
    Dim fila As Integer
    fila = 2

    wsDiag.Cells(fila, 1).Value = ""
    fila = fila + 1

    wsDiag.Cells(fila, 1).Value = "=== DIAGNÓSTICO FINANCIERO DE " & UCase(nombreEmpresa) & " ==="
    wsDiag.Cells(fila, 1).Font.Bold = True
    wsDiag.Cells(fila, 1).Font.Size = 14
    fila = fila + 1

    wsDiag.Cells(fila, 1).Value = "Sector: " & sectorEmpresa
    fila = fila + 1

    wsDiag.Cells(fila, 1).Value = "Período analizado: 2022 - " & añoBase
    fila = fila + 1

    wsDiag.Cells(fila, 1).Value = "Fecha de elaboración: " & fechaHoy
    fila = fila + 1

    wsDiag.Cells(fila, 1).Value = ""
    fila = fila + 1

    wsDiag.Cells(fila, 1).Value = "═══════════════════════════════════════════════════════════════"
    fila = fila + 2

    ' 1. RESUMEN EJECUTIVO
    Call GenerarResumenEjecutivo(wsDiag, fila, wsInd, wsEERR)

    ' 2. ANÁLISIS DE LIQUIDEZ
    Call GenerarAnalisisLiquidez(wsDiag, fila, wsInd)

    ' 3. ANÁLISIS DE RENTABILIDAD
    Call GenerarAnalisisRentabilidad(wsDiag, fila, wsInd)

    ' 4. ANÁLISIS DE ENDEUDAMIENTO
    Call GenerarAnalisisEndeudamiento(wsDiag, fila, wsInd)

    ' 5. ANÁLISIS DE CICLO DE EFECTIVO
    Call GenerarAnalisisCicloEfectivo(wsDiag, fila, wsInd)

    ' 6. PRINCIPALES HALLAZGOS
    Call GenerarHallazgos(wsDiag, fila, wsInd)

    ' 7. RECOMENDACIONES
    Call GenerarRecomendaciones(wsDiag, fila, wsInd)

    ' 8. CONCLUSIÓN
    Call GenerarConclusión(wsDiag, fila, nombreEmpresa)

    ' Ajustar formato final
    wsDiag.Columns("A:H").WrapText = True
    wsDiag.Rows.AutoFit

    ' Mensaje de confirmación
    MsgBox "Diagnóstico financiero generado exitosamente." & vbCrLf & vbCrLf & _
           "Empresa: " & nombreEmpresa & vbCrLf & _
           "Fecha: " & fechaHoy, vbInformation, "Diagnóstico Completo"

Cleanup:
    Application.ScreenUpdating = True
    Application.Calculation = xlCalculationAutomatic
    Exit Sub

ErrorHandler:
    MsgBox "Error al generar diagnóstico: " & Err.Description, vbCritical
    Resume Cleanup

End Sub

'====================================================================================
' FUNCIONES AUXILIARES PARA GENERACIÓN DE DIAGNÓSTICO
'====================================================================================

Private Sub GenerarResumenEjecutivo(ws As Worksheet, ByRef fila As Integer, wsInd As Worksheet, wsEERR As Worksheet)
    ws.Cells(fila, 1).Value = "1. RESUMEN EJECUTIVO"
    ws.Cells(fila, 1).Font.Bold = True
    ws.Cells(fila, 1).Font.Size = 12
    fila = fila + 1

    ws.Cells(fila, 1).Value = "────────────────────────────────────────────────────────────"
    fila = fila + 2

    ' Generar resumen basado en indicadores clave
    Dim resumen As String
    Dim razonCorriente As Double
    Dim margenNeto As Double
    Dim nivelEndeudamiento As Double

    ' Obtener valores de indicadores (ajustar referencias según estructura real)
    razonCorriente = wsInd.Range("C7").Value ' Ajustar celda
    margenNeto = wsInd.Range("C18").Value ' Ajustar celda
    nivelEndeudamiento = wsInd.Range("C23").Value ' Ajustar celda

    resumen = "La empresa presenta "

    ' Evaluación de liquidez
    If razonCorriente >= 1.5 Then
        resumen = resumen & "una sólida posición de liquidez "
    ElseIf razonCorriente >= 1 Then
        resumen = resumen & "una posición de liquidez aceptable "
    Else
        resumen = resumen & "una situación de liquidez crítica "
    End If

    ' Evaluación de rentabilidad
    If margenNeto >= 0.1 Then
        resumen = resumen & "con buenos márgenes de rentabilidad. "
    ElseIf margenNeto >= 0.05 Then
        resumen = resumen & "con márgenes de rentabilidad ajustados. "
    ElseIf margenNeto > 0 Then
        resumen = resumen & "con márgenes de rentabilidad bajos. "
    Else
        resumen = resumen & "con pérdidas operacionales. "
    End If

    ' Evaluación de endeudamiento
    If nivelEndeudamiento <= 0.5 Then
        resumen = resumen & "El nivel de endeudamiento es saludable, "
    ElseIf nivelEndeudamiento <= 0.7 Then
        resumen = resumen & "El nivel de endeudamiento es moderado, "
    Else
        resumen = resumen & "El nivel de endeudamiento es alto, "
    End If

    resumen = resumen & "lo que permite a la empresa operar con relativa estabilidad financiera."

    ws.Cells(fila, 1).Value = resumen
    fila = fila + 3
End Sub

Private Sub GenerarAnalisisLiquidez(ws As Worksheet, ByRef fila As Integer, wsInd As Worksheet)
    ws.Cells(fila, 1).Value = "2. ANÁLISIS DE LIQUIDEZ"
    ws.Cells(fila, 1).Font.Bold = True
    ws.Cells(fila, 1).Font.Size = 12
    fila = fila + 1

    ws.Cells(fila, 1).Value = "────────────────────────────────────────────────────────────"
    fila = fila + 2

    ' 2.1 Razón Corriente
    ws.Cells(fila, 1).Value = "2.1 Razón Corriente"
    ws.Cells(fila, 1).Font.Bold = True
    fila = fila + 1

    Dim razonCorriente As Double
    razonCorriente = wsInd.Range("C7").Value ' Ajustar

    ws.Cells(fila, 1).Value = "Valor actual: " & Format(razonCorriente, "0.00") & "x"
    fila = fila + 1

    Dim interpretacion As String
    If razonCorriente >= 2 Then
        interpretacion = "La empresa presenta una excelente posición de liquidez. Por cada peso de deuda a corto plazo, " & _
                        "cuenta con $" & Format(razonCorriente, "0.00") & " en activos corrientes para responder. " & _
                        "Esto indica capacidad holgada para cubrir obligaciones inmediatas y trabajar con tranquilidad financiera."
    ElseIf razonCorriente >= 1.5 Then
        interpretacion = "La liquidez es sólida. Por cada peso de deuda a corto plazo, cuenta con $" & _
                        Format(razonCorriente, "0.00") & " en activos corrientes. " & _
                        "La empresa tiene capacidad suficiente para responder por sus obligaciones inmediatas."
    ElseIf razonCorriente >= 1 Then
        interpretacion = "La liquidez es aceptable pero ajustada. Se recomienda monitorear el capital de trabajo " & _
                        "y evaluar la optimización del ciclo de conversión de efectivo para mejorar la posición."
    Else
        interpretacion = "ALERTA: La liquidez es crítica. La empresa NO tiene suficientes activos corrientes " & _
                        "para cubrir sus deudas de corto plazo. Se requiere acción inmediata para mejorar " & _
                        "la posición de caja, ya sea mediante aumento de capital, renegociación de deudas o " & _
                        "aceleración de cobranzas."
    End If

    ws.Cells(fila, 1).Value = "Interpretación: " & interpretacion
    fila = fila + 3

    ' Agregar más indicadores de liquidez aquí...
End Sub

Private Sub GenerarAnalisisRentabilidad(ws As Worksheet, ByRef fila As Integer, wsInd As Worksheet)
    ws.Cells(fila, 1).Value = "3. ANÁLISIS DE RENTABILIDAD"
    ws.Cells(fila, 1).Font.Bold = True
    ws.Cells(fila, 1).Font.Size = 12
    fila = fila + 1

    ws.Cells(fila, 1).Value = "────────────────────────────────────────────────────────────"
    fila = fila + 2

    ' Implementar análisis de rentabilidad similar al de liquidez
    ws.Cells(fila, 1).Value = "[Los márgenes de rentabilidad se analizan aquí...]"
    fila = fila + 3
End Sub

Private Sub GenerarAnalisisEndeudamiento(ws As Worksheet, ByRef fila As Integer, wsInd As Worksheet)
    ws.Cells(fila, 1).Value = "4. ANÁLISIS DE ENDEUDAMIENTO"
    ws.Cells(fila, 1).Font.Bold = True
    ws.Cells(fila, 1).Font.Size = 12
    fila = fila + 1

    ws.Cells(fila, 1).Value = "────────────────────────────────────────────────────────────"
    fila = fila + 2

    ws.Cells(fila, 1).Value = "[El análisis de endeudamiento se genera aquí...]"
    fila = fila + 3
End Sub

Private Sub GenerarAnalisisCicloEfectivo(ws As Worksheet, ByRef fila As Integer, wsInd As Worksheet)
    ws.Cells(fila, 1).Value = "5. ANÁLISIS DEL CICLO DE EFECTIVO"
    ws.Cells(fila, 1).Font.Bold = True
    ws.Cells(fila, 1).Font.Size = 12
    fila = fila + 1

    ws.Cells(fila, 1).Value = "────────────────────────────────────────────────────────────"
    fila = fila + 2

    ws.Cells(fila, 1).Value = "[El ciclo de conversión de efectivo se analiza aquí...]"
    fila = fila + 3
End Sub

Private Sub GenerarHallazgos(ws As Worksheet, ByRef fila As Integer, wsInd As Worksheet)
    ws.Cells(fila, 1).Value = "8. PRINCIPALES HALLAZGOS Y ALERTAS"
    ws.Cells(fila, 1).Font.Bold = True
    ws.Cells(fila, 1).Font.Size = 12
    fila = fila + 1

    ws.Cells(fila, 1).Value = "────────────────────────────────────────────────────────────"
    fila = fila + 2

    ws.Cells(fila, 1).Value = "FORTALEZAS IDENTIFICADAS:"
    ws.Cells(fila, 1).Font.Bold = True
    fila = fila + 1

    ws.Cells(fila, 1).Value = "• [Fortaleza 1 - Se identifica automáticamente]"
    fila = fila + 1
    ws.Cells(fila, 1).Value = "• [Fortaleza 2]"
    fila = fila + 1
    ws.Cells(fila, 1).Value = "• [Fortaleza 3]"
    fila = fila + 2

    ws.Cells(fila, 1).Value = "DEBILIDADES IDENTIFICADAS:"
    ws.Cells(fila, 1).Font.Bold = True
    fila = fila + 1

    ws.Cells(fila, 1).Value = "• [Debilidad 1 - Se identifica automáticamente]"
    fila = fila + 1
    ws.Cells(fila, 1).Value = "• [Debilidad 2]"
    fila = fila + 3
End Sub

Private Sub GenerarRecomendaciones(ws As Worksheet, ByRef fila As Integer, wsInd As Worksheet)
    ws.Cells(fila, 1).Value = "9. RECOMENDACIONES DE ACCIÓN"
    ws.Cells(fila, 1).Font.Bold = True
    ws.Cells(fila, 1).Font.Size = 12
    fila = fila + 1

    ws.Cells(fila, 1).Value = "────────────────────────────────────────────────────────────"
    fila = fila + 2

    ws.Cells(fila, 1).Value = "RECOMENDACIÓN 1: [Título de la recomendación]"
    ws.Cells(fila, 1).Font.Bold = True
    fila = fila + 1

    ws.Cells(fila, 1).Value = "Situación actual: [Descripción del problema detectado]"
    fila = fila + 1
    ws.Cells(fila, 1).Value = "Meta propuesta: [Objetivo cuantificable]"
    fila = fila + 1
    ws.Cells(fila, 1).Value = "Acciones sugeridas:"
    fila = fila + 1
    ws.Cells(fila, 1).Value = "  1. [Acción específica 1]"
    fila = fila + 1
    ws.Cells(fila, 1).Value = "  2. [Acción específica 2]"
    fila = fila + 1
    ws.Cells(fila, 1).Value = "Impacto esperado: [Beneficio cuantificado]"
    fila = fila + 3
End Sub

Private Sub GenerarConclusión(ws As Worksheet, ByRef fila As Integer, nombreEmpresa As String)
    ws.Cells(fila, 1).Value = "10. CONCLUSIÓN"
    ws.Cells(fila, 1).Font.Bold = True
    ws.Cells(fila, 1).Font.Size = 12
    fila = fila + 1

    ws.Cells(fila, 1).Value = "────────────────────────────────────────────────────────────"
    fila = fila + 2

    ws.Cells(fila, 1).Value = nombreEmpresa & " presenta oportunidades de mejora en diversos aspectos financieros. " & _
                              "Es fundamental implementar las recomendaciones propuestas de manera priorizada, " & _
                              "comenzando por los aspectos críticos identificados. Se recomienda hacer seguimiento " & _
                              "mensual a los indicadores clave y ajustar la estrategia según los resultados obtenidos."
    fila = fila + 3

    ws.Cells(fila, 1).Value = "═══════════════════════════════════════════════════════════════"
    fila = fila + 2

    ws.Cells(fila, 1).Value = "Este diagnóstico fue generado automáticamente por el Sistema Integral"
    fila = fila + 1
    ws.Cells(fila, 1).Value = "de Controller Financiero. Se recomienda revisión por parte de un"
    fila = fila + 1
    ws.Cells(fila, 1).Value = "profesional contable para validar interpretaciones y recomendaciones."
End Sub
