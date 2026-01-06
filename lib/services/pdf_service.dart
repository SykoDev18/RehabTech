import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:rehabtech/services/progress_service.dart';

class PdfService {
  static Future<Uint8List> generateProgressReport(String period) async {
    final progressService = ProgressService();
    final profile = progressService.userProfile;
    
    Map<String, dynamic> stats;
    String periodTitle;
    
    switch (period) {
      case 'Semanal':
        stats = progressService.getWeeklyStats();
        periodTitle = 'Reporte Semanal';
        break;
      case 'Mensual':
        stats = progressService.getMonthlyStats();
        periodTitle = 'Reporte Mensual';
        break;
      default:
        stats = progressService.getTotalStats();
        periodTitle = 'Reporte Total';
    }

    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // Header
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#3B82F6'),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'RehabTech',
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  periodTitle,
                  style: const pw.TextStyle(
                    fontSize: 18,
                    color: PdfColors.white,
                  ),
                ),
                pw.Text(
                  'Generado el ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.white,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 30),

          // Información del paciente
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Información del Paciente',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Nombre: ${profile.name} ${profile.lastName}'),
                    pw.Text('Condición: ${profile.condition.isNotEmpty ? profile.condition : "No especificada"}'),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Terapeuta: ${profile.therapistName.isNotEmpty ? profile.therapistName : "No asignado"}'),
                    pw.Text('Email: ${profile.email.isNotEmpty ? profile.email : "No especificado"}'),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 30),

          // Resumen de estadísticas
          pw.Text(
            'Resumen de Progreso',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 16),
          
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildStatBox('Ejercicios\nCompletados', '${stats['totalExercises']}', '#22C55E'),
              _buildStatBox('Tiempo\nActivo', _formatDuration(stats['totalSeconds'] ?? 0), '#3B82F6'),
              _buildStatBox('Dolor\nPromedio', '${(stats['avgPain'] ?? 0).toStringAsFixed(1)}/10', '#F59E0B'),
              if (stats['streak'] != null)
                _buildStatBox('Racha\nActual', '${stats['streak']} días', '#EF4444'),
            ],
          ),
          pw.SizedBox(height: 30),

          // Detalles según período
          pw.Text(
            'Detalles del Período',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 16),
          
          _buildProgressTable(progressService.progressList, period),
          pw.SizedBox(height: 30),

          // Recomendaciones
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F0FDF4'),
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColor.fromHex('#22C55E')),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Recomendaciones',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#166534'),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  '• Mantén la constancia en tus ejercicios diarios',
                  style: const pw.TextStyle(fontSize: 11),
                ),
                pw.Text(
                  '• Si experimentas dolor mayor a 5/10, consulta con tu terapeuta',
                  style: const pw.TextStyle(fontSize: 11),
                ),
                pw.Text(
                  '• Recuerda realizar los ejercicios con la técnica correcta',
                  style: const pw.TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount} - RehabTech © 2026',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
        ),
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildStatBox(String label, String value, String colorHex) {
    final baseColor = PdfColor.fromHex(colorHex);
    return pw.Container(
      width: 100,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor(baseColor.red, baseColor.green, baseColor.blue, 0.1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex(colorHex),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            label,
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildProgressTable(List<ProgressData> data, String period) {
    // Filtrar datos según período
    final now = DateTime.now();
    List<ProgressData> filteredData;
    
    switch (period) {
      case 'Semanal':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        filteredData = data.where((p) => p.date.isAfter(weekStart.subtract(const Duration(days: 1)))).toList();
        break;
      case 'Mensual':
        final monthStart = DateTime(now.year, now.month, 1);
        filteredData = data.where((p) => p.date.isAfter(monthStart.subtract(const Duration(days: 1)))).toList();
        break;
      default:
        filteredData = data;
    }

    if (filteredData.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(20),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Text(
          'No hay datos registrados para este período',
          style: const pw.TextStyle(color: PdfColors.grey),
        ),
      );
    }

    // Tomar los últimos 10 registros
    final displayData = filteredData.length > 10 
      ? filteredData.sublist(filteredData.length - 10) 
      : filteredData;

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F3F4F6')),
          children: [
            _tableCell('Fecha', isHeader: true),
            _tableCell('Ejercicio', isHeader: true),
            _tableCell('Reps', isHeader: true),
            _tableCell('Duración', isHeader: true),
            _tableCell('Dolor', isHeader: true),
          ],
        ),
        ...displayData.map((p) => pw.TableRow(
          children: [
            _tableCell('${p.date.day}/${p.date.month}'),
            _tableCell(p.exerciseName),
            _tableCell('${p.completedReps}/${p.totalReps}'),
            _tableCell(_formatDuration(p.durationSeconds)),
            _tableCell('${p.painLevel}/10'),
          ],
        )),
      ],
    );
  }

  static pw.Widget _tableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 11 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  static Future<void> sharePdf(String period) async {
    final pdfBytes = await generateProgressReport(period);
    
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/reporte_progreso_$period.pdf');
    await file.writeAsBytes(pdfBytes);
    
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Mi reporte de progreso de RehabTech - $period',
      subject: 'Reporte de Progreso RehabTech',
    );
  }

  static Future<void> printPdf(String period) async {
    final pdfBytes = await generateProgressReport(period);
    await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
  }
}
