import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../models/debt_model1.dart';
import '../providers/app_settings_provider.dart';
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

  double? _parseAmount(String value) {
    return double.tryParse(value.trim());
  }

  double? _parseInterestPercent() {
    if (!hasInterest) return 0;
    return double.tryParse(interestController.text.trim());
  }

  double? _calculateTotalAmount() {
    final principalAmount = _parseAmount(amountController.text);
    if (principalAmount == null) return null;

    final interestPercent = _parseInterestPercent();
    if (interestPercent == null) return null;

    return principalAmount + ((principalAmount * interestPercent) / 100);
  }

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
              const SizedBox(height: 4),
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 2, 18, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Attachment Options',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ),
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose invoice/receipt from gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickPhoto(ImageSource.gallery);
                },
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Capture invoice/receipt photo'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickPhoto(ImageSource.camera);
                },
              ),
              if (_photoPath != null)
                ListTile(
                  dense: true,
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
      final totalAmount = _calculateTotalAmount();
      if (totalAmount == null) {
        return;
      }

      final debt = DebtModel(
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        type: widget.type,
        amount: totalAmount,
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
    final settings = context.watch<AppSettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
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
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(
                icon: Icons.person_outline,
                title: 'Contact Information',
                subtitle: 'Select or enter the person involved',
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: nameController,
                              decoration: const InputDecoration(
                                labelText: 'Name',
                                prefixIcon: Icon(Icons.person_outline, size: 20),
                              ),
                              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            onPressed: _pickFromContacts,
                            icon: const Icon(Icons.contacts_outlined, size: 20),
                            tooltip: 'Contacts',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          prefixIcon: Icon(Icons.phone_outlined, size: 20),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _sectionHeader(
                icon: Icons.receipt_long_outlined,
                title: 'Transaction Details',
                subtitle: 'Set amount and dates',
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: amountController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          prefixText: '${settings.currencySymbol} ',
                          prefixIcon: const Icon(Icons.payments_outlined, size: 20),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (double.tryParse(value) == null) return 'Invalid';
                          return null;
                        },
                      ),
                      const Divider(),
                      SwitchListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        title: const Text('Add Interest'),
                        value: hasInterest,
                        activeThumbColor: mainColor,
                        onChanged: (value) {
                          setState(() {
                            hasInterest = value;
                            if (!value) {
                              interestController.clear();
                            }
                          });
                        },
                      ),
                      if (hasInterest) ...[
                        TextFormField(
                          controller: interestController,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Interest %',
                            suffixText: '%',
                            prefixIcon: Icon(Icons.percent, size: 20),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (!hasInterest) return null;
                            if (value == null || value.trim().isEmpty) {
                              return 'Required';
                            }
                            final interestPercent = double.tryParse(value.trim());
                            if (interestPercent == null) return 'Invalid';
                            if (interestPercent < 0) return 'Must be 0 or more';
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _buildTotalPreview(settings.currencySymbol),
                            style: TextStyle(
                              color: Colors.blueGrey.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        leading: Icon(Icons.calendar_today, color: mainColor, size: 20),
                        title: const Text('Transaction Date'),
                        subtitle: Text(settings.formatDate(selectedDate)),
                        onTap: () => _selectDate(context, false),
                      ),
                      const Divider(),
                      SwitchListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        title: const Text('Set Due Date'),
                        value: hasDueDate,
                        onChanged: (value) => setState(() => hasDueDate = value),
                      ),
                      if (hasDueDate)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          leading: const Icon(Icons.event, color: Colors.orange, size: 20),
                          title: const Text('Due Date'),
                          subtitle: Text(dueDate != null ? settings.formatDate(dueDate!) : 'Select Date'),
                          onTap: () => _selectDate(context, true),
                        ),
                      const Divider(),
                      TextFormField(
                        controller: descController,
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                          prefixIcon: Icon(Icons.notes_outlined, size: 20),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _sectionHeader(
                icon: Icons.attach_file,
                title: 'Attachments',
                subtitle: 'Invoice or receipt photo',
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _showPhotoOptions,
                icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                label: Text(_photoPath == null ? 'Add Receipt' : 'Change Receipt'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
              if (_photoPath != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_photoPath!),
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveTransaction,
        backgroundColor: mainColor,
        icon: const Icon(Icons.check, color: Colors.white),
        label: const Text('Save Transaction', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blueGrey.shade700),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.blueGrey.shade800,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.blueGrey.shade500,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _buildTotalPreview(String currencySymbol) {
    final totalAmount = _calculateTotalAmount();
    if (totalAmount == null) {
      return 'Enter amount and interest to calculate total';
    }
    return 'Total with interest: $currencySymbol${totalAmount.toStringAsFixed(0)}';
  }
}
