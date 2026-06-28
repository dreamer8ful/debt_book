import 'package:flutter/material.dart';

const String _appDeveloperName = 'IntroSoft Media Solutions';
const String _appContactInfo = 'msr08@live.com';
const String _appCopyrightNotice = '© 2026 IntroSoft Media Solutions. All rights reserved.';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF0D6B8A),
              gradient: LinearGradient(
                colors: [Color(0xFF0D6B8A), Color(0xFF0A536B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.account_balance_wallet, size: 30, color: Color(0xFF0D6B8A)),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Debt Book',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Manage your debts easily',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _buildDrawerTile(
                  context,
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  title: 'Home',
                  isSelected: ModalRoute.of(context)?.settings.name == '/home' || ModalRoute.of(context)?.settings.name == '/',
                  onTap: () {
                    Navigator.pop(context);
                    if (ModalRoute.of(context)?.settings.name != '/home') {
                      Navigator.pushReplacementNamed(context, '/home');
                    }
                  },
                ),
                _buildDrawerTile(
                  context,
                  icon: Icons.file_download_outlined,
                  activeIcon: Icons.file_download,
                  title: 'Export Data',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/export');
                  },
                ),
                _buildDrawerTile(
                  context,
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings,
                  title: 'Settings',
                  isSelected: ModalRoute.of(context)?.settings.name == '/settings',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/settings');
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(),
                ),
                _buildDrawerTile(
                  context,
                  icon: Icons.info_outline,
                  activeIcon: Icons.info,
                  title: 'About',
                  onTap: () {
                    Navigator.pop(context);
                    showAboutDialog(
                      context: context,
                      applicationName: 'Debt Book',
                      applicationVersion: '1.0.0',
                      applicationLegalese: _appCopyrightNotice,
                      children: const [
                        SizedBox(height: 12),
                        _AboutInfoRow(
                          icon: Icons.person_outline,
                          label: 'Developer',
                          value: _appDeveloperName,
                        ),
                        SizedBox(height: 10),
                        _AboutInfoRow(
                          icon: Icons.mail_outline,
                          label: 'Contact',
                          value: _appContactInfo,
                        ),
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
    required IconData activeIcon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    final color = isSelected ? const Color(0xFF0D6B8A) : Colors.blueGrey.shade700;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D6B8A).withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(isSelected ? activeIcon : icon, color: color, size: 22),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _AboutInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF0D6B8A)),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
