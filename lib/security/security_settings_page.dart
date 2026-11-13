import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import 'app_security.dart';

class SecuritySettingsPage extends StatefulWidget {
  final AppSecurity security;
  const SecuritySettingsPage({super.key, required this.security});

  @override
  State<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage> {
  final bool _busy = false;

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  /// Show all fields together: validation never dismisses this dialog.
  Future<void> _setPin() async {
    if (_busy) return;
    final old = TextEditingController();
    final fresh = TextEditingController();
    final confirm = TextEditingController();
    final changing = widget.security.enabled;
    String? error;
    bool saving = false;

    try {
      final success = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, update) {
            final pinError =
                fresh.text.isEmpty ? null : validateSpendWisePin(fresh.text);
            final confirmationError =
                confirm.text.isNotEmpty && fresh.text != confirm.text
                    ? 'PINs do not match.'
                    : null;
            return AlertDialog(
              title: Text(
                  changing ? 'Change SpendWise PIN' : 'Create SpendWise PIN'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                        'Choose 6–12 numbers. You will need this PIN to access your financial records.'),
                    const SizedBox(height: 12),
                    if (changing) ...[
                      TextField(
                        controller: old,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        enableSuggestions: false,
                        autocorrect: false,
                        maxLength: 12,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration:
                            const InputDecoration(labelText: 'Current PIN'),
                        onChanged: (_) => update(() => error = null),
                      ),
                    ],
                    TextField(
                      controller: fresh,
                      autofocus: !changing,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      enableSuggestions: false,
                      autocorrect: false,
                      maxLength: 12,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'New PIN',
                        helperText: 'Minimum 6 digits; maximum 12 digits',
                        errorText: pinError,
                      ),
                      onChanged: (_) => update(() => error = null),
                    ),
                    TextField(
                      controller: confirm,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      enableSuggestions: false,
                      autocorrect: false,
                      maxLength: 12,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Confirm new PIN',
                        errorText: confirmationError,
                      ),
                      onChanged: (_) => update(() => error = null),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 8),
                      Text(error!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error)),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      saving ? null : () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final validation = validateSpendWisePin(fresh.text);
                          if (validation != null) {
                            update(() => error = validation);
                            return;
                          }
                          if (fresh.text != confirm.text) {
                            update(() =>
                                error = 'The confirmation PIN does not match.');
                            return;
                          }
                          if (changing && old.text.isEmpty) {
                            update(
                                () => error = 'Enter your current PIN first.');
                            return;
                          }
                          update(() {
                            saving = true;
                            error = null;
                          });
                          try {
                            await widget.security.createPin(
                              fresh.text,
                              currentPin: changing ? old.text : null,
                            );
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop(true);
                            }
                          } on AppLockException catch (e) {
                            if (dialogContext.mounted) {
                              update(() => error = e.message);
                            }
                          } catch (_) {
                            if (dialogContext.mounted) {
                              update(() => error =
                                  'Unable to save the PIN. Please try again.');
                            }
                          } finally {
                            if (dialogContext.mounted) {
                              update(() => saving = false);
                            }
                          }
                        },
                  child: Text(saving ? 'Saving…' : 'Save PIN'),
                ),
              ],
            );
          },
        ),
      );
      if (success == true) {
        _message(changing ? 'PIN changed successfully.' : 'PIN lock enabled.');
      }
    } finally {
      old.dispose();
      fresh.dispose();
      confirm.dispose();
    }
  }

  Future<void> _disablePin() async {
    if (_busy) return;
    final controller = TextEditingController();
    String? error;
    bool saving = false;
    try {
      final success = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, update) => AlertDialog(
            title: const Text('Disable SpendWise app lock?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                    'Your financial records will no longer require a SpendWise PIN to open.'),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 12,
                  enableSuggestions: false,
                  autocorrect: false,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                      labelText: 'Current PIN', errorText: error),
                  onChanged: (_) => update(() => error = null),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed:
                    saving ? null : () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        final problem = validateSpendWisePin(controller.text);
                        if (problem != null) {
                          update(() => error = problem);
                          return;
                        }
                        update(() {
                          saving = true;
                          error = null;
                        });
                        try {
                          await widget.security.disable(controller.text);
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop(true);
                          }
                        } on AppLockException catch (e) {
                          if (dialogContext.mounted) {
                            update(() => error = e.message);
                          }
                        } catch (_) {
                          if (dialogContext.mounted) {
                            update(() => error =
                                'Could not disable app lock. Try again.');
                          }
                        } finally {
                          if (dialogContext.mounted) {
                            update(() => saving = false);
                          }
                        }
                      },
                child: Text(saving ? 'Checking…' : 'Disable lock'),
              ),
            ],
          ),
        ),
      );
      if (success == true) _message('SpendWise app lock disabled.');
    } finally {
      controller.dispose();
    }
  }

  Future<void> _setAutoLock(int minutes) async {
    try {
      await widget.security.setAutoLockMinutes(minutes);
      _message('Auto-lock setting updated.');
    } on AppLockException catch (e) {
      _message(e.message);
    } catch (_) {
      _message('Unable to save the auto-lock setting.');
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: widget.security,
        builder: (context, _) => Scaffold(
          appBar: AppBar(title: const Text('App lock & privacy')),
          body: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                Card(
                    child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(children: [
                          Icon(Icons.shield_outlined,
                              size: 36,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 16),
                          const Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text('PIN protection',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18)),
                                SizedBox(height: 4),
                                Text('Control access and automatic locking.'),
                              ])),
                        ]))),
                const SizedBox(height: 14),
                ListTile(
                  leading: const Icon(Icons.pin),
                  title: Text(widget.security.enabled
                      ? 'Change PIN'
                      : 'Enable PIN lock'),
                  subtitle: const Text(
                      '6–12 digits, protected in Android secure storage'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _busy ? null : _setPin,
                ),
                if (widget.security.enabled) ...[
                  ListTile(
                    title: const Text('Auto-lock after inactivity'),
                    subtitle: Text(widget.security.autoLockMinutes == 0
                        ? 'Immediately when backgrounded'
                        : '${widget.security.autoLockMinutes} minute(s)'),
                    trailing: DropdownButton<int>(
                      value: widget.security.autoLockMinutes,
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('Immediate')),
                        DropdownMenuItem(value: 1, child: Text('1 minute')),
                        DropdownMenuItem(value: 5, child: Text('5 minutes')),
                        DropdownMenuItem(value: 15, child: Text('15 minutes')),
                      ],
                      onChanged: _busy
                          ? null
                          : (m) {
                              if (m != null) _setAutoLock(m);
                            },
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.lock),
                    title: const Text('Lock SpendWise now'),
                    onTap: _busy
                        ? null
                        : () {
                            Navigator.of(context).pop();
                            widget.security.lock();
                          },
                  ),
                  ListTile(
                    leading: const Icon(Icons.lock_open),
                    title: const Text('Disable app lock'),
                    subtitle: const Text('Requires your existing PIN'),
                    onTap: _busy ? null : _disablePin,
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    'SpendWise uses your PIN for app access. Keep a verified encrypted backup, and never clear app data to resolve a PIN issue.',
                  ),
                ),
              ]),
        ),
      );
}
