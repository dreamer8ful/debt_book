import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
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
  final _imagePicker = ImagePicker();

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final amountController = TextEditingController();
  final descController = TextEditingController();
  final interestController = TextEditingController();

  DateTime selectedDate = DateTime.now();
  DateTime? dueDate;
  bool hasDueDate = false;
  bool hasInterest = false;
  String? _photoPath;

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
      initialDate: isDueDate
          ? DateTime.now().add(const Duration(days: 30))
          : selectedDate,
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

  Future<void> _pickFromContacts() async {
    final permission = await FlutterContacts.permissions.request(PermissionType.read);
    if (!mounted) return;

    if (permission != PermissionStatus.granted && permission != PermissionStatus.limited) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contacts permission is required to pick a person'),
        ),
      );
      return;
    }

    final contact = await FlutterContacts.native.showPicker(
      properties: {ContactProperty.name, ContactProperty.phone},
    );

    if (!mounted || contact == null) return;

    setState(() {
      nameController.text = contact.displayName ?? contact.name?.first ?? nameController.text;
      if (contact.phones.isNotEmpty) {
        phoneController.text = contact.phones.first.number;
      }
    });
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
      requestFullMetadata: false,
    );
    if (picked == null || !mounted) return;

    final documentsDir = await getApplicationDocumentsDirectory();
    final fileName =
        'debt_${DateTime.now().millisecondsSinceEpoch}_${p.basename(picked.path)}';
    final savedPath = p.join(documentsDir.path, fileName);
    final savedFile = await File(picked.path).copy(savedPath);

    if (!mounted) return;
    setState(() {
      _photoPath = savedFile.path;
    });
  }

  Future<void> _showPhotoOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose invoice/receipt from gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickPhoto(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Capture invoice/receipt photo'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickPhoto(ImageSource.camera);
                },
              ),
              if (_photoPath != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Remove attachment'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _photoPath = null);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _saveTransaction() {
    if (_formKey.currentState!.validate()) {
      final debt = DebtModel(
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        type: widget.type,
        amount: double.parse(amountController.text),
        dateBorrowed: DateFormat('dd-MM-yyyy').format(selectedDate),
        dueDate: hasDueDate && dueDate != null
            ? DateFormat('dd-MM-yyyy').format(dueDate!)
            : null,
        description: descController.text.trim().isEmpty
            ? null
            : descController.text.trim(),
        photoPath: _photoPath,
      );

      Provider.of<DebtProvider>(context, listen: false).addDebt(debt);
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.type == 'lend' ? 'Lend' : 'Borrow'} added successfully',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLend = widget.type == 'lend';
    final mainColor = isLend ? Colors.red.shade600 : Colors.green.shade600;
    final title = isLend ? 'Add Lend' : 'Add Borrow';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: mainColor,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select a contact or add one manually',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _pickFromContacts,
                        icon: const Icon(Icons.contacts_outlined),
                        label: const Text('From Contacts'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Person Name *',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number *',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter phone';
                          }
                          return null;
                        },
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
                    children: [
                      TextFormField(
                        controller: amountController,
                        decoration: const InputDecoration(
                          labelText: 'Amount *',
                          prefixText: 'TSh ',
                          prefixIcon: Icon(Icons.payments_outlined),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter amount';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.calendar_today, color: mainColor),
                        title: const Text('Date Borrowed'),
                        subtitle: Text(
                          DateFormat('dd MMM yyyy').format(selectedDate),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _selectDate(context, false),
                      ),
                      const Divider(),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Set Due Date'),
                        value: hasDueDate,
                        activeThumbColor: mainColor,
                        onChanged: (value) {
                          setState(() {
                            hasDueDate = value;
                            if (value && dueDate == null) {
                              dueDate = DateTime.now().add(
                                const Duration(days: 30),
                              );
                            }
                          });
                        },
                      ),
                      if (hasDueDate) ...[
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.event,
                            color: Colors.orange.shade700,
                          ),
                          title: const Text('Due Date'),
                          subtitle: Text(
                            dueDate != null
                                ? DateFormat('dd MMM yyyy').format(dueDate!)
                                : 'Select date',
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () => _selectDate(context, true),
                        ),
                      ],
                      const Divider(),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Add Interest'),
                        value: hasInterest,
                        activeThumbColor: mainColor,
                        onChanged: (value) =>
                            setState(() => hasInterest = value),
                      ),
                      if (hasInterest)
                        TextFormField(
                          controller: interestController,
                          decoration: const InputDecoration(
                            labelText: 'Interest %',
                            suffixText: '%',
                            prefixIcon: Icon(Icons.percent),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: descController,
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.notes_outlined),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Attachment (invoice/receipt)',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: _showPhotoOptions,
                          icon: const Icon(Icons.attach_file),
                          label: const Text('Attach Invoice or Receipt'),
                        ),
                      ),
                      if (_photoPath != null && File(_photoPath!).existsSync()) ...[
                        const SizedBox(height: 12),
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 260,
                            maxHeight: 340,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(_photoPath!),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
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