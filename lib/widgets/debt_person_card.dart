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
    final result = await showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentDialog(debt: widget.debt),
    );

    if (result == null || !mounted) return;

    try {
      await context.read<DebtProvider>().addPayment(widget.debt.id!, result);

      if (!mounted) return;
      _showFeedback(
        '${widget.debt.type == 'lend' ? 'Collected' : 'Paid'} ${formatCurrency(result)}',
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
    final transactionPeriod =
      'Since ${settings.formatStoredDate(widget.debt.dateBorrowed)} --> ${widget.debt.dueDate == null ? 'undefined' : settings.formatStoredDate(widget.debt.dueDate!)}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      elevation: _isExpanded ? 5 : 2,
      shadowColor: mainColor.withValues(alpha: 0.14),
      clipBehavior: Clip.antiAlias,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: _isExpanded
              ? mainColor.withValues(alpha: 0.35)
              : Colors.transparent,
          width: 1.25,
        ),
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: Column(
          children: [
            InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 5,
                    height: 52,
                    decoration: BoxDecoration(
                      color: mainColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: mainColor.withValues(alpha: 0.12),
                    child: Icon(Icons.person, color: mainColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.debt.name} ${isBorrow ? '(Creditor)' : '(Debtor)'}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade900,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              isPaid ? Icons.check_circle : Icons.pending,
                              size: 14,
                              color: isPaid ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${isBorrow ? 'Borrow' : 'Lend'} ${formatCurrency(remainingAmount)}',
                              style: TextStyle(
                                fontSize: 12,
                                decoration: isPaid
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: isPaid ? Colors.grey : null,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          transactionPeriod,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_isExpanded && !isPaid)
                    ElevatedButton(
                      onPressed: _showPayDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.padded,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(buttonText),
                    ),
                  if (!_isExpanded && isPaid)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'PAID',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
            if (_isExpanded) ...[
              const Divider(height: 1),
              Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          final confirmDelete = await _showDeleteConfirmation();
                          if (confirmDelete == true) {
                            widget.onDelete();
                            if (mounted) {
                              _showFeedback(
                                '${widget.debt.name} deleted',
                                backgroundColor: Colors.red,
                              );
                            }
                          }
                        },
                        icon: const Icon(
                          Icons.delete,
                          size: 16,
                          color: Colors.red,
                        ),
                        label: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.padded,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: mainColor.withValues(alpha: 0.1),
                        child: Icon(Icons.person, color: mainColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.debt.name} ${isBorrow ? '(Creditor)' : '(Debtor)'}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade900,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${isBorrow ? 'Total Borrow' : 'Total Lend'} ${formatCurrency(widget.debt.amount)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.arrow_circle_down,
                                  size: 16,
                                  color: Colors.red.shade400,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Remaining ${formatCurrency(remainingAmount)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    decoration: isPaid
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: isPaid ? Colors.grey : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.arrow_circle_up,
                                  size: 16,
                                  color: Colors.green.shade400,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Paid ${formatCurrency(widget.debt.paidAmount)}',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (!isPaid)
                        Column(
                          children: [
                            ElevatedButton(
                              onPressed: _showAddMoreDialog,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                foregroundColor: Colors.white,
                                visualDensity: VisualDensity.compact,
                                tapTargetSize: MaterialTapTargetSize.padded,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                              ),
                              child: Text(
                                isBorrow ? 'Borrow more' : 'Lend more',
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _showPayDialog,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                foregroundColor: Colors.white,
                                visualDensity: VisualDensity.compact,
                                tapTargetSize: MaterialTapTargetSize.padded,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                              ),
                              child: Text(buttonText),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      transactionPeriod,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _openUpdatePage,
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            tapTargetSize: MaterialTapTargetSize.padded,
                            side: BorderSide(color: Colors.green.shade600),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            'Update',
                            style: TextStyle(color: Colors.green.shade700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _openDetailsPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            visualDensity: VisualDensity.compact,
                            tapTargetSize: MaterialTapTargetSize.padded,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          icon: const Icon(Icons.info_outline, size: 18),
                          label: const Text('Details'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
