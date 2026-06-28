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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Transaction Details'),
        backgroundColor: mainColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: mainColor.withValues(alpha: 0.1),
                    child: Text(
                      widget.debt.name.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: mainColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.debt.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    isBorrow ? 'CREDITOR' : 'DEBTOR',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: mainColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Divider(),
                  ),
                  Row(
                    children: [
                      _buildHeaderStat('Total', _formatCurrency(widget.debt.amount), Colors.blueGrey.shade600),
                      Container(width: 1, height: 30, color: const Color(0xFFE2E8F0)),
                      _buildHeaderStat('Paid', _formatCurrency(widget.debt.paidAmount), Colors.green.shade600),
                      Container(width: 1, height: 30, color: const Color(0xFFE2E8F0)),
                      _buildHeaderStat('Remaining', _formatCurrency(remaining), Colors.red.shade600),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Details List
            _buildSectionHeader('Information'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildDetailTile(Icons.phone_outlined, 'Phone', widget.debt.phone ?? 'N/A'),
                  _buildDetailTile(Icons.calendar_today_outlined, 'Started', _formatDate(widget.debt.dateBorrowed)),
                  _buildDetailTile(Icons.event_note_outlined, 'Due Date', widget.debt.dueDate != null ? _formatDate(widget.debt.dueDate!) : 'N/A', isLast: true),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (widget.debt.description?.isNotEmpty == true) ...[
              _buildSectionHeader('Notes'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  widget.debt.description!,
                  style: TextStyle(color: Colors.blueGrey.shade700, height: 1.5),
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (widget.debt.photoPath != null && File(widget.debt.photoPath!).existsSync()) ...[
              _buildSectionHeader('Attachment'),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(widget.debt.photoPath!),
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
            ],

            _buildSectionHeader('Activity History'),
            FutureBuilder<List<DebtHistoryEntry>>(
              future: _historyFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                }
                final history = snapshot.data ?? [];
                if (history.isEmpty) {
                  return _buildEmptyState('No activity yet');
                }
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: history.length,
                    separatorBuilder: (_, _) => const Divider(indent: 50, height: 1),
                    itemBuilder: (context, index) {
                      final entry = history[index];
                      final color = _historyColor(entry);
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: color.withValues(alpha: 0.1),
                          child: Icon(
                            entry.action == 'Payment' ? Icons.check : Icons.edit,
                            size: 14,
                            color: color,
                          ),
                        ),
                        title: Text(
                          _historyLabel(entry),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          DateFormat('MMM dd, yyyy • hh:mm a').format(
                            DateTime.tryParse(entry.createdAt) ?? DateTime.now(),
                          ),
                          style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade500),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blueGrey.shade500),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: valueColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Colors.blueGrey.shade500,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String label, String value, {bool isLast = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey.shade400),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: Colors.blueGrey.shade600, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: TextStyle(fontWeight: FontWeight.w700, color: Colors.blueGrey.shade900)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey.shade400)),
    );
  }
}
