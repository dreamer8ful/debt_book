import 'dart:io';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import '../models/debt_model1.dart';

class ExportService {
  final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  String formatCurrency(double amount) {
    return NumberFormat('#,##0', 'en_US').format(amount);
  }

  // 1. EXPORT TO EXCEL
  Future<String> exportToExcel(List<DebtModel> debts) async {
    final excel = Excel.createExcel();
    final Sheet sheet = excel['Debt Report'];

    // Header style
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.blue,
      fontColorHex: ExcelColor.white,
      horizontalAlign: HorizontalAlign.Center,
    );

    // Headers
    sheet.appendRow([
      TextCellValue('Name'),
      TextCellValue('Phone'),
      TextCellValue('Type'),
      TextCellValue('Total Amount'),
      TextCellValue('Paid Amount'),
      TextCellValue('Remaining'),
      TextCellValue('Status'),
      TextCellValue('Date'),
    ]);

    // Style header
    for (var i = 0; i < 8; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = headerStyle;
    }

    // Data rows
    for (var debt in debts) {
      final remaining = debt.amount - debt.paidAmount;
      final status = debt.paidAmount >= debt.amount ? 'Paid Off' : 'Active';
      
      sheet.appendRow([
        TextCellValue(debt.name),
        TextCellValue(debt.phone ?? ''),
        TextCellValue(debt.type == 'lend' ? 'Lend' : 'Borrow'),
        DoubleCellValue(debt.amount),
        DoubleCellValue(debt.paidAmount),
        DoubleCellValue(remaining),
        TextCellValue(status),
        TextCellValue(debt.dateBorrowed),
      ]);
    }

    // Summary
    sheet.appendRow([]);
    final totalLend = debts.where((d) => d.type == 'lend').fold(0.0, (sum, d) => sum + (d.amount - d.paidAmount));
    final totalBorrow = debts.where((d) => d.type == 'borrow').fold(0.0, (sum, d) => sum + (d.amount - d.paidAmount));
    
    sheet.appendRow([TextCellValue('SUMMARY')]);
    sheet.appendRow([TextCellValue('Total to Collect'), DoubleCellValue(totalLend)]);
    sheet.appendRow([TextCellValue('Total to Pay'), DoubleCellValue(totalBorrow)]);

    // Save file
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyy-MM-dd-HH-mm-ss').format(DateTime.now());
    final path = '${dir.path}/Debt-Report-$timestamp.xlsx';
    final fileBytes = excel.encode();
    
    final file = File(path)..createSync(recursive: true);
    file.writeAsBytesSync(fileBytes!);
    
    return path;
  }

  // 2. EXPORT TO PDF
  Future<String> exportToPdf(List<DebtModel> debts) async {
    final pdf = pw.Document();
    final totalLend = debts.where((d) => d.type == 'lend').fold(0.0, (sum, d) => sum + (d.amount - d.paidAmount));
    final totalBorrow = debts.where((d) => d.type == 'borrow').fold(0.0, (sum, d) => sum + (d.amount - d.paidAmount));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Debt Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 10),
          pw.Text('Generated: ${dateFormat.format(DateTime.now())}'),
          pw.SizedBox(height: 20),
          
          // Summary
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(border: pw.Border.all()),
            child: pw.Column(children: [
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('Total to Collect:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('${formatCurrency(totalLend)} TSh', style: pw.TextStyle(color: PdfColors.green)),
              ]),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('Total to Pay:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('${formatCurrency(totalBorrow)} TSh', style: pw.TextStyle(color: PdfColors.red)),
              ]),
            ]),
          ),
          pw.SizedBox(height: 20),
          
          // Table
          pw.TableHelper.fromTextArray(
            headers: ['Name', 'Type', 'Total', 'Paid', 'Remaining', 'Status'],
            data: debts.map((debt) {
              final remaining = debt.amount - debt.paidAmount;
              return [
                debt.name,
                debt.type == 'lend' ? 'Lend' : 'Borrow',
                formatCurrency(debt.amount),
                formatCurrency(debt.paidAmount),
                formatCurrency(remaining),
                debt.paidAmount >= debt.amount ? 'Paid Off' : 'Active',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          ),
        ],
      ),
    );

    // Save file
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyy-MM-dd-HH-mm-ss').format(DateTime.now());
    final path = '${dir.path}/Debt-Report-$timestamp.pdf';
    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    
    return path;
  }

  // 3. OPEN FILE
  Future<void> openFile(String path) async {
    await OpenFile.open(path);
  }
}