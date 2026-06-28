import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import '../providers/debt_provider.dart';
import '../providers/app_settings_provider.dart';
import '../services/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _enableLock = false;
  bool _lockStateInitialized = false;

  static final _currencyOptions = [
    {'label': 'Tanzanian Shilling (TSh)', 'code': 'TZS', 'symbol': 'TSh '},
    {'label': 'US Dollar (\$)', 'code': 'USD', 'symbol': '\$'},
    {'label': 'Euro (€)', 'code': 'EUR', 'symbol': '€'},
    {'label': 'British Pound (£)', 'code': 'GBP', 'symbol': '£'},
    {'label': 'Kenyan Shilling (KSh)', 'code': 'KES', 'symbol': 'KSh '},
    {'label': 'Ugandan Shilling (USh)', 'code': 'UGX', 'symbol': 'USh '},
    {'label': 'South African Rand (R)', 'code': 'ZAR', 'symbol': 'R'},
    {'label': 'Japanese Yen (¥)', 'code': 'JPY', 'symbol': '¥'},
    {'label': 'Indian Rupee (₹)', 'code': 'INR', 'symbol': '₹'},
  ];

  static final _dateFormats = [
    {'label': 'Day-Month-Year (28-06-2026)', 'pattern': 'dd-MM-yyyy'},
    {'label': 'Month-Day-Year (06-28-2026)', 'pattern': 'MM-dd-yyyy'},
    {'label': 'Year-Month-Day (2026-06-28)', 'pattern': 'yyyy-MM-dd'},
    {'label': 'Day/Month/Year (28/06/2026)', 'pattern': 'dd/MM/yyyy'},
    {'label': 'Month day, Year (Jun 28, 2026)', 'pattern': 'MMM d, yyyy'},
  ];

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _savePasswordSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final settings = context.read<AppSettingsProvider>();

    if (!_enableLock) {
      await settings.clearPassword();
      if (!mounted) return;
      setState(() {
        _enableLock = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('App lock disabled')),
      );
      return;
    }

    await settings.setPassword(_passwordController.text.trim());
    if (!mounted) return;
    setState(() {
      _enableLock = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password saved. App locked.')),
    );
  }

  Future<void> _backupDatabase(String providerName) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final suggestedName =
          'debt_book_${providerName.toLowerCase()}_$timestamp.db';

      final directoryPath = await getDirectoryPath(
        confirmButtonText: 'Choose Folder',
      );

      if (directoryPath == null || directoryPath.isEmpty) {
        return;
      }

      final targetPath = p.join(directoryPath, suggestedName);
      final savedPath = await DatabaseHelper.instance.backupDatabaseToFile(
        targetPath,
      );

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('$providerName backup saved to $savedPath')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('$providerName backup failed: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  Future<void> _restoreDatabase(String providerName) async {
    final messenger = ScaffoldMessenger.of(context);
    final debtProvider = context.read<DebtProvider>();
    try {
      final typeGroup = XTypeGroup(
        label: 'Database backups',
        extensions: const ['db'],
      );
      final source = await openFile(
        acceptedTypeGroups: [typeGroup],
        confirmButtonText: 'Select Backup',
      );

      final sourcePath = source?.path;
      if (sourcePath == null || sourcePath.isEmpty) {
        return;
      }

      await DatabaseHelper.instance.restoreDatabaseFromFile(sourcePath);
      await debtProvider.loadAllData();

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('$providerName backup restored successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('$providerName restore failed: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
    if (settings.initialized && !_lockStateInitialized) {
      _enableLock = settings.lockEnabled;
      _lockStateInitialized = true;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF0D6B8A),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Localization'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Currency',
                      prefixIcon: Icon(Icons.payments_outlined, size: 20),
                    ),
                    initialValue: settings.currencyCode,
                    items: _currencyOptions.map((opt) => DropdownMenuItem(
                      value: opt['code'] as String,
                      child: Text(opt['label'] as String),
                    )).toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      final selected = _currencyOptions.firstWhere((o) => o['code'] == val);
                      context.read<AppSettingsProvider>().setCurrency(
                        code: selected['code'] as String,
                        symbol: selected['symbol'] as String,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Date Format',
                      prefixIcon: Icon(Icons.calendar_today_outlined, size: 20),
                    ),
                    initialValue: settings.dateFormatPattern,
                    items: _dateFormats.map((opt) => DropdownMenuItem(
                      value: opt['pattern'] as String,
                      child: Text(opt['label'] as String),
                    )).toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      context.read<AppSettingsProvider>().setDateFormat(val);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader('Security'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enable App Lock', style: TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: const Text('Require password to open app'),
                      value: _enableLock,
                      onChanged: (value) async {
                        setState(() => _enableLock = value);
                        if (!value && settings.hasPassword) {
                          await context.read<AppSettingsProvider>().clearPassword();
                        }
                      },
                    ),
                    if (_enableLock) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'New Password',
                          prefixIcon: Icon(Icons.lock_outline, size: 20),
                        ),
                        validator: (v) => _enableLock && (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: Icon(Icons.lock_reset_outlined, size: 20),
                        ),
                        validator: (v) => _enableLock && v != _passwordController.text ? 'No match' : null,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _savePasswordSettings,
                          child: Text(settings.hasPassword ? 'Update Password' : 'Save Password'),
                        ),
                      ),
                      if (settings.hasPassword) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => context.read<AppSettingsProvider>().lockApp(),
                            child: const Text('Lock App Now'),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader('Backup & Restore'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _cloudProviderRow(
                    'Google Drive',
                    Icons.cloud_outlined,
                    Colors.blue,
                    () => _backupDatabase('Google Drive'),
                    () => _restoreDatabase('Google Drive'),
                  ),
                  const Divider(height: 32),
                  _cloudProviderRow(
                    'OneDrive',
                    Icons.cloud_done_outlined,
                    Colors.indigo,
                    () => _backupDatabase('OneDrive'),
                    () => _restoreDatabase('OneDrive'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: Colors.blueGrey.shade500,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _cloudProviderRow(String title, IconData icon, Color color, VoidCallback onBackup, VoidCallback onRestore) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onBackup,
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Backup'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onRestore,
                icon: const Icon(Icons.download_for_offline_outlined, size: 18),
                label: const Text('Restore'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
