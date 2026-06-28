import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_settings_provider.dart';
import '../models/debt_history_entry.dart';
import '../models/debt_model1.dart';
import '../providers/debt_provider.dart';

class TransactionDetailScreen extends StatefulWidget {
  final DebtModel debt;

  const TransactionDetailScreen({super.key, required this.debt});

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late Future<List<DebtHistoryEntry>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = context.read<DebtProvider>().getDebtHistory(widget.debt.id!);
  }

  String _formatCurrency(double amount) {
    return context.read<AppSettingsProvider>().formatCurrency(amount);
  }

  String _formatDate(String value) {
    return context.read<AppSettingsProvider>().formatStoredDate(value);
  }

  Color _historyColor(DebtHistoryEntry entry) {
    switch (entry.action) {
      case 'Payment':
        return Colors.green.shade700;
      case 'Added More':
        return Colors.orange.shade700;
      case 'Updated':
        return Colors.blue.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  String _historyLabel(DebtHistoryEntry entry) {
    if (entry.amount == null) {
      return entry.action;
    }
    return '${entry.action}: ${_formatCurrency(entry.amount!)}';
  }

  @override
  Widget build(BuildContext context) {
    final isBorrow = widget.debt.type == 'borrow';
    final mainColor = isBorrow ? Colors.green.shade600 : Colors.red.shade600;
    final remaining = widget.debt.amount - widget.debt.paidAmount;
    final settings = context.watch<AppSettingsProvider>();
    final dueDateText = widget.debt.dueDate ?? 'undefined';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        backgroundColor: mainColor,
        foregroundColor: Colors.white,
        flexibleSpace: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [mainColor, mainColor.withValues(alpha: 0.86)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _animatedEntry(
            delayMs: 0,
            child: Card(
              child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: mainColor.withValues(alpha: 0.12),
                        child: Icon(Icons.person, color: mainColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.debt.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isBorrow ? 'Creditor' : 'Debtor',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _statusChip(
                        icon: Icons.calendar_today,
                        label:
                          'Since ${settings.formatStoredDate(widget.debt.dateBorrowed)} --> ${widget.debt.dueDate == null ? 'undefined' : settings.formatStoredDate(widget.debt.dueDate!)}',
                        background: Colors.grey.shade100,
                        foreground: Colors.grey.shade800,
                      ),
                      _statusChip(
                        icon: Icons.payments_outlined,
                        label: _formatCurrency(widget.debt.amount),
                        background: Colors.blue.shade50,
                        foreground: Colors.blue.shade800,
                      ),
                      _statusChip(
                        icon: Icons.check_circle_outline,
                        label: _formatCurrency(widget.debt.paidAmount),
                        background: Colors.green.shade50,
                        foreground: Colors.green.shade800,
                      ),
                      _statusChip(
                        icon: Icons.timelapse,
                        label: _formatCurrency(remaining),
                        background: Colors.orange.shade50,
                        foreground: Colors.orange.shade800,
                      ),
                    ],
                  ),
                ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _animatedEntry(
            delayMs: 45,
            child: Card(
              child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'All Parameters',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _detailRow('Type', isBorrow ? 'Borrow' : 'Lend'),
                  _detailRow(
                    'Phone',
                    widget.debt.phone?.isNotEmpty == true
                        ? widget.debt.phone!
                        : 'undefined',
                  ),
                  _detailRow('Date Borrowed', _formatDate(widget.debt.dateBorrowed)),
                  _detailRow('Due Date', dueDateText == 'undefined' ? dueDateText : _formatDate(dueDateText)),
                  _detailRow('Total Amount', _formatCurrency(widget.debt.amount)),
                  _detailRow('Paid Amount', _formatCurrency(widget.debt.paidAmount)),
                  _detailRow('Remaining Amount', _formatCurrency(remaining)),
                  _detailRow(
                    'Description',
                    widget.debt.description?.isNotEmpty == true
                        ? widget.debt.description!
                        : 'undefined',
                  ),
                ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (widget.debt.photoPath != null && File(widget.debt.photoPath!).existsSync())
            _animatedEntry(
              delayMs: 80,
              child: Card(
                child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Receipt / Invoice',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(widget.debt.photoPath!),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                  ),
                ),
              ),
            ),
          if (widget.debt.photoPath != null && File(widget.debt.photoPath!).existsSync())
            const SizedBox(height: 12),
          _animatedEntry(
            delayMs: 120,
            child: Card(
              child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Transaction History',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  FutureBuilder<List<DebtHistoryEntry>>(
                    future: _historyFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (snapshot.hasError) {
                        return Text(
                          'Unable to load history',
                          style: TextStyle(color: Colors.red.shade700),
                        );
                      }

                      final history = snapshot.data ?? const <DebtHistoryEntry>[];
                      if (history.isEmpty) {
                        return Text(
                          'No activity recorded yet',
                          style: TextStyle(color: Colors.grey.shade600),
                        );
                      }

                      return Column(
                        children: history.map((entry) {
                          final color = _historyColor(entry);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: color.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.arrow_right_alt, color: color, size: 20),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _historyLabel(entry),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: color,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('dd MMM yyyy, hh:mm a').format(
                                          DateTime.tryParse(entry.createdAt) ??
                                              DateTime.now(),
                                        ),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      if (entry.note != null && entry.note!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          entry.note!,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                      if (entry.balanceAfter != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Balance after: ${_formatCurrency(entry.balanceAfter!)}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip({
    required IconData icon,
    required String label,
    required Color background,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _animatedEntry({
    required Widget child,
    required int delayMs,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 220 + delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, value, animatedChild) {
        final offsetY = (1 - value) * 10;
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, offsetY),
            child: animatedChild,
          ),
        );
      },
      child: child,
    );
  }
}