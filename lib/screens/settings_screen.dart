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

    final selectedCurrency = _currencyOptions.firstWhere(
      (option) => option['code'] == settings.currencyCode,
      orElse: () => _currencyOptions.first,
    );

    final selectedDateFormat = _dateFormats.firstWhere(
      (option) => option['pattern'] == settings.dateFormatPattern,
      orElse: () => _dateFormats.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D6B8A), Color(0xFF0A536B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Currency',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: settings.currencyCode,
                    items: _currencyOptions
                        .map(
                          (option) => DropdownMenuItem<String>(
                            value: option['code'] as String,
                            child: Text(option['label'] as String),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      final selected = _currencyOptions.firstWhere(
                        (option) => option['code'] == value,
                      );
                      context.read<AppSettingsProvider>().setCurrency(
                            code: selected['code'] as String,
                            symbol: selected['symbol'] as String,
                          );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selected: ${selectedCurrency['label']}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Date Format',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: settings.dateFormatPattern,
                    items: _dateFormats
                        .map(
                          (option) => DropdownMenuItem<String>(
                            value: option['pattern'] as String,
                            child: Text(option['label'] as String),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      context.read<AppSettingsProvider>().setDateFormat(value);
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selected: ${selectedDateFormat['label']}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'App Lock',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enable app lock'),
                      value: _enableLock,
                      onChanged: (value) async {
                        setState(() {
                          _enableLock = value;
                        });

                        if (!value && settings.hasPassword) {
                          await context.read<AppSettingsProvider>().clearPassword();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('App lock disabled')),
                          );
                        }
                      },
                    ),
                    if (_enableLock) ...[
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (value) {
                          if (_enableLock && (value == null || value.isEmpty)) {
                            return 'Enter a password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirm password',
                          prefixIcon: Icon(Icons.lock_reset_outlined),
                        ),
                        validator: (value) {
                          if (_enableLock && value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _savePasswordSettings,
                              icon: const Icon(Icons.save_outlined),
                              label: Text(
                                settings.hasPassword ? 'Update Password' : 'Save Password',
                              ),
                            ),
                          ),
                          if (settings.hasPassword) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  context.read<AppSettingsProvider>().lockApp();
                                },
                                icon: const Icon(Icons.lock),
                                label: const Text('Lock App Now'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ] else if (settings.hasPassword) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Password is set but app lock is disabled.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await context.read<AppSettingsProvider>().clearPassword();
                          if (!mounted) return;
                          setState(() {
                            _enableLock = false;
                          });
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Password removed')),
                          );
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Remove Password'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.language_outlined),
              title: const Text('Language'),
              subtitle: const Text('Coming soon'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Soon',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              enabled: false,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cloud Backup & Restore',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose a folder or file location inside your Google Drive or OneDrive sync folder on this device.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  _cloudProviderTile(
                    icon: Icons.cloud,
                    title: 'Google Drive',
                    color: Colors.blue.shade700,
                    onBackup: () => _backupDatabase('Google Drive'),
                    onRestore: () => _restoreDatabase('Google Drive'),
                  ),
                  const SizedBox(height: 12),
                  _cloudProviderTile(
                    icon: Icons.cloud_done,
                    title: 'OneDrive',
                    color: Colors.indigo.shade700,
                    onBackup: () => _backupDatabase('OneDrive'),
                    onRestore: () => _restoreDatabase('OneDrive'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cloudProviderTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onBackup,
    required VoidCallback onRestore,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onBackup,
                  icon: const Icon(Icons.backup_outlined),
                  label: const Text('Backup Data'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onRestore,
                  icon: const Icon(Icons.restore_outlined),
                  label: const Text('Restore Data'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}