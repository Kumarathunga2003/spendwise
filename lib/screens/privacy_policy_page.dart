import 'package:material_ui/material_ui.dart';

/// Before Play submission: replace the two values below with public details
/// matching your Play Console developer identity and support contact.
const spendWiseDeveloperName = 'R.P.G.B Kumarathunga';
const spendWiseSupportEmail = 'gaweesha2003@gmail.com';

class SpendWisePrivacyPage extends StatelessWidget {
  const SpendWisePrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy policy')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Icon(Icons.privacy_tip_outlined, size: 40, color: scheme.primary),
          const SizedBox(height: 12),
          Text('SpendWise Privacy Policy',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          const Text('Effective date: 7 November 2026'),
          const SizedBox(height: 18),
          const _PolicySection(
            title: 'What SpendWise does',
            body: 'SpendWise is an offline-first personal finance tracker. '
                'You can record income, expenses, budgets and preferences '
                'without creating an account.',
          ),
          const _PolicySection(
            title: 'Information stored on your device',
            body: 'Your transaction titles, amounts, dates, categories, '
                'notes, budgets and dark-mode preference are saved locally. '
                'On Android, the current app uses an unencrypted SQLite '
                'database. Anyone with sufficient device access may be able '
                'to access locally stored information.',
          ),
          const _PolicySection(
            title: 'Internet and data sharing',
            body: 'The reviewed SpendWise application has no account system '
                'or cloud sync. It is designed to keep financial records on '
                'your device. Final Play Store disclosures must also reflect '
                'any services or SDKs included in the released build.',
          ),
          const _PolicySection(
            title: 'Backups and exports',
            body: 'You can save an encrypted backup protected with a '
                'passphrase, or copy transaction data as unencrypted CSV. '
                'Files you save or share are outside the app’s control. '
                'Keep the passphrase safe: it cannot be recovered by SpendWise.',
          ),
          const _PolicySection(
            title: 'Deleting your data',
            body: 'Settings includes Delete all app data. It removes active '
                'financial records, budgets, your local theme preference and '
                'known older preference copies on this installation. '
                'Previously exported backups, copied CSV files and other '
                'copies you created are not deleted. Device and operating '
                'system backups may also be managed separately.',
          ),
          const _PolicySection(
            title: 'Security',
            body: 'The Android database itself is not encrypted at rest, '
                'and this release does not offer an in-app PIN or biometric '
                'lock. Use your device screen lock and handle backup files '
                'with care.',
          ),
          const _PolicySection(
            title: 'Contact',
            body: 'Developer: $spendWiseDeveloperName\n'
                'Privacy questions: $spendWiseSupportEmail',
          ),
          const SizedBox(height: 8),
          Text(
              'Please review this policy against the final published '
              'application and its dependencies before release.',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String body;
  const _PolicySection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 19),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
            const SizedBox(height: 6),
            Text(body),
          ],
        ),
      );
}
