import 'package:material_ui/material_ui.dart';
import '../widgets/spendwise_brand_logo.dart';
import 'package:flutter/services.dart';

import 'app_security.dart';

class SpendWiseLockScreen extends StatefulWidget {
  final AppSecurity security;
  const SpendWiseLockScreen({super.key, required this.security});

  @override
  State<SpendWiseLockScreen> createState() => _SpendWiseLockScreenState();
}

class _SpendWiseLockScreenState extends State<SpendWiseLockScreen> {
  final TextEditingController _pin = TextEditingController();
  bool _busy = false;
  bool _obscured = true;
  String? _error;

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    if (_busy) return;
    final problem = validateSpendWisePin(_pin.text);
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final success = await widget.security.checkPin(_pin.text);
      if (mounted && !success) {
        setState(
            () => _error = 'Incorrect PIN. Check the numbers and try again.');
      }
    } on AppLockException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to unlock securely. Please try again.');
      }
    } finally {
      // Successful unlock removes this screen; never access its disposed
      // TextEditingController after the security notifier rebuilds the app.
      if (mounted) {
        _pin.clear();
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final valid = validateSpendWisePin(_pin.text) == null;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 10 * (1 - value)),
                    child: child,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(19),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF086D66), Color(0xFF123E3C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(21),
                      ),
                      child: const Column(
                        children: [
                          SpendWiseBrandLogo(size: 55),
                          SizedBox(height: 7),
                          SpendWiseWordmark(width: 162, onDarkSurface: true),
                          SizedBox(height: 9),
                          Text('Welcome back',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                          SizedBox(height: 6),
                          Text('Unlock SpendWise to manage your money',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFFD1EEE7))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.password_rounded,
                                    color: scheme.primary),
                                const SizedBox(width: 10),
                                Text('Your secure PIN',
                                    style: theme.textTheme.titleMedium),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (widget.security.securityError != null) ...[
                              Text(widget.security.securityError!,
                                  style: TextStyle(color: scheme.error)),
                              const SizedBox(height: 14),
                              OutlinedButton.icon(
                                onPressed: _busy ? null : widget.security.load,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Retry secure storage'),
                              ),
                            ] else ...[
                              TextField(
                                controller: _pin,
                                autofocus: true,
                                obscureText: _obscured,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.done,
                                maxLength: 12,
                                enableSuggestions: false,
                                autocorrect: false,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                decoration: InputDecoration(
                                  labelText: 'SpendWise PIN',
                                  helperText: 'Enter 6–12 digits',
                                  counterText: '',
                                  errorText: _error,
                                  prefixIcon: const Icon(Icons.dialpad_rounded),
                                  suffixIcon: IconButton(
                                    tooltip:
                                        _obscured ? 'Show PIN' : 'Hide PIN',
                                    onPressed: () =>
                                        setState(() => _obscured = !_obscured),
                                    icon: Icon(_obscured
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined),
                                  ),
                                ),
                                onChanged: (value) => setState(() {
                                  _error = value.isNotEmpty && value.length < 6
                                      ? 'Enter at least 6 digits.'
                                      : null;
                                }),
                                onSubmitted: (_) => _unlock(),
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                height: 50,
                                child: FilledButton.icon(
                                  onPressed: _busy || !valid ? null : _unlock,
                                  icon: _busy
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white))
                                      : const Icon(Icons.arrow_forward_rounded),
                                  label: Text(_busy
                                      ? 'Verifying PIN…'
                                      : 'Unlock SpendWise'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your transactions stay on this device. Never share your PIN.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
