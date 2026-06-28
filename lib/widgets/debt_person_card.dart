// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_settings_provider.dart';
import '../models/debt_model1.dart';
import '../providers/debt_provider.dart';
import '../screens/transaction_detail_screen.dart';
import '../screens/update_transaction_screen.dart';
import '../widgets/payment_dialog.dart';

class DebtPersonCard extends StatefulWidget {
  final DebtModel debt;
  final VoidCallback onDelete;

  const DebtPersonCard({super.key, required this.debt, required this.onDelete});

  @override
  State<DebtPersonCard> createState() => _DebtPersonCardState();
}

class _DebtPersonCardState extends State<DebtPersonCard> {
  bool _isExpanded = false;

  PageRouteBuilder<void> _buildPageRoute(Widget page) {
    return PageRouteBuilder<void>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slide = Tween<Offset>(
          begin: const Offset(0.03, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
        final fade = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }

  String formatCurrency(double amount) {
    return context.read<AppSettingsProvider>().formatCurrency(amount);
  }

  void _showFeedback(String message, {Color? backgroundColor}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showPayDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentDialog(debt: widget.debt),
    );

    if (result == null || !mounted) return;

    try {
      final amount = result['amount'] as double;
      final date = result['date'] as DateTime;
      final note = result['note'] as String?;

      await context.read<DebtProvider>().addPayment(
            widget.debt.id!,
            amount,
            date: date,
            note: note,
          );

      if (!mounted) return;
      _showFeedback(
        '${widget.debt.type == 'lend' ? 'Collected' : 'Paid'} ${formatCurrency(amount)}',
        backgroundColor: Colors.green.shade600,
      );
    } catch (e) {
      if (!mounted) return;
      _showFeedback('Error: $e', backgroundColor: Colors.red.shade600);
    }
  }

  void _showAddMoreDialog() {
    final moreController = TextEditingController();
    final isBorrow = widget.debt.type == 'borrow';
    final actionText = isBorrow ? 'Borrow more from' : 'Lend more to';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
        contentPadding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.shade700.withValues(alpha: 0.12),
              child: Icon(Icons.add_card_rounded, size: 16, color: Colors.blue.shade700),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$actionText ${widget.debt.name}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade700.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade700.withValues(alpha: 0.15)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Current remaining',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    formatCurrency(widget.debt.amount - widget.debt.paidAmount),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: moreController,
              decoration: InputDecoration(
                labelText: 'Additional Amount',
                prefixText: context.read<AppSettingsProvider>().currencySymbol,
                hintText: isBorrow ? 'Borrow more' : 'Lend more',
                prefixIcon: const Icon(Icons.payments_outlined),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final moreAmount = double.tryParse(moreController.text) ?? 0;
              if (moreAmount > 0) {
                Provider.of<DebtProvider>(
                  context,
                  listen: false,
                ).addMoreDebt(widget.debt.id!, moreAmount);
                Navigator.pop(context);
                _showFeedback('Added ${formatCurrency(moreAmount)}');
              } else {
                _showFeedback('Invalid amount', backgroundColor: Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.padded,
              backgroundColor: Colors.blue.shade700,
            ),
            child: Text(
              'Confirm ${isBorrow ? 'Borrow' : 'Lend'}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showDeleteConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
        contentPadding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.red.shade700.withValues(alpha: 0.12),
              child: Icon(Icons.delete_outline, size: 16, color: Colors.red.shade700),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Delete Transaction',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete ${widget.debt.name}? This action cannot be undone.',
          style: TextStyle(color: Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.padded,
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _openUpdatePage() async {
    await Navigator.push(
      context,
      _buildPageRoute(UpdateTransactionScreen(debt: widget.debt)),
    );
  }

  Future<void> _openDetailsPage() async {
    await Navigator.push(
      context,
      _buildPageRoute(TransactionDetailScreen(debt: widget.debt)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBorrow = widget.debt.type == 'borrow';
    final mainColor = isBorrow ? Colors.green.shade600 : Colors.red.shade600;
    final remainingAmount = widget.debt.amount - widget.debt.paidAmount;
    final buttonText = widget.debt.type == 'lend' ? 'Collect' : 'Pay';
    final isPaid = remainingAmount <= 0;
    final settings = context.watch<AppSettingsProvider>();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: _isExpanded ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _isExpanded ? mainColor.withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: mainColor.withValues(alpha: 0.1),
                      child: Text(
                        widget.debt.name.substring(0, 1).toUpperCase(),
                        style: TextStyle(color: mainColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.debt.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: mainColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isBorrow ? 'CREDITOR' : 'DEBTOR',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: mainColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isPaid ? 'Settled' : 'Pending: ${formatCurrency(remainingAmount)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isPaid ? Colors.green.shade600 : Colors.blueGrey.shade600,
                                  fontWeight: isPaid ? FontWeight.w700 : FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!isPaid)
                      ElevatedButton(
                        onPressed: _showPayDialog,
                        style: ElevatedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          backgroundColor: mainColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          minimumSize: const Size(0, 36),
                        ),
                        child: Text(buttonText),
                      )
                    else
                      Icon(Icons.check_circle, color: Colors.green.shade600, size: 24),
                  ],
                ),
              ),
              if (_isExpanded) ...[
                const Divider(indent: 12, endIndent: 12),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildDetailItem('Total', formatCurrency(widget.debt.amount)),
                          _buildDetailItem('Paid', formatCurrency(widget.debt.paidAmount)),
                          _buildDetailItem('Due', settings.formatStoredDate(widget.debt.dueDate ?? 'N/A')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _openUpdatePage,
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                backgroundColor: const Color.fromARGB(255, 235, 136, 7).withValues(alpha: 0.08),
                              ),
                              child: const Text('Update'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _openDetailsPage,
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                backgroundColor: const Color.fromARGB(255, 230, 94, 94).withValues(alpha: 0.08),
                              ),
                              child: const Text('Details'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            onPressed: () async {
                              final confirmDelete = await _showDeleteConfirmation();
                              if (confirmDelete == true) {
                                widget.onDelete();
                              }
                            },
                            icon: const Icon(Icons.delete_outline, size: 20),
                            style: IconButton.styleFrom(
                              foregroundColor: Colors.red,
                              backgroundColor: Colors.red.withValues(alpha: 0.1),
                            ),
                          ),
                        ],
                      ),
                      if (!isPaid) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _showAddMoreDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: mainColor,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(isBorrow ? 'Borrow More' : 'Lend More'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.blueGrey.shade500,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.blueGrey,
          ),
        ),
      ],
    );
  }
}
