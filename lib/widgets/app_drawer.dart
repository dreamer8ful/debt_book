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
        padding: EdgeInsets.zero,
        children: [
          // HEADER YA DRAWER
          UserAccountsDrawerHeader(
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
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
            ),
          ),
          
          // HOME - FIXED VERSION
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              // Close the drawer first
              Navigator.pop(context);
              
              // Check if we're already on HomeScreen
              // If yes, just close drawer, don't push new route
              // If no, navigate to HomeScreen
              if (ModalRoute.of(context)?.settings.name != '/home') {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false, // Remove all previous routes
                );
              }
            },
          ),
          
          const Divider(),
          
          // EXPORT DATA
          ListTile(
            leading: const Icon(Icons.file_download, color: Colors.green),
            title: const Text('Export Data'),
            subtitle: const Text('Save to Excel or PDF'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Close drawer first
              Navigator.pop(context);
              // Navigate to Export Screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ExportScreen()),
              );
            },
          ),
          
          const Divider(),
          
          // SETTINGS
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (_) => const SettingsScreen()),
              // );
              // Temporary: Show a snackbar that settings is coming soon
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings coming soon!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          
          // ABOUT
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            onTap: () {
              Navigator.pop(context);
              showAboutDialog(
                context: context,
                applicationName: 'Debt Manager',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.account_balance_wallet, size: 40),
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
    );
  }
}