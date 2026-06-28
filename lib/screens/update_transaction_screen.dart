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

class UpdateTransactionScreen extends StatefulWidget {
  final DebtModel debt;

  const UpdateTransactionScreen({super.key, required this.debt});

  @override
  State<UpdateTransactionScreen> createState() =>
      _UpdateTransactionScreenState();
}

class _UpdateTransactionScreenState extends State<UpdateTransactionScreen> {
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
  void initState() {
    super.initState();
    nameController.text = widget.debt.name;
    phoneController.text = widget.debt.phone ?? '';
    amountController.text = widget.debt.amount.toStringAsFixed(0);
    descController.text = widget.debt.description ?? '';
    _photoPath = widget.debt.photoPath;
    hasDueDate = widget.debt.dueDate != null;
    selectedDate = _parseDate(widget.debt.dateBorrowed) ?? DateTime.now();
    dueDate = widget.debt.dueDate == null
        ? null
        : _parseDate(widget.debt.dueDate!);
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

  DateTime? _parseDate(String value) {
    try {
      return DateFormat('dd-MM-yyyy').parseStrict(value);
    } catch (_) {
      return null;
    }
  }

  Future<void> _selectDate(BuildContext context, bool isDueDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isDueDate
          ? dueDate ?? DateTime.now().add(const Duration(days: 30))
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
    final permission = await FlutterContacts.permissions.request(
      PermissionType.read,
    );
    if (!mounted) return;

    if (permission != PermissionStatus.granted &&
        permission != PermissionStatus.limited) {
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

  void _updateTransaction() {
    if (_formKey.currentState!.validate()) {
      final newAmount = double.parse(amountController.text);
      if (newAmount < widget.debt.paidAmount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Amount cannot be less than paid: ${widget.debt.paidAmount.toStringAsFixed(0)} TSh',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final updatedDebt = DebtModel(
        id: widget.debt.id,
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        type: widget.debt.type,
        amount: newAmount,
        paidAmount: widget.debt.paidAmount,
        dateBorrowed: DateFormat('dd-MM-yyyy').format(selectedDate),
        dueDate: hasDueDate && dueDate != null
            ? DateFormat('dd-MM-yyyy').format(dueDate!)
            : null,
        description: descController.text.trim().isEmpty
            ? null
            : descController.text.trim(),
        photoPath: _photoPath,
      );

      Provider.of<DebtProvider>(context, listen: false).updateDebt(updatedDebt);
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debt updated successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLend = widget.debt.type == 'lend';
    final mainColor = isLend ? Colors.red.shade600 : Colors.green.shade600;
    final title = isLend ? 'Update Lend' : 'Update Borrow';
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
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 88),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _animatedEntry(
                delayMs: 0,
                child: _sectionHeader(
                  icon: Icons.person_outline,
                  title: 'Person',
                  subtitle: 'Update the participant information',
                ),
              ),
              const SizedBox(height: 8),
              _animatedEntry(
                delayMs: 45,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
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
                        label: const Text('Choose Contact'),
                        style: _compactButtonStyle(),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nameController,
                        textInputAction: TextInputAction.next,
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
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: phoneController,
                        textInputAction: TextInputAction.next,
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
              ),
              const SizedBox(height: 14),
              _animatedEntry(
                delayMs: 85,
                child: _sectionHeader(
                  icon: Icons.request_quote_outlined,
                  title: 'Transaction',
                  subtitle: 'Adjust amount, dates, and details',
                ),
              ),
              const SizedBox(height: 8),
              _animatedEntry(
                delayMs: 130,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                      TextFormField(
                        controller: amountController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Amount *',
                          prefixText: settings.currencySymbol,
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
                      const SizedBox(height: 12),
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.calendar_today, color: mainColor),
                        title: const Text('Date Borrowed'),
                        subtitle: Text(
                          settings.formatDate(selectedDate),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _selectDate(context, false),
                      ),
                      const Divider(height: 14),
                      SwitchListTile(
                        dense: true,
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
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.event,
                            color: Colors.orange.shade700,
                          ),
                          title: const Text('Due Date'),
                          subtitle: Text(
                            dueDate != null
                                ? settings.formatDate(dueDate!)
                                : 'Select date',
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () => _selectDate(context, true),
                        ),
                      ],
                      const Divider(height: 14),
                      SwitchListTile(
                        dense: true,
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
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Interest %',
                            suffixText: '%',
                            prefixIcon: Icon(Icons.percent),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descController,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _updateTransaction(),
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.notes_outlined),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 14),
                      const SizedBox(height: 6),
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
                          label: const Text('Attach Receipt / Invoice'),
                          style: _compactButtonStyle(),
                        ),
                      ),
                      if (_photoPath != null && File(_photoPath!).existsSync()) ...[
                        const SizedBox(height: 10),
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 240,
                            maxHeight: 300,
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
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _updateTransaction,
        backgroundColor: mainColor,
        icon: const Icon(Icons.check, color: Colors.white),
        label: const Text('Update Transaction', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  ButtonStyle _compactButtonStyle() {
    return OutlinedButton.styleFrom(
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.padded,
      minimumSize: const Size(0, 40),
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

  Widget _animatedEntry({
    required Widget child,
    required int delayMs,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 220 + delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, value, animatedChild) {
        final offsetY = (1 - value) * 10;
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, offsetY),
            child: animatedChild,
          ),
        );
      },
      child: child,
    );
  }
}