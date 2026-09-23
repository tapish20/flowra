import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/auth_service.dart';
import '../services/health_log_service.dart';
import '../widgets/card_container.dart';
import '../theme.dart';
import 'login_screen.dart';
import 'chatbot_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  final HealthLogService _healthLogService = HealthLogService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  
  String _selectedCycleLength = '28';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.primary,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF0F5), Color(0xFFFDFBFC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            children: [
              // ── Appearance Section ──────────────────────────────────────
              _buildSection(
                title: 'Appearance',
                titleTopPadding: 16,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: ValueListenableBuilder<FlowraTheme>(
                      valueListenable: themeNotifier,
                      builder: (context, current, _) {
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _ThemeCard(
                              label: 'Light',
                              bg: const Color(0xFFFCF9FA),
                              accent: const Color(0xFFEA4C89),
                              sidebar: Colors.white,
                              isSelected: current == FlowraTheme.light,
                              onTap: () => themeNotifier.value = FlowraTheme.light,
                            ),
                            _ThemeCard(
                              label: 'Dark',
                              bg: const Color(0xFF121212),
                              accent: const Color(0xFFEA4C89),
                              sidebar: const Color(0xFF1E1E2E),
                              isSelected: current == FlowraTheme.dark,
                              onTap: () => themeNotifier.value = FlowraTheme.dark,
                            ),
                            _ThemeCard(
                              label: 'Lavender',
                              bg: const Color(0xFF1A1428),
                              accent: const Color(0xFFCB9FE5),
                              sidebar: const Color(0xFF261E3A),
                              isSelected: current == FlowraTheme.lavender,
                              onTap: () => themeNotifier.value = FlowraTheme.lavender,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
              // Account Section
              _buildSection(
                title: 'Account',
                children: [
                  _buildSettingsTile(
                    icon: Icons.person,
                    title: 'Profile',
                    subtitle: 'Manage your profile information',
                    onTap: () => _showProfileDialog(),
                  ),
                  _buildSettingsTile(
                    icon: Icons.lock,
                    title: 'Change Password',
                    subtitle: 'Update your password',
                    onTap: () => _showChangePasswordDialog(),
                  ),
                  _buildSettingsTile(
                    icon: Icons.logout,
                    title: 'Logout',
                    subtitle: 'Sign out of your Flowra account',
                    onTap: () => _showLogoutDialog(),
                    isDestructive: true,
                  ),
                ],
              ),
              // Health Settings Section
              _buildSection(
                title: 'Health Settings',
                titleTopPadding: 8,
                children: [
                  _buildDropdownTile(
                    icon: Icons.calendar_month,
                    title: 'Average Cycle Length',
                    subtitle: 'Days between periods',
                    value: _selectedCycleLength,
                    items: ['21', '24', '26', '28', '30', '32', '35'],
                    onChanged: (val) => setState(() => _selectedCycleLength = val ?? '28'),
                  ),
                  _buildSettingsTile(
                    icon: Icons.medical_information,
                    title: 'Health Data Export',
                    subtitle: 'Download your health logs',
                    onTap: () => _exportHealthData(),
                  ),
                ],
              ),
              // Privacy & Security Section
              _buildSection(
                title: 'Privacy & Security',
                children: [
                  _buildSettingsTile(
                    icon: Icons.privacy_tip,
                    title: 'Privacy Policy',
                    subtitle: 'Read our privacy terms',
                    onTap: () => _showPrivacyPolicy(),
                  ),
                  _buildSettingsTile(
                    icon: Icons.description,
                    title: 'Terms of Service',
                    subtitle: 'View terms and conditions',
                    onTap: () => _showTermsOfService(),
                  ),
                  _buildSettingsTile(
                    icon: Icons.delete_forever,
                    title: 'Delete Account',
                    subtitle: 'Permanently delete your account',
                    onTap: () => _showDeleteAccountDialog(),
                    isDestructive: true,
                  ),
                ],
              ),
              // Support Section
              _buildSection(
                title: 'Support',
                children: [
                  _buildSettingsTile(
                    icon: Icons.chat_bubble,
                    title: 'Ask AI Assistant',
                    subtitle: 'Get answers to your questions',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ChatbotScreen()),
                      );
                    },
                  ),
                  _buildSettingsTile(
                    icon: Icons.help,
                    title: 'Help & FAQ',
                    subtitle: 'Common questions and answers',
                    onTap: () => _showHelpFaq(),
                  ),
                  _buildSettingsTile(
                    icon: Icons.bug_report,
                    title: 'Report a Bug',
                    subtitle: 'Help us improve Flowra',
                    onTap: () => _showBugReport(),
                  ),
                  _buildSettingsTile(
                    icon: Icons.info,
                    title: 'About',
                    subtitle: 'Version 1.0.0 | Made with ❤️',
                    onTap: () => _showAboutDialog(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
    double titleTopPadding = 16,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(8, titleTopPadding, 8, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.primary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          CardContainer(
            padding: EdgeInsets.zero,
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red.shade600 : AppTheme.primary),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDestructive ? Colors.red.shade600 : const Color(0xFF2D3748),
        ),
      ),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2D3748))),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      trailing: DropdownButton<String>(
        value: value,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
        underline: const SizedBox(),
        style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
        dropdownColor: Colors.white,
      ),
    );
  }

  Widget _dialogSecondaryButton({
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
  }) {
    final btn = icon == null
        ? TextButton(onPressed: onPressed, child: Text(label))
        : TextButton.icon(onPressed: onPressed, icon: Icon(icon, size: 18), label: Text(label));
    return btn;
  }

  ButtonStyle _primaryButtonStyle({Color? backgroundColor}) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? AppTheme.primary,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
    );
  }

  ButtonStyle _secondaryButtonStyle() {
    return TextButton.styleFrom(
      foregroundColor: AppTheme.primary,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Future<void> _showProfileDialog() async {
    final user = _firebaseAuth.currentUser;
    final nameCtrl = TextEditingController(text: user?.displayName ?? '');
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gradient avatar with initial
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEA4C89), Color(0xFF6C5CE7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEA4C89).withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    (user?.displayName?.isNotEmpty == true
                            ? user!.displayName![0]
                            : user?.email?[0] ?? '?')
                        .toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              user?.email ?? '',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Display name',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          _dialogSecondaryButton(
            label: 'Cancel',
            icon: Icons.close,
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                await user?.updateDisplayName(nameCtrl.text.trim());
                if (!mounted || !ctx.mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated'), backgroundColor: Colors.green),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update profile: $e'), backgroundColor: Colors.red),
                );
              }
            },
            icon: const Icon(Icons.save),
            label: const Text('Save Changes'),
            style: _primaryButtonStyle(),
          ),
        ],
      ),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current password'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: newCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm new password'),
            ),
          ],
        ),
        actions: [
          _dialogSecondaryButton(
            label: 'Cancel',
            icon: Icons.close,
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              if (newCtrl.text != confirmCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('New passwords do not match'), backgroundColor: Colors.orange),
                );
                return;
              }
              try {
                final user = _firebaseAuth.currentUser;
                final email = user?.email;
                if (user == null || email == null) {
                  throw Exception('Not authenticated');
                }
                final credential = EmailAuthProvider.credential(
                  email: email,
                  password: currentCtrl.text,
                );
                await user.reauthenticateWithCredential(credential);
                await user.updatePassword(newCtrl.text);
                if (!mounted || !ctx.mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password updated'), backgroundColor: Colors.green),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update password: $e'), backgroundColor: Colors.red),
                );
              }
            },
            icon: const Icon(Icons.lock_reset),
            label: const Text('Update Password'),
            style: _primaryButtonStyle(),
          ),
        ],
      ),
    );
  }

  Future<void> _exportHealthData() async {
    try {
      final logs = await _healthLogService.fetchLogsOnce();
      final payload = logs.map((l) => l.toJson()).toList();
      final jsonStr = payload.map((e) => e.toString()).join('\n');
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Health Data Export', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: SelectableText(jsonStr),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: jsonStr));
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard'), backgroundColor: Colors.green),
                );
              },
              style: _secondaryButtonStyle(),
              child: const Text('Copy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: _secondaryButtonStyle(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showPrivacyPolicy() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const SingleChildScrollView(
          child: Text(
            'We only collect data you enter to provide tracking and insights. '
            'Your data is stored securely and is not sold or shared with third parties. '
            'You can delete your data at any time from Settings.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: _secondaryButtonStyle(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Terms of Service', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const SingleChildScrollView(
          child: Text(
            'Flowra provides wellness tracking tools and safety features. '
            'It is not a substitute for professional medical advice. '
            'Use the SOS feature responsibly and verify your contact information.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: _secondaryButtonStyle(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelpFaq() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Help & FAQ', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const SingleChildScrollView(
          child: Text(
            '• Track your cycle in the Period Tracker.\n'
            '• Log mood, energy, and pain in Health Logging.\n'
            '• Use Insights to view trends.\n'
            '• Add trusted contacts for SOS alerts.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: _secondaryButtonStyle(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showBugReport() {
    const template = 'Flowra Bug Report\n'
        '1) What happened?\n'
        '2) Steps to reproduce:\n'
        '3) Expected result:\n'
        '4) Actual result:\n'
        '5) Device/OS:\n';
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Report a Bug', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Copy the template and send it to support@flowra.app'),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(const ClipboardData(text: template));
              if (!mounted || !ctx.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bug report template copied'), backgroundColor: Colors.green),
              );
            },
            style: _secondaryButtonStyle(),
            child: const Text('Copy Template'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: _secondaryButtonStyle(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Flowra',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2026 Flowra. All rights reserved.\nMade with ❤️ for women\'s health and safety.',
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            'Flowra is a comprehensive period tracker and women\'s safety companion app designed to help you manage your health and stay safe.',
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          _dialogSecondaryButton(
            label: 'Cancel',
            icon: Icons.close,
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await _authService.logout();
              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: _primaryButtonStyle(backgroundColor: Colors.red.shade600),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Account?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'This action cannot be undone. All your data will be permanently deleted. Are you sure?',
        ),
        actions: [
          _dialogSecondaryButton(
            label: 'Cancel',
            icon: Icons.close,
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final user = _firebaseAuth.currentUser;
                final uid = user?.uid;
                if (uid == null) throw Exception('Not authenticated');

                // Best-effort data cleanup
                await _db.ref('health_logs/$uid').remove();
                await _db.ref('cycles/$uid').remove();
                await _db.ref('recent_cycles/$uid').remove();
                await _db.ref('contacts/$uid').remove();

                await user?.delete();
                if (!mounted) return;
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Delete failed: $e'), backgroundColor: Colors.red),
                );
              }
            },
            icon: const Icon(Icons.delete_forever),
            label: const Text('Delete Account'),
            style: _primaryButtonStyle(backgroundColor: Colors.red.shade700),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ThemeCard — mini preview swatch for the Appearance section
// ─────────────────────────────────────────────────────────────────────────────
class _ThemeCard extends StatelessWidget {
  final String label;
  final Color bg;
  final Color accent;
  final Color sidebar;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.label,
    required this.bg,
    required this.accent,
    required this.sidebar,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? accent : Colors.transparent,
              width: 2.5,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 10, spreadRadius: 1)]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Mini preview panel
                Container(
                  height: 52,
                  color: bg,
                  child: Row(
                    children: [
                      Container(width: 18, color: sidebar),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 4,
                              width: 30,
                              decoration: BoxDecoration(
                                color: accent,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 3,
                              width: 20,
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Label
                Container(
                  color: isSelected ? accent : Colors.grey.shade100,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
