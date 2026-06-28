import 'package:flutter/material.dart';
import '../screens/export_screen.dart';
import '../screens/home_screen.dart';
// import '../screens/settings_screen.dart'; // Kama unayo

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: UserAccountsDrawerHeader(
                margin: EdgeInsets.zero,
                accountName: const Text(
                  'Debt Manager',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                accountEmail: const Text('Manage your debts easily'),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.account_balance_wallet,
                    size: 40,
                    color: Colors.blue.shade700,
                  ),
                ),
                decoration: BoxDecoration(color: Colors.blue.shade700),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildDrawerTile(
                  context,
                  icon: Icons.home,
                  title: 'Home',
                  onTap: () {
                    Navigator.pop(context);
                    if (ModalRoute.of(context)?.settings.name != '/home') {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                        (route) => false,
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
                _buildDrawerTile(
                  context,
                  icon: Icons.file_download,
                  iconColor: Colors.green,
                  title: 'Export Data',
                  subtitle: 'Save to Excel or PDF',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ExportScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _buildDrawerTile(
                  context,
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Settings coming soon!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _buildDrawerTile(
                  context,
                  icon: Icons.info_outline,
                  title: 'About',
                  onTap: () {
                    Navigator.pop(context);
                    showAboutDialog(
                      context: context,
                      applicationName: 'Debt Manager',
                      applicationVersion: '1.0.0',
                      applicationIcon: const Icon(
                        Icons.account_balance_wallet,
                        size: 40,
                      ),
                      children: const [
                        Text('Track your lending and borrowing with ease.'),
                        SizedBox(height: 8),
                        Text('Features:'),
                        Text('• Track money you lent and borrowed'),
                        Text('• Export data to Excel/PDF'),
                        Text('• Payment reminders'),
                        Text('• Search and filter transactions'),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    String? subtitle,
    Widget? trailing,
    Color? iconColor,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? Colors.blueGrey.shade700),
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
