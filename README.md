# SpendWise

**A simple way to understand your money.**

SpendWise is a Flutter personal finance app that helps you track income, manage expenses, and set monthly budgets. It brings your balance, spending history, and category budgets together in a clean interface with light and dark themes.

Built by **Gaweesha** · Current UI version: **2.0** · Primary target: **Android**

## Features

- **Balance overview** — See your total income, expenses, and available balance.
- **Transaction management** — Add, edit, and delete income and expense records.
- **Categories and notes** — Organize transactions and add useful details.
- **Transaction history** — Review past income and spending.
- **Monthly budgets** — Set category limits and track spending against them.
- **Reports** — Explore monthly totals and spending by category.
- **Dark mode** — Switch between light and dark themes.
- **CSV export** — Copy transaction records as CSV for use in a spreadsheet.
- **Local storage** — Keep financial records on your device without creating an account.
- **Custom branding** — SpendWise app icon and splash screen.

## Built with

- Flutter and Dart
- Material Design
- Android tooling

See [`pubspec.yaml`](pubspec.yaml) for the project's dependencies and SDK requirements.

## Getting started

### Requirements

- Flutter SDK, including Dart
- Git
- Android SDK and an Android emulator, or an Android phone with USB debugging enabled
- VS Code or Android Studio

### Installation

Clone the repository and install its dependencies:

```bash
git clone https://github.com/Kumarathunga2003/spendwise.git
cd spendwise
flutter pub get
```

The repository is private, so cloning requires a GitHub account with access.

Check your development environment and connected devices:

```bash
flutter doctor
flutter devices
```

Run the app on your Android device or emulator, replacing `DEVICE_ID` with an ID from `flutter devices`:

```bash
flutter run -d DEVICE_ID
```

### Code checks

```bash
flutter analyze
flutter test
```

### Build an Android APK

```bash
flutter build apk --release
```

The generated APK is available at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

For distribution, configure your own release signing and keep signing credentials outside version control. When updating an installed app, retain its application ID and signing key to preserve update compatibility.

## Project structure

| Path | Purpose |
| --- | --- |
| `lib/main.dart` | App entry point |
| `lib/data/` | App state and data storage |
| `lib/models/` | Transaction and budget models |
| `lib/screens/` | Dashboard, history, budgets, reports, and settings |
| `lib/theme/` | App colors and themes |
| `lib/utils/` | Formatting and shared helpers |
| `lib/widgets/` | Reusable interface components |
| `assets/branding/` | Logo, app icon, and splash assets |
| `android/` | Android configuration and native resources |
| `test/` | Automated tests |

## Privacy and data

SpendWise keeps financial records locally. It does not require an account or provide cloud synchronization.

- Uninstalling the app or clearing its storage can remove saved records.
- CSV exports contain transactions only, not budgets or preferences, and are not encrypted.
- Local storage alone does not guarantee encryption. Use your device's screen lock to help protect access.
- Saving source code on GitHub does not back up records stored inside the app.
- Keep personal exports, backup files, passwords, and signing keys out of the repository.

## Planned improvements

- PIN and biometric app unlock
- Automatic locking when the app moves into the background
- Stronger protection for locally stored records
- Multiple wallets
- Recurring income and expenses

These are planned features and are not promises of availability in the current version.

## Development status

SpendWise is under active development. The Settings screen currently identifies the interface as **UI refresh 2.0**. Check the source and `pubspec.yaml` when identifying a particular build; the UI label may differ from the package version.

## Author

**Gaweesha**  
GitHub: [@Kumarathunga2003](https://github.com/Kumarathunga2003)

## License

No open-source license has been added yet. All rights are reserved by the author.
