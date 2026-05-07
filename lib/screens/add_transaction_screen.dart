import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/debt_model1.dart';
import '../providers/debt_provider.dart';

class AddTransactionScreen extends StatefulWidget {
  final String type; // 'lend' au 'borrow'

  const AddTransactionScreen({super.key, required this.type});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final amountController = TextEditingController();
  final descController = TextEditingController();
  final interestController = TextEditingController();

  DateTime selectedDate = DateTime.now();
  DateTime? dueDate;
  bool hasDueDate = false;
  bool hasInterest = false;

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    amountController.dispose();
    descController.dispose();
    interestController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isDueDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isDueDate? DateTime.now().add(const Duration(days: 30)) : selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isDueDate) {
          dueDate = picked;
        } else {
          selectedDate = picked;
        }
      });
    }
  }

  void _saveTransaction() {
    if (_formKey.currentState!.validate()) {
      final debt = DebtModel(
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        type: widget.type,
        amount: double.parse(amountController.text),
        dateBorrowed: DateFormat('dd-MM-yyyy').format(selectedDate),
        dueDate: hasDueDate && dueDate != null? DateFormat('dd-MM-yyyy').format(dueDate!) : null,
        description: descController.text.trim().isEmpty? null : descController.text.trim(),
      );

      Provider.of<DebtProvider>(context, listen: false).addDebt(debt);
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.type == 'lend'? 'Lend' : 'Borrow'} added successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isLend = widget.type == 'lend';
    Color mainColor = isLend? Colors.red.shade600 : Colors.green.shade600;
    String title = isLend? 'Add Lend' : 'Add Borrow';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: mainColor,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo + Name + Phone
              Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: mainColor.withValues(alpha: 0.2),
                        child: Icon(Icons.person, size: 40, color: mainColor),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: mainColor,
                          child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Person Name *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) => value!.isEmpty? 'Enter name' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number *',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) => value!.isEmpty? 'Enter phone' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Amount
              TextFormField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: 'Amount *',
                  border: const OutlineInputBorder(),
                  prefixText: 'TSh ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'Enter amount';
                  if (double.tryParse(value) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date Borrowed
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.calendar_today, color: mainColor),
                title: const Text('Date Borrowed'),
                subtitle: Text(DateFormat('dd MMM yyyy').format(selectedDate)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _selectDate(context, false),
              ),
              const Divider(),

              // Due Date Toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Set Due Date'),
                value: hasDueDate,
                activeThumbColor: mainColor,
                onChanged: (value) {
                  setState(() {
                    hasDueDate = value;
                    if (value && dueDate == null) {
                      dueDate = DateTime.now().add(const Duration(days: 30));
                    }
                  });
                },
              ),
              if (hasDueDate)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.event, color: Colors.orange.shade700),
                  title: const Text('Due Date'),
                  subtitle: Text(dueDate != null? DateFormat('dd MMM yyyy').format(dueDate!) : 'Select date'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _selectDate(context, true),
                ),
              const Divider(),

              // Interest Toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Add Interest'),
                value: hasInterest,
                activeThumbColor: mainColor,
                onChanged: (value) => setState(() => hasInterest = value),
              ),
              if (hasInterest)
                TextFormField(
                  controller: interestController,
                  decoration: const InputDecoration(
                    labelText: 'Interest %',
                    border: OutlineInputBorder(),
                    suffixText: '%',
                  ),
                  keyboardType: TextInputType.number,
                ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveTransaction,
        backgroundColor: mainColor,
        icon: const Icon(Icons.check, color: Colors.white),
        label: const Text('Save', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}