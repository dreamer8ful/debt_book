import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/debt_model1.dart';
import '../providers/app_settings_provider.dart';

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
    return context.read<AppSettingsProvider>().formatCurrency(amount);
  }

  @override
  void dispose() {
    _payController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.debt.amount - widget.debt.paidAmount;
    final isLend = widget.debt.type == 'lend';
    final accent = isLend ? Colors.green.shade700 : Colors.blue.shade700;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
      contentPadding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
      actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      title: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: accent.withValues(alpha: 0.12),
            child: Icon(
              isLend ? Icons.south_west_rounded : Icons.north_east_rounded,
              size: 16,
              color: accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${isLend ? 'Collect from' : 'Pay'} ${widget.debt.name}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withValues(alpha: 0.15)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Remaining',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    formatCurrency(remaining),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _payController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'Amount to ${isLend ? 'Collect' : 'Pay'}',
                prefixText: context.read<AppSettingsProvider>().currencySymbol,
                prefixIcon: Icon(Icons.payments_outlined, color: accent),
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
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            
            final payAmount = double.parse(_payController.text);
            
            Navigator.pop(context, payAmount);
          },
          style: ElevatedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            backgroundColor: accent,
          ),
          child: Text(
            'Confirm',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}