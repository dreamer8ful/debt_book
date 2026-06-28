import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/debt_provider.dart';
import '../services/export_service.dart';
import '../models/debt_model1.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final _exportService = ExportService();
  bool _isLoading = false;
  String? _lastPath;

  // Filters
  bool _active = true;
  bool _paidOff = true;
  bool _lend = true;
  bool _borrow = true;

  List<DebtModel> _filterDebts(List<DebtModel> allDebts) {
    return allDebts.where((debt) {
      final isPaidOff = debt.paidAmount >= debt.amount;
      final statusOk = (_active && !isPaidOff) || (_paidOff && isPaidOff);
      final typeOk =
          (_lend && debt.type == 'lend') || (_borrow && debt.type == 'borrow');
      return statusOk && typeOk;
    }).toList();
  }

  Future<void> _exportExcel() async {
    setState(() => _isLoading = true);
    final provider = context.read<DebtProvider>();
    final allDebts = [...provider.lendList, ...provider.borrowList];
    final debts = _filterDebts(allDebts);
    final path = await _exportService.exportToExcel(debts);
    setState(() {
      _isLoading = false;
      _lastPath = path;
    });
    _showSuccess('Excel saved');
  }

  Future<void> _exportPdf() async {
    setState(() => _isLoading = true);
    final provider = context.read<DebtProvider>();
    final allDebts = [...provider.lendList, ...provider.borrowList];
    final debts = _filterDebts(allDebts);
    final path = await _exportService.exportToPdf(debts);
    setState(() {
      _isLoading = false;
      _lastPath = path;
    });
    _showSuccess('PDF saved');
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$msg at $_lastPath'),
        action: SnackBarAction(
          label: 'OPEN',
          onPressed: () => _exportService.openFile(_lastPath!),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.book),
              title: const Text('Master Book'),
              subtitle: const Text('Choose which records to export'),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active'),
                    value: _active,
                    onChanged: (v) => setState(() => _active = v!),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Paid Off'),
                    value: _paidOff,
                    onChanged: (v) => setState(() => _paidOff = v!),
                  ),
                  const Divider(),
                  const Text(
                    'Type',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Lend'),
                    value: _lend,
                    onChanged: (v) => setState(() => _lend = v!),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Borrow'),
                    value: _borrow,
                    onChanged: (v) => setState(() => _borrow = v!),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_lastPath != null)
            Text(
              'Stored at: $_lastPath',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _exportExcel,
                  icon: const Icon(Icons.table_chart),
                  label: const Text('EXPORT XLS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _exportPdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('EXPORT PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
