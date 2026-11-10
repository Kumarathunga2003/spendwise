# SpendWise

### Keep track of your money, one day at a time.

SpendWise is a personal finance app I’m building with Flutter. It helps you keep a record of what you earn, see where your money goes, and plan your monthly spending.

You can check your balance, add daily expenses, and set budgets for different categories—all in one place. The app stores your records on your device, so there’s no account to create.

**Developer:** Gaweesha  
**Current UI version:** 2.0  
**Main platform:** Android

## What you can do

- See your total income, expenses, and remaining balance.
- Add, edit, or delete transactions.
- Group transactions into categories and add notes.
- Look back through your transaction history.
- Set monthly budgets for each spending category.
- Check monthly reports and category spending.
- Choose a light or dark theme.
- Copy your transactions as CSV to use in a spreadsheet.

## Tools used

The app is built with **Flutter and Dart**, using Material Design components. You can find the packages and SDK requirements in [`pubspec.yaml`](pubspec.yaml).

## Run the project

You’ll need Flutter, Git, and the Android SDK installed. You can use VS Code or Android Studio to work on the code, and either an Android emulator or a phone with USB debugging enabled to run it.

### 1. Download the code

```bash
git clone https://github.com/Kumarathunga2003/spendwise.git
cd spendwise
```

If the repository is private, you’ll need to sign in with a GitHub account that has access.

### 2. Install the packages

```bash
flutter pub get
```

### 3. Check your setup

```bash
flutter doctor
flutter devices
```

`flutter doctor` helps you spot missing setup steps. `flutter devices` lists the devices you can run the app on.

### 4. Start the app

Replace `DEVICE_ID` with your Android device’s ID from the previous command:

```bash
flutter run -d DEVICE_ID
```

## Check the code

Run these commands to check for code issues and run the automated tests:

```bash
flutter analyze
flutter test
```

## Build an APK

To create a release APK, run:

```bash
flutter build apk --release
```

You’ll find the file here:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Before distributing the app, set up your own release signing. Keep your signing files private. Updates to an existing installation need the same application ID and signing key.

## Where to find things

| Folder or file | What’s inside |
| --- | --- |
| `lib/main.dart` | Where the app starts |
| `lib/data/` | App state and saved data handling |
| `lib/models/` | Transaction and budget models |
| `lib/screens/` | The app’s main pages |
| `lib/widgets/` | Components used across different pages |
| `lib/theme/` | Colors and themes |
| `lib/utils/` | Formatting and other helpers |
| `assets/branding/` | SpendWise logos, icons, and splash images |
| `android/` | Android project settings |
| `test/` | Automated tests |

## Your data

Your financial records stay on your device. There’s no account system or cloud sync.

Keep a backup before uninstalling the app or clearing its storage, as those actions can remove your records. CSV exports include transactions only; they don’t include budgets or preferences, and they aren’t encrypted.

Use your phone’s screen lock to help protect access. Storing records locally doesn’t, by itself, mean they are encrypted. Uploading the project to GitHub saves the source code, not the financial records inside the app. Personal backups, exports, passwords, and signing keys should stay out of this repository.

## Ideas for later

I plan to keep improving SpendWise. Some features I’d like to add are:

- PIN and fingerprint or face unlock
- Automatic locking when you leave the app
- Better protection for saved records
- Separate wallets for cash and bank accounts
- Recurring income and expenses

These are future plans and aren’t included in the current version.

## About the version

The Settings screen currently shows **UI refresh 2.0**. This is the interface label; the package version is listed separately in `pubspec.yaml`.

## Author

Built by **Gaweesha**.  
GitHub: [@Kumarathunga2003](https://github.com/Kumarathunga2003)

## License

A license hasn’t been added yet. All rights are reserved by the author.
