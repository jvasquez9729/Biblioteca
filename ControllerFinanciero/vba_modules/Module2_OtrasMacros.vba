Attribute VB_Name = "Module2_OtrasMacros"
Option Explicit

'====================================================================================
' MÓDULO 2: OTRAS MACROS DEL SISTEMA
' Sistema Integral de Controller Financiero
'====================================================================================

'-----------------------------------------------------------------------------------
' MACRO: Actualizar Gráficos
'-----------------------------------------------------------------------------------
Sub ActualizarGraficos()
    '
    ' ActualizarGraficos Macro
    ' Actualiza todos los gráficos del dashboard
    '

    Application.ScreenUpdating = False

    On Error Resume Next

    Dim cht As ChartObject
    Dim ws As Worksheet

    ' Actualizar gráficos en la hoja INFORME VISUAL
    Set ws = ThisWorkbook.Sheets("INFORME VISUAL")

    For Each cht In ws.ChartObjects
        cht.Chart.Refresh
    Next cht

    ' Recalcular toda la hoja
    ws.Calculate

    Application.ScreenUpdating = True

    MsgBox "Gráficos actualizados exitosamente.", vbInformation, "Actualización Completa"

End Sub

'-----------------------------------------------------------------------------------
' MACRO: Exportar a PDF
'-----------------------------------------------------------------------------------
Sub ExportarPDF()
    '
    ' ExportarPDF Macro
    ' Exporta el diagnóstico e informe visual a PDF
    '

    Dim rutaPDF As String
    Dim nombreArchivo As String
    Dim nombreEmpresa As String
    Dim fechaHoy As String

    Application.ScreenUpdating = False

    ' Obtener nombre de la empresa
    nombreEmpresa = ThisWorkbook.Sheets("CONFIGURACIÓN").Range("B5").Value
    If nombreEmpresa = "" Then nombreEmpresa = "Empresa"

    fechaHoy = Format(Date, "yyyymmdd")

    ' Limpiar nombre de empresa para usarlo en nombre de archivo
    nombreEmpresa = Replace(nombreEmpresa, " ", "_")
    nombreEmpresa = Replace(nombreEmpresa, ".", "")

    ' Definir nombre del archivo PDF
    nombreArchivo = "Diagnostico_Financiero_" & nombreEmpresa & "_" & fechaHoy & ".pdf"

    ' Obtener ruta donde guardar (mismo directorio del archivo Excel)
    rutaPDF = ThisWorkbook.Path & "\" & nombreArchivo

    On Error GoTo ErrorHandler

    ' Exportar hojas seleccionadas a PDF
    Dim arrHojas As Variant
    arrHojas = Array("DIAGNÓSTICO", "INFORME VISUAL", "INDICADORES")

    ThisWorkbook.Sheets(arrHojas).Select
    ActiveSheet.ExportAsFixedFormat _
        Type:=xlTypePDF, _
        Filename:=rutaPDF, _
        Quality:=xlQualityStandard, _
        IncludeDocProperties:=True, _
        IgnorePrintAreas:=False, _
        OpenAfterPublish:=True

    ' Volver a la hoja de diagnóstico
    ThisWorkbook.Sheets("DIAGNÓSTICO").Select

    Application.ScreenUpdating = True

    MsgBox "Archivo PDF exportado exitosamente:" & vbCrLf & vbCrLf & rutaPDF, vbInformation, "Exportación Completa"

    Exit Sub

ErrorHandler:
    Application.ScreenUpdating = True
    MsgBox "Error al exportar PDF: " & Err.Description & vbCrLf & vbCrLf & _
           "Verifique que no haya otro archivo PDF abierto con el mismo nombre.", vbCritical
End Sub

'-----------------------------------------------------------------------------------
' MACRO: Limpiar Datos
'-----------------------------------------------------------------------------------
Sub LimpiarDatos()
    '
    ' LimpiarDatos Macro
    ' Limpia todas las celdas de entrada para comenzar un nuevo análisis
    '

    Dim respuesta As VbMsgBoxResult

    ' Confirmar con el usuario
    respuesta = MsgBox("¿Está seguro que desea limpiar TODOS los datos ingresados?" & vbCrLf & vbCrLf & _
                      "Esta acción no se puede deshacer.", vbQuestion + vbYesNo, "Confirmar Limpieza")

    If respuesta = vbNo Then Exit Sub

    Application.ScreenUpdating = False
    Application.Calculation = xlCalculationManual

    On Error Resume Next

    ' Limpiar hoja CONFIGURACIÓN
    With ThisWorkbook.Sheets("CONFIGURACIÓN")
        .Range("B5").ClearContents ' Nombre empresa
        .Range("B7").ClearContents ' Sector
        .Range("B8").ClearContents ' CIIU
    End With

    ' Limpiar hoja EERR (Estado de Resultados)
    With ThisWorkbook.Sheets("EERR")
        ' Limpiar columnas de datos (B, D, G para años 2022, 2023, 2024)
        Dim celda As Range
        For Each celda In .Range("B:B,D:D,G:G").Cells
            If celda.Font.Color = RGB(0, 0, 255) Then ' Solo celdas azules (inputs)
                celda.ClearContents
            End If
        Next celda
    End With

    ' Limpiar hoja ESF (Balance General)
    With ThisWorkbook.Sheets("ESF")
        For Each celda In .Range("B:B,D:D,G:G").Cells
            If celda.Font.Color = RGB(0, 0, 255) Then
                celda.ClearContents
            End If
        Next celda
    End With

    ' Limpiar hoja PUNTO DE EQUILIBRIO
    With ThisWorkbook.Sheets("PUNTO EQUILIBRIO")
        .Range("B5:B12").ClearContents ' Datos de entrada
    End With

    ' Limpiar hoja PROYECCIONES
    With ThisWorkbook.Sheets("PROYECCIONES")
        .Range("B5:B15").ClearContents ' Supuestos
    End With

    ' Limpiar hoja VALORACIÓN
    With ThisWorkbook.Sheets("VALORACIÓN")
        .Range("B5:B25").ClearContents ' Datos de valoración
    End With

    Application.Calculation = xlCalculationAutomatic
    Application.ScreenUpdating = True

    MsgBox "Todos los datos han sido limpiados exitosamente." & vbCrLf & vbCrLf & _
           "Puede comenzar un nuevo análisis.", vbInformation, "Limpieza Completa"

End Sub

'-----------------------------------------------------------------------------------
' MACRO: Calcular Escenarios
'-----------------------------------------------------------------------------------
Sub CalcularEscenarios()
    '
    ' CalcularEscenarios Macro
    ' Recalcula las proyecciones para los tres escenarios (base, optimista, pesimista)
    '

    Application.ScreenUpdating = False
    Application.Calculation = xlCalculationManual

    Dim ws As Worksheet
    Set ws = ThisWorkbook.Sheets("PROYECCIONES")

    ' Asegurarse de que los supuestos estén completos
    If ws.Range("B5").Value = "" Then
        MsgBox "Por favor complete los supuestos de proyección antes de calcular escenarios.", vbExclamation
        Application.ScreenUpdating = True
        Application.Calculation = xlCalculationAutomatic
        Exit Sub
    End If

    ' Recalcular escenarios
    ' (Las fórmulas en la hoja ya deben estar configuradas para los 3 escenarios)

    ws.Calculate

    Application.Calculation = xlCalculationAutomatic
    Application.ScreenUpdating = True

    MsgBox "Los escenarios han sido recalculados:" & vbCrLf & vbCrLf & _
           "• Escenario Base (0%)" & vbCrLf & _
           "• Escenario Optimista (+15%)" & vbCrLf & _
           "• Escenario Pesimista (-15%)", vbInformation, "Escenarios Actualizados"

End Sub

'-----------------------------------------------------------------------------------
' MACRO: Proteger Hojas
'-----------------------------------------------------------------------------------
Sub ProtegerHojas()
    '
    ' ProtegerHojas Macro
    ' Protege todas las hojas dejando solo las celdas de entrada desbloqueadas
    '

    Dim ws As Worksheet
    Dim pwd As String

    pwd = "controller2024" ' Contraseña para desproteger

    Application.ScreenUpdating = False

    For Each ws In ThisWorkbook.Worksheets
        ' Desproteger primero por si ya estaba protegida
        On Error Resume Next
        ws.Unprotect Password:=pwd
        On Error GoTo 0

        ' Bloquear todas las celdas
        ws.Cells.Locked = True

        ' Desbloquear celdas de entrada (azules)
        Dim celda As Range
        For Each celda In ws.UsedRange.Cells
            If celda.Font.Color = RGB(0, 0, 255) Or _
               celda.Interior.Color = RGB(255, 255, 0) Then ' Azules o amarillas
                celda.Locked = False
            End If
        Next celda

        ' Proteger la hoja
        ws.Protect Password:=pwd, _
                   DrawingObjects:=True, _
                   Contents:=True, _
                   Scenarios:=True, _
                   AllowFormattingCells:=False, _
                   AllowFormattingColumns:=False, _
                   AllowFormattingRows:=False

    Next ws

    Application.ScreenUpdating = True

    MsgBox "Todas las hojas han sido protegidas." & vbCrLf & vbCrLf & _
           "Solo las celdas de entrada (azules) pueden ser editadas." & vbCrLf & _
           "Contraseña: " & pwd, vbInformation, "Protección Activada"

End Sub

'-----------------------------------------------------------------------------------
' MACRO: Desproteger Hojas
'-----------------------------------------------------------------------------------
Sub DesprotegerHojas()
    '
    ' DesprotegerHojas Macro
    ' Desprotege todas las hojas para edición completa
    '

    Dim ws As Worksheet
    Dim pwd As String

    pwd = "controller2024"

    Application.ScreenUpdating = False

    On Error Resume Next
    For Each ws In ThisWorkbook.Worksheets
        ws.Unprotect Password:=pwd
    Next ws
    On Error GoTo 0

    Application.ScreenUpdating = True

    MsgBox "Todas las hojas han sido desprotegidas.", vbInformation, "Protección Desactivada"

End Sub

'-----------------------------------------------------------------------------------
' FUNCIÓN AUXILIAR: Validar Balance
'-----------------------------------------------------------------------------------
Function ValidarBalance() As Boolean
    '
    ' Valida que el balance cuadre (Activo = Pasivo + Patrimonio)
    '

    Dim ws As Worksheet
    Set ws = ThisWorkbook.Sheets("ESF")

    Dim totalActivo As Double
    Dim totalPasivoPatrimonio As Double
    Dim diferencia As Double

    ' Obtener totales (ajustar referencias según estructura real)
    totalActivo = ws.Range("B24").Value ' Ajustar celda
    totalPasivoPatrimonio = ws.Range("B57").Value ' Ajustar celda

    diferencia = Abs(totalActivo - totalPasivoPatrimonio)

    ' Considerar válido si la diferencia es menor a 1 (por redondeos)
    If diferencia < 1 Then
        ValidarBalance = True
    Else
        ValidarBalance = False
        MsgBox "ALERTA: El balance no cuadra." & vbCrLf & vbCrLf & _
               "Total Activo: " & Format(totalActivo, "#,##0") & vbCrLf & _
               "Total Pasivo + Patrimonio: " & Format(totalPasivoPatrimonio, "#,##0") & vbCrLf & _
               "Diferencia: " & Format(diferencia, "#,##0") & vbCrLf & vbCrLf & _
               "Por favor revise los datos ingresados.", vbCritical, "Error de Cuadre"
    End If

End Function
