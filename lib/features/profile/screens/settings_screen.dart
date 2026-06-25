import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';

/// Settings screen with appearance, notifications, account, and about sections.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Local state for decorative controls
  ThemeMode _selectedTheme = ThemeMode.system;
  bool _orderUpdates = true;
  bool _promotional = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppShadows.spacingLg,
          vertical: AppShadows.spacingXl,
        ),
        children: [
          // ── Appearance ───────────────────────────────────────────
          _SectionHeader(title: 'Appearance'),
          const SizedBox(height: AppShadows.spacingSm),
          _buildCard(
            isDark: isDark,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppShadows.spacingLg,
                  vertical: AppShadows.spacingMd,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Theme',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppShadows.spacingSm),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.system,
                            label: Text('System'),
                            icon: Icon(Icons.settings_brightness_rounded),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            label: Text('Light'),
                            icon: Icon(Icons.light_mode_rounded),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            label: Text('Dark'),
                            icon: Icon(Icons.dark_mode_rounded),
                          ),
                        ],
                        selected: {_selectedTheme},
                        onSelectionChanged: (selection) {
                          setState(() {
                            _selectedTheme = selection.first;
                          });
                        },
                        style: ButtonStyle(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppShadows.spacingXxl),

          // ── Notifications ────────────────────────────────────────
          _SectionHeader(title: 'Notifications'),
          const SizedBox(height: AppShadows.spacingSm),
          _buildCard(
            isDark: isDark,
            children: [
              SwitchListTile(
                title: const Text('Order Updates'),
                subtitle: const Text('Get notified about order status changes'),
                value: _orderUpdates,
                onChanged: (val) => setState(() => _orderUpdates = val),
                activeThumbColor: AppColors.primary,
              ),
              Divider(
                height: 1,
                indent: AppShadows.spacingLg,
                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
              ),
              SwitchListTile(
                title: const Text('Promotional'),
                subtitle: const Text('Offers, deals and canteen specials'),
                value: _promotional,
                onChanged: (val) => setState(() => _promotional = val),
                activeThumbColor: AppColors.primary,
              ),
            ],
          ),

          const SizedBox(height: AppShadows.spacingXxl),

          // ── Account ──────────────────────────────────────────────
          _SectionHeader(title: 'Account'),
          const SizedBox(height: AppShadows.spacingSm),
          _buildCard(
            isDark: isDark,
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline_rounded),
                title: const Text('Edit Profile'),
                trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                onTap: () => _showComingSoon(context, 'Edit Profile'),
              ),
              Divider(
                height: 1,
                indent: 56,
                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
              ),
              ListTile(
                leading: const Icon(Icons.lock_outline_rounded),
                title: const Text('Change Password'),
                trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                onTap: () => _showComingSoon(context, 'Change Password'),
              ),
              Divider(
                height: 1,
                indent: 56,
                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                ),
                title: Text(
                  'Delete Account',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.error,
                  ),
                ),
                onTap: () => _confirmDeleteAccount(context),
              ),
            ],
          ),

          const SizedBox(height: AppShadows.spacingXxl),

          // ── About ────────────────────────────────────────────────
          _SectionHeader(title: 'About'),
          const SizedBox(height: AppShadows.spacingSm),
          _buildCard(
            isDark: isDark,
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline_rounded),
                title: const Text('App Version'),
                trailing: Text(
                  '1.0.0',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                ),
              ),
              Divider(
                height: 1,
                indent: 56,
                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Terms of Service'),
                trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                onTap: () => _showComingSoon(context, 'Terms of Service'),
              ),
              Divider(
                height: 1,
                indent: 56,
                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                onTap: () => _showComingSoon(context, 'Privacy Policy'),
              ),
            ],
          ),

          const SizedBox(height: AppShadows.spacing4xl),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────

  Widget _buildCard({
    required bool isDark,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppShadows.borderRadiusMd,
        side: BorderSide(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          width: 0.5,
        ),
      ),
      child: Column(children: children),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppShadows.borderRadiusMd,
        ),
        title: const Text('Coming Soon'),
        content: Text('$feature is under development. Stay tuned!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppShadows.borderRadiusMd,
        ),
        title: const Text('Delete Account'),
        content: const Text(
          'This action is permanent and cannot be undone. '
          'All your data will be deleted.\n\n'
          'Are you sure you want to delete your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Account deletion is not yet implemented. Contact support.',
          ),
        ),
      );
    }
  }
}

// ─── Section Header ────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      title,
      style: theme.textTheme.labelLarge?.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
