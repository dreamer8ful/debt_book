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
  bool _settled = true;
  bool _lend = true;
  bool _borrow = true;

  List<DebtModel> _filterDebts(List<DebtModel> allDebts) {
    return allDebts.where((debt) {
      final isSettled = debt.paidAmount >= debt.amount;
      final statusOk = (_active && !isSettled) || (_settled && isSettled);
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
    _showSuccess('Excel export complete');
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
    _showSuccess('PDF export complete');
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$msg at $_lastPath'),
        action: SnackBarAction(
          label: 'Open File',
          onPressed: () => _exportService.openFile(_lastPath!),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Export Records'),
        backgroundColor: const Color(0xFF0D6B8A),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Report Configuration'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Status',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildToggleChip('Active', _active, (v) => setState(() => _active = v)),
                      const SizedBox(width: 8),
                      _buildToggleChip('Settled', _settled, (v) => setState(() => _settled = v)),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(),
                  ),
                  const Text(
                    'Select Type',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildToggleChip('Lend', _lend, (v) => setState(() => _lend = v)),
                      const SizedBox(width: 8),
                      _buildToggleChip('Borrow', _borrow, (v) => setState(() => _borrow = v)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader('Export Format'),
          Row(
            children: [
              Expanded(
                child: _buildExportCard(
                  title: 'Excel Sheet',
                  subtitle: '.xlsx format',
                  icon: Icons.table_chart_outlined,
                  color: const Color(0xFF2E9E5B),
                  onTap: _isLoading ? null : _exportExcel,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildExportCard(
                  title: 'PDF Document',
                  subtitle: '.pdf format',
                  icon: Icons.picture_as_pdf_outlined,
                  color: const Color(0xFFB23A48),
                  onTap: _isLoading ? null : _exportPdf,
                ),
              ),
            ],
          ),
          
          if (_isLoading) ...[
            const SizedBox(height: 32),
            const Center(child: CircularProgressIndicator()),
          ],

          if (_lastPath != null) ...[
            const SizedBox(height: 32),
            _buildSectionHeader('Recent Export'),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.file_present, color: Colors.blueGrey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Export Successful', style: TextStyle(fontWeight: FontWeight.w700)),
                        Text(
                          _lastPath!.split('\\').last,
                          style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _exportService.openFile(_lastPath!),
                    child: const Text('Open'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: Colors.blueGrey.shade500,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildToggleChip(String label, bool isSelected, Function(bool) onToggle) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onToggle,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildExportCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
