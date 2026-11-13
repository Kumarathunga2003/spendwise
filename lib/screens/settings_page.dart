import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import '../widgets/spendwise_brand_logo.dart';
import 'package:flutter/services.dart';

import '../data/app_store.dart';
import '../data/finance_snapshot.dart';
import 'privacy_policy_page.dart';
import '../security/app_security.dart';
import '../security/security_settings_page.dart';
import '../notifications/expense_notifications.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/spend_ui.dart';

class SettingsPage extends StatelessWidget {
  final AppStore store;
  const SettingsPage({super.key, required this.store});

  void _message(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _copyCsv(BuildContext context) async {
    try {
      await Clipboard.setData(
          ClipboardData(text: transactionsCsv(store.entries)));
      if (!context.mounted) return;
      _message(context, 'CSV copied. It includes transactions only.');
    } catch (_) {
      if (!context.mounted) return;
      _message(context, 'Unable to copy the CSV.');
    }
  }

  Future<String?> _askPassphrase(BuildContext context,
      {required bool newBackup}) async {
    final first = TextEditingController();
    final second = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(newBackup ? 'Protect your backup' : 'Unlock backup'),
        content: SingleChildScrollView(
            child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(newBackup
                ? 'Choose a unique passphrase of at least 12 characters. '
                    'You will need it to restore this file. It cannot be recovered.'
                : 'Enter the passphrase used when this backup file was created.'),
            const SizedBox(height: 10),
            TextField(
              controller: first,
              obscureText: true,
              autofocus: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(labelText: 'Backup passphrase'),
            ),
            if (newBackup) ...[
              const SizedBox(height: 10),
              TextField(
                controller: second,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                decoration:
                    const InputDecoration(labelText: 'Confirm passphrase'),
              ),
            ],
          ],
        )),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (first.text.length < 12 ||
                  (newBackup && first.text != second.text)) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(
                  content: Text('Use 12+ characters and matching passphrases.'),
                ));
                return;
              }
              Navigator.pop(dialogContext, first.text);
            },
            child: Text(newBackup ? 'Continue' : 'Unlock'),
          ),
        ],
      ),
    );
    first.dispose();
    second.dispose();
    return result;
  }

  Future<void> _exportEncrypted(BuildContext context) async {
    final passphrase = await _askPassphrase(context, newBackup: true);
    if (passphrase == null || !context.mounted) return;
    try {
      final encrypted = await store.exportEncryptedBackup(passphrase);
      final now = DateTime.now();
      final stamp = '${now.year}${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}';
      final saved = await FilePicker.saveFile(
        fileName: 'SpendWise-$stamp.swbackup',
        bytes: encrypted,
        mimeType: 'application/octet-stream',
        dialogTitle: 'Save encrypted SpendWise backup',
      );
      if (saved != null && context.mounted) {
        _message(
            context, 'Encrypted backup saved. Store the passphrase safely.');
      }
    } catch (_) {
      if (!context.mounted) return;
      _message(context, 'Could not create or save the encrypted backup.');
    }
  }

  Future<void> _confirmDeleteAllData(BuildContext context) async {
    String confirmation = '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete all app data?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('This deletes all transactions, budgets and '
                  'preferences from this app installation. It cannot be '
                  'undone unless you have a separate backup. Export and '
                  'verify an encrypted backup before continuing.'),
              const SizedBox(height: 10),
              const Text('Type DELETE to confirm:'),
              TextField(
                onChanged: (value) => confirmation = value,
                autofocus: true,
                autocorrect: false,
                enableSuggestions: false,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(hintText: 'DELETE'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (confirmation.trim() != 'DELETE') {
                ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(
                    content: Text('Please type DELETE exactly.')));
                return;
              }
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Delete everything',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      final reminders = store.features.reminders;
      await store.deleteAllData();
      await AppSecurity.instance.clearLockSettings();
      try {
        await ExpenseNotifications.cancelAll(reminders);
      } catch (_) {/* No notifications on some platforms. */}
      if (!context.mounted) return;
      _message(context, 'Local transactions, budgets and preferences cleared.');
    } catch (_) {
      if (!context.mounted) return;
      _message(
          context,
          'Deletion could not be fully verified. '
          'Check data before assuming it was cleared.');
    }
  }

  Future<void> _restoreEncrypted(BuildContext context) async {
    try {
      final file = await FilePicker.pickFile(type: FileType.any);
      if (file == null || !context.mounted) return;
      // Guard before allocating large buffers from arbitrary files.
      final length = file.lengthSync() ?? await file.length();
      if (!context.mounted) return;
      if (length != null && length > 16 * 1024 * 1024) {
        _message(context, 'Backup is too large.');
        return;
      }
      final Uint8List bytes = await file.readAsBytes();
      if (!context.mounted) return;
      final passphrase = await _askPassphrase(context, newBackup: false);
      if (passphrase == null || !context.mounted) return;
      final FinanceSnapshot preview =
          await store.previewEncryptedBackup(bytes, passphrase);
      if (!context.mounted) return;
      final approved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Replace all SpendWise data?'),
          content: Text(
            'This backup contains ${preview.entries.length} transactions and '
            '${preview.budgets.length} budgets. Restoring REPLACES all current '
            'transactions, budgets and theme settings. Make a separate '
            'encrypted backup of your current data first.',
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Replace data'),
            ),
          ],
        ),
      );
      if (approved != true || !context.mounted) return;
      final oldReminders = store.features.reminders;
      await store.restoreSnapshot(preview);
      try {
        await ExpenseNotifications.cancelAll(oldReminders);
        await ExpenseNotifications.sync(store.features.reminders);
      } catch (_) {/* Not supported on every desktop/platform. */}
      if (!context.mounted) return;
      _message(context,
          'Restore finished. ${preview.entries.length} transactions loaded.');
    } catch (error) {
      if (!context.mounted) return;
      _message(
          context,
          error is FormatException
              ? 'Restore cancelled: ${error.message}'
              : 'Restore failed. Your current data has not been intentionally cleared.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsContent = ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SpendColors.teal,
            borderRadius: BorderRadius.circular(19),
          ),
          child: const Row(children: [
            SpendWiseBrandLogo(size: 48),
            SizedBox(width: 13),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SpendWiseWordmark(width: 180, onDarkSurface: true),
                SizedBox(height: 4),
                Text('Safer everyday money tracking',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.35,
                    )),
              ],
            )),
          ]),
        ),
        const SizedBox(height: 19),
        const SpendSectionHeader(
            title: 'Preferences',
            subtitle: 'Make SpendWise feel right for you'),
        const SizedBox(height: 10),
        Card(
            child: SwitchListTile(
          contentPadding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
          secondary: const SpendIconBadge(
              icon: Icons.dark_mode_outlined, color: SpendColors.teal),
          title: const Text('Dark mode',
              style: TextStyle(fontWeight: FontWeight.w700)),
          subtitle: const Text('Use a darker color theme'),
          value: store.darkMode,
          onChanged: (value) async {
            try {
              await store.setDarkMode(value);
            } catch (_) {
              if (!context.mounted) return;
              _message(context, 'Unable to change theme');
            }
          },
        )),
        const SizedBox(height: 19),
        const SpendSectionHeader(
            title: 'Your data',
            subtitle: 'Local database and protected backups'),
        const SizedBox(height: 10),
        Card(
            child: Column(children: [
          ListTile(
            leading: const SpendIconBadge(
                icon: Icons.receipt_long_outlined, color: SpendColors.teal),
            title: const Text('Saved transactions',
                style: TextStyle(fontWeight: FontWeight.w700)),
            trailing: Text('${store.entries.length}',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const SpendIconBadge(
                icon: Icons.storage_outlined, color: SpendColors.teal),
            title: const Text('Storage engine'),
            subtitle: Text(store.storageDescription),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const SpendIconBadge(
                icon: Icons.lock_outline, color: SpendColors.teal),
            title: const Text('Export encrypted backup',
                style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle:
                const Text('Save all transactions, budgets and preferences'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _exportEncrypted(context),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const SpendIconBadge(
                icon: Icons.settings_backup_restore, color: SpendColors.orange),
            title: const Text('Restore encrypted backup',
                style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle:
                const Text('Replaces existing data only after confirmation'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _restoreEncrypted(context),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const SpendIconBadge(
                icon: Icons.content_copy_outlined, color: SpendColors.teal),
            title: const Text('Copy transactions as CSV'),
            subtitle: const Text('Unencrypted transaction-only export'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _copyCsv(context),
          ),
        ])),
        const SizedBox(height: 19),
        const SpendSectionHeader(
            title: 'Privacy & security',
            subtitle: 'Know the limits of local storage'),
        const SizedBox(height: 10),
        Card(
            child: Column(children: [
          ListTile(
            leading: const SpendIconBadge(
                icon: Icons.privacy_tip_outlined, color: SpendColors.teal),
            title: const Text('Privacy policy',
                style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Read how SpendWise handles your data'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const SpendWisePrivacyPage())),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          const ListTile(
            leading: SpendIconBadge(
                icon: Icons.phone_android_rounded, color: SpendColors.teal),
            title: Text('Device-only storage',
                style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle:
                Text('No account or cloud sync. Android records use SQLite; '
                    'records are encrypted using SQLCipher on Android.'),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const SpendIconBadge(
                icon: Icons.lock_outline_rounded, color: SpendColors.orange),
            title: const Text('App lock'),
            subtitle: const Text('Set your PIN and automatic lock time'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) =>
                    SecuritySettingsPage(security: AppSecurity.instance))),
          ),
        ])),
        const SizedBox(height: 19),
        const SpendSectionHeader(
          title: 'Danger zone',
          subtitle: 'Actions that permanently remove local data',
        ),
        const SizedBox(height: 10),
        Card(
          child: ListTile(
            leading: const SpendIconBadge(
              icon: Icons.delete_forever_outlined,
              color: SpendColors.red,
            ),
            title: const Text('Delete all app data',
                style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Removes locally saved financial records'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _confirmDeleteAllData(context),
          ),
        ),
        const SizedBox(height: 18),
        Card(
            child: const Padding(
          padding: EdgeInsets.all(17),
          child: Text('Encrypted backup files use a passphrase. Keep a copy '
              'outside your phone. Losing the passphrase means losing access '
              'to that backup. CSV export is not encrypted. Do not uninstall '
              'the app or clear its data before checking a backup.'),
        )),
        const SizedBox(height: 15),
        Center(
            child: Text('SpendWise • Version 1.0',
                style: Theme.of(context).textTheme.bodySmall)),
      ],
    );
    // Scaffold provides the correct Material text style (no yellow underlines).
    // SafeArea keeps the banner below the status bar and punch-hole camera.
    return Scaffold(
      body: SafeArea(
        child: settingsContent,
      ),
    );
  }
}
