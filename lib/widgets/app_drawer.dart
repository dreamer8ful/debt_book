import 'package:flutter/material.dart';
import '../screens/export_screen.dart';
import '../screens/home_screen.dart';
import '../screens/settings_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  PageRouteBuilder<void> _buildPageRoute(Widget page) {
    return PageRouteBuilder<void>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slide = Tween<Offset>(
          begin: const Offset(0.03, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
        final fade = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFF4F8FB),
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
                    color: const Color(0xFF0D6B8A),
                  ),
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0D6B8A), Color(0xFF0A536B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
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
                        _buildPageRoute(const HomeScreen()),
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
                      _buildPageRoute(const ExportScreen()),
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
                    Navigator.push(
                      context,
                      _buildPageRoute(const SettingsScreen()),
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
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: (iconColor ?? const Color(0xFF0D6B8A)).withValues(alpha: 0.12),
          child: Icon(icon, color: iconColor ?? const Color(0xFF0D6B8A)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: subtitle == null ? null : Text(subtitle),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
