// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/debt_provider.dart';
import '../models/debt_model1.dart';
import '../widgets/payment_dialog.dart';

class DebtPersonCard extends StatefulWidget {
  final DebtModel debt;
  final VoidCallback onDelete;

  const DebtPersonCard({
    super.key,
    required this.debt,
    required this.onDelete,
  });

  @override
  State<DebtPersonCard> createState() => _DebtPersonCardState();
}

class _DebtPersonCardState extends State<DebtPersonCard> {
  bool _isExpanded = false;

  String formatCurrency(double amount) {
    return '${NumberFormat('#,##0', 'en_US').format(amount)} TSh';
  }

  void _showPayDialog() async {
    final result = await showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentDialog(debt: widget.debt),
    );

    if (result == null || !mounted) return;

    try {
      await context.read<DebtProvider>().addPayment(widget.debt.id!, result);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.debt.type == 'lend' ? 'Collected' : 'Paid'} ${formatCurrency(result)} TSh'),
          backgroundColor: Colors.green.shade600,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  void _showAddMoreDialog() {
    final moreController = TextEditingController();
    bool isBorrow = widget.debt.type == 'borrow';
    String actionText = isBorrow ? 'Borrow more from' : 'Lend more to';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$actionText ${widget.debt.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current remaining: ${formatCurrency(widget.debt.amount - widget.debt.paidAmount)}', 
                 style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: moreController,
              decoration: InputDecoration(
                labelText: 'Additional Amount',
                border: const OutlineInputBorder(),
                prefixText: 'TSh ',
                hintText: isBorrow ? 'Borrow more' : 'Lend more',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              double moreAmount = double.tryParse(moreController.text) ?? 0;
              if (moreAmount > 0) {
                Provider.of<DebtProvider>(context, listen: false).addMoreDebt(widget.debt.id!, moreAmount);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Added ${formatCurrency(moreAmount)}')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid amount'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
            child: Text('Confirm ${isBorrow ? 'Borrow' : 'Lend'}', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<bool> _showDeleteConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: Text('Are you sure you want to delete ${widget.debt.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showUpdateDialog() {
    final nameController = TextEditingController(text: widget.debt.name);
    final amountController = TextEditingController(text: widget.debt.amount.toStringAsFixed(0));
    final dateController = TextEditingController(text: widget.debt.dateBorrowed);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update ${widget.debt.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: 'Total Amount',
                  border: const OutlineInputBorder(),
                  prefixText: 'TSh ',
                  helperText: 'Paid: ${formatCurrency(widget.debt.paidAmount)}',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dateController,
                decoration: const InputDecoration(
                  labelText: 'Date Borrowed',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                  hintText: 'DD-MM-YYYY',
                ),
                readOnly: true,
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    dateController.text = DateFormat('dd-MM-yyyy').format(picked);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              double newAmount = double.tryParse(amountController.text) ?? widget.debt.amount;
              
              if (newAmount < widget.debt.paidAmount) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Amount cannot be less than paid: ${formatCurrency(widget.debt.paidAmount)}'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (nameController.text.isNotEmpty && newAmount > 0) {
                final updatedDebt = DebtModel(
                  id: widget.debt.id,
                  name: nameController.text,
                  phone: widget.debt.phone,
                  description: widget.debt.description,
                  amount: newAmount,
                  paidAmount: widget.debt.paidAmount,
                  dateBorrowed: dateController.text,
                  type: widget.debt.type,
                );
                
                Provider.of<DebtProvider>(context, listen: false).updateDebt(updatedDebt);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Debt updated successfully')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600),
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDetailsDialog() {
    bool isBorrow = widget.debt.type == 'borrow';
    final remaining = widget.debt.amount - widget.debt.paidAmount;
    final percentPaid = widget.debt.amount > 0 ? (widget.debt.paidAmount / widget.debt.amount * 100) : 0;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade700, size: 28),
            const SizedBox(width: 8),
            const Text('Debt Details'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isBorrow ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: isBorrow ? Colors.green.shade100 : Colors.red.shade100,
                      child: Icon(Icons.person, color: isBorrow ? Colors.green.shade700 : Colors.red.shade700),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.debt.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          Text(
                            isBorrow ? 'Creditor' : 'Debtor',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              Text('Payment Progress', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: percentPaid / 100,
                  minHeight: 10,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
                ),
              ),
              const SizedBox(height: 4),
              Text('${percentPaid.toStringAsFixed(1)}% Paid', style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 16),
              
              _buildDetailRow('Type:', isBorrow ? 'Borrowed' : 'Lent', isBorrow ? Colors.green : Colors.red),
              const Divider(height: 20),
              _buildDetailRow('Total Amount:', formatCurrency(widget.debt.amount), Colors.black87),
              const Divider(height: 20),
              _buildDetailRow('Amount Paid:', formatCurrency(widget.debt.paidAmount), Colors.green.shade700),
              const Divider(height: 20),
              _buildDetailRow('Remaining:', formatCurrency(remaining), Colors.red.shade700, isBold: true),
              const Divider(height: 20),
              _buildDetailRow('Date Borrowed:', widget.debt.dateBorrowed, Colors.black87),
              const Divider(height: 20),
              _buildDetailRow('Status:', remaining <= 0 ? 'Fully Paid' : 'Pending', 
                             remaining <= 0 ? Colors.green : Colors.orange.shade700),
              
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.history, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Payment history coming soon',
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color valueColor, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
        Text(
          value, 
          style: TextStyle(
            color: valueColor, 
            fontSize: 14, 
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600
          ),
        ),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    bool isBorrow = widget.debt.type == 'borrow';
    Color mainColor = isBorrow ? Colors.green.shade600 : Colors.red.shade600;
    final remainingAmount = widget.debt.amount - widget.debt.paidAmount;
    final buttonText = widget.debt.type == 'lend' ? 'Collect' : 'Pay';
    final isPaid = remainingAmount <= 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: _isExpanded ? mainColor : Colors.transparent, width: 1.5),
      ),
      child: Column(
        children: [
          // DEFAULT VIEW - Collapsed
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Container(width: 4, height: 50, color: mainColor),
                  const SizedBox(width: 12),
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
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 15),
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
                                fontSize: 13,
                                decoration: isPaid ? TextDecoration.lineThrough : null,
                                color: isPaid ? Colors.grey : null,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Since ${widget.debt.dateBorrowed}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text(buttonText),
                    ),
                  if (!_isExpanded && isPaid)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 16, color: Colors.green.shade700),
                          const SizedBox(width: 4),
                          Text(
                            'PAID',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // EXPANDED VIEW
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  // Row 1: Delete button only
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          bool? confirmDelete = await _showDeleteConfirmation();
                          if (confirmDelete == true) {
                            widget.onDelete();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${widget.debt.name} deleted'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                        label: const Text('Delete', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Row 2: Details za Amount
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
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 15),
                            ),
                            const SizedBox(height: 8),
                            Row(children: [
                              Icon(Icons.arrow_circle_down, size: 16, color: Colors.red.shade400),
                              const SizedBox(width: 4),
                              Text('Remaining ${formatCurrency(remainingAmount)}', 
                                   style: TextStyle(
                                     fontSize: 13,
                                     decoration: isPaid ? TextDecoration.lineThrough : null,
                                     color: isPaid ? Colors.grey : null,
                                   )),
                            ]),
                            const SizedBox(height: 4),
                            Row(children: [
                              Icon(Icons.arrow_circle_up, size: 16, color: Colors.green.shade400),
                              const SizedBox(width: 4),
                              Text('Paid ${formatCurrency(widget.debt.paidAmount)}', 
                                   style: TextStyle(color: Colors.green.shade700, fontSize: 13)),
                            ]),
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
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                              ),
                              child: Text(isBorrow ? 'Borrow more' : 'Lend more'),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _showPayDialog,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      'Since ${widget.debt.dateBorrowed}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Row 3: Update + Details
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _showUpdateDialog,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.green.shade600),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: Text('Update', style: TextStyle(color: Colors.green.shade700)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showDetailsDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
    );
  }
}