import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_settings_provider.dart';
import '../models/debt_model1.dart';
import '../providers/debt_provider.dart';

class AddPaymentScreen extends StatefulWidget {
  final DebtModel debt;

  const AddPaymentScreen({super.key, required this.debt});

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  bool _isLoading = false;
  late double _remainingAmount;

  @override
  void initState() {
    super.initState();
    _remainingAmount = widget.debt.amount - widget.debt.paidAmount;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String formatCurrency(double amount) {
    return context.read<AppSettingsProvider>().formatCurrency(amount);
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final payAmount = double.parse(_amountController.text);
    final provider = context.read<DebtProvider>();

    try {
      await provider.addPayment(
        widget.debt.id!,
        payAmount,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        date: _selectedDate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment of ${formatCurrency(payAmount)} recorded',
            ),
            backgroundColor: Colors.green.shade600,
          ),
        );
        Navigator.of(context).pop(); // Rudi nyuma
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isBorrow = widget.debt.type == 'borrow';
    Color mainColor = isBorrow ? Colors.red.shade600 : Colors.green.shade600;
    String actionText = isBorrow ? 'Pay' : 'Collect';

    return Scaffold(
      appBar: AppBar(
        title: Text('$actionText Payment'),
        backgroundColor: mainColor,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: mainColor.withValues(alpha: 0.1),
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
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                isBorrow
                                    ? 'You owe this person'
                                    : 'This person owes you',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildDetailRow(
                      'Total Amount',
                      formatCurrency(widget.debt.amount),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Already Paid',
                      formatCurrency(widget.debt.paidAmount),
                      Colors.green.shade700,
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Remaining',
                      formatCurrency(_remainingAmount),
                      Colors.red.shade600,
                      true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$actionText Amount',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      decoration: InputDecoration(
                        hintText: 'Enter amount',
                        prefixText: context.read<AppSettingsProvider>().currencySymbol,
                        suffixIcon: TextButton(
                          onPressed: () {
                            _amountController.text = _remainingAmount
                                .toStringAsFixed(0);
                          },
                          child: const Text('Pay All'),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter amount';
                        }
                        final amount = double.tryParse(value);
                        if (amount == null || amount <= 0) {
                          return 'Enter valid amount';
                        }
                        if (amount > _remainingAmount) {
                          return 'Amount exceeds remaining ${formatCurrency(_remainingAmount)}';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Transaction Date',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.calendar_today, color: mainColor),
                      title: Text(
                        context.read<AppSettingsProvider>().formatDate(_selectedDate),
                      ),
                      trailing: const Icon(Icons.edit, size: 16),
                      onTap: _selectDate,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Note (Optional)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _noteController,
                      maxLines: 3,
                      decoration: InputDecoration(hintText: 'Add a note...'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        '$actionText ${formatCurrency(double.tryParse(_amountController.text) ?? 0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, [
    Color? color,
    bool isBold = false,
  ]) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade700)),
        Text(
          '$value TSh',
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: color ?? Colors.black,
            fontSize: isBold ? 16 : 14,
          ),
        ),
      ],
    );
  }
}
