import 'package:flutter/material.dart';

class VendorSettingsTab extends StatelessWidget {
  final Map<String, dynamic>? canteenData;
  final VoidCallback onSignOut;

  const VendorSettingsTab({
    super.key,
    required this.canteenData,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canteenName = canteenData?['name'] ?? 'Preorder Canteen';
    final canteenLocation = canteenData?['location'] ?? 'Main Block';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Settings Header ───────────────────────────────────────────────
          Text(
            'Settings',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage your vendor configuration',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),

          // ── Vendor Profile Card ───────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    child: Icon(Icons.storefront, color: theme.colorScheme.primary, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          canteenName,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          canteenLocation.isNotEmpty ? canteenLocation : 'Location unset',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit_outlined, color: theme.colorScheme.primary),
                    onPressed: () {
                      _showEditInfoDialog(context);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Timings & Working Hours ───────────────────────────────────────
          _buildSettingsGroupHeader('TIMING & HOURS', theme),
          Card(
            child: Column(
              children: [
                _buildSettingsTile(
                  icon: Icons.access_time,
                  title: 'Working Hours',
                  subtitle: 'Daily: 08:00 AM - 08:00 PM',
                  theme: theme,
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56),
                _buildSettingsTile(
                  icon: Icons.calendar_today,
                  title: 'Holiday Timings',
                  subtitle: 'Set special closed days',
                  theme: theme,
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Operational Settings ──────────────────────────────────────────
          _buildSettingsGroupHeader('OPERATIONS', theme),
          Card(
            child: Column(
              children: [
                _buildSettingsTile(
                  icon: Icons.notifications_active_outlined,
                  title: 'Sound & Notifications',
                  subtitle: 'Volume, Ringtone on new orders',
                  theme: theme,
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56),
                _buildSettingsTile(
                  icon: Icons.print_outlined,
                  title: 'Printer Setup',
                  subtitle: 'Configure bluetooth receipt auto-printer',
                  theme: theme,
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56),
                _buildSettingsTile(
                  icon: Icons.payments_outlined,
                  title: 'Payments & Payouts',
                  subtitle: 'Configure bank details, Cashfree, UPI ID',
                  theme: theme,
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Help & Support ────────────────────────────────────────────────
          _buildSettingsGroupHeader('HELP & LEGAL', theme),
          Card(
            child: Column(
              children: [
                _buildSettingsTile(
                  icon: Icons.help_outline,
                  title: 'Support & FAQs',
                  subtitle: 'Need help running the store?',
                  theme: theme,
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56),
                _buildSettingsTile(
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                  subtitle: 'Merchant policies and rules',
                  theme: theme,
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Logout Button ─────────────────────────────────────────────────
          ElevatedButton.icon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out of Store'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSettingsGroupHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.08),
        child: Icon(icon, color: theme.colorScheme.primary, size: 18),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(subtitle, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: theme.colorScheme.onSurfaceVariant),
      onTap: onTap,
    );
  }

  void _showEditInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Vendor Information'),
          content: const Text('To modify your official canteen name or verified location, please contact customer support or submit a request to the operations administrator.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
