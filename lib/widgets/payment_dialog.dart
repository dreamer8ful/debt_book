import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/debt_model1.dart';
import 'package:intl/intl.dart';

class PaymentDialog extends StatefulWidget {
  final DebtModel debt;
  
  const PaymentDialog({super.key, required this.debt});

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _payController = TextEditingController();
  
  String formatCurrency(double amount) {
    return NumberFormat('#,##0', 'en_US').format(amount);
  }

  @override
  void dispose() {
    _payController.dispose(); // 👈 Sasa iko safe 100%
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.debt.amount - widget.debt.paidAmount;
    final isLend = widget.debt.type == 'lend';

    return AlertDialog(
      title: Text('${isLend ? 'Collect from' : 'Pay'} ${widget.debt.name}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Remaining:', style: TextStyle(fontSize: 14)),
                  Text(
                    '${formatCurrency(remaining)} TSh',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _payController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'Amount to ${isLend ? 'Collect' : 'Pay'}',
                border: const OutlineInputBorder(),
                prefixText: 'TSh ',
                suffixIcon: TextButton(
                  onPressed: () {
                    _payController.text = remaining.toStringAsFixed(0);
                    setState(() {});
                  },
                  child: const Text('All'),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Enter amount';
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) return 'Invalid amount';
                if (amount > remaining) return 'Exceeds ${formatCurrency(remaining)}';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), // 👈 Tumia context ya dialog
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            
            final payAmount = double.parse(_payController.text);
            
            // Rudi na value badala ya kufanya kazi hapa
            Navigator.pop(context, payAmount); // 👈 Rudisha amount
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isLend ? Colors.green.shade600 : const Color.fromARGB(255, 6, 138, 13),
          ),
          child: Text(
            isLend ? 'Confirm Collect' : 'Confirm Pay',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}