# SpendWise — Complete Flutter source package

A functional, offline personal finance tracker suitable for a Flutter coursework/demo project. **This package is meant to be merged into the existing `spendwise` Flutter project**. It is not a replacement for Flutter's generated `android`, `ios`, `windows`, `web`, or other platform folders.

## Features

- Home dashboard: all-time balance, this month's income and expenses, recent transactions.
- Transaction history: add, edit, delete, search, filter by income/expense.
- Transaction details: amount (LKR), date, type, category, optional note.
- Monthly budgets: reusable limits for each expense category, progress and overspending warnings.
- Reports: monthly income, expenses, net cash flow, category spending, six-month income/expense chart.
- Settings: light/dark theme and copy transactions as a CSV backup.
- Persistent **local** data using Flutter `shared_preferences` (Android, iOS, web, desktop).
- Responsive Flutter Material UI. No sign-in or cloud service required.

## Step 1 — Back up your current project

In Windows File Explorer, make a copy of:

`C:\Users\Gaweesha\Desktop\Projects\spendwise`

Your current browser demo transactions are **not yet saved**; before replacing the app, manually note the sample transactions and re-enter them after installing this version.

## Step 2 — Copy in the source

1. Extract `SpendWise_Complete_Flutter_Source.zip` to a folder.
2. Open your existing `spendwise` folder in VS Code.
3. Copy the **contents** of the extracted `lib` folder into your existing `spendwise/lib` folder, allowing overwrites of `lib/main.dart`.
4. Replace the existing `spendwise/pubspec.yaml` with the provided `pubspec.yaml` (back up your original first).
5. Replace the starter files in `spendwise/test` with the provided tests (the original `widget_test.dart` tests the Flutter counter app and is no longer relevant).
6. Keep all existing platform folders (`android`, `ios`, `web`, and so on). Keep `pubspec.lock`; `flutter pub get` will update it as needed.

The extra `lib/oracleJdk-27` folder from your earlier project is not required by this app. **Do not delete it until you have made a backup and confirmed you have another working JDK installation.**

New source layout:

```
lib/
  main.dart
  data/app_store.dart
  models/money_transaction.dart
  screens/
    home_shell.dart
    dashboard_page.dart
    transactions_page.dart
    budgets_page.dart
    reports_page.dart
    settings_page.dart
  theme/app_theme.dart
  utils/formatters.dart
  widgets/
    transaction_form.dart
    transaction_tile.dart
```

## Step 3 — Run in Chrome

From the VS Code terminal **inside your original `spendwise` folder**:

```powershell
flutter pub get
flutter analyze
flutter test
flutter run -d chrome --web-port=5000
```

If the old counter app is already running, press `q` in its terminal, then run the new app again. A **full restart** is preferable after adding a new plugin (`shared_preferences`).

## Step 4 — Run on Android

```powershell
flutter emulators
```

Launch an available emulator using its displayed ID:

```powershell
flutter emulators --launch <EMULATOR_ID>
flutter devices
flutter run -d <DEVICE_ID>
```

Alternatively, connect an Android phone with developer options / USB debugging enabled and choose its device ID shown by `flutter devices`.

## How to test

1. Home → Add transaction → enter Salary, 5000, Income → Save.
2. Add Food, 2000, Expense → Save. Balance should be Rs. 3,000.00.
3. History → Edit Food; confirm the dashboard changes. Delete it and check totals.
4. Budgets → Set Food limit to Rs. 1,000.00, then add a Food expense of Rs. 2,000.00. A warning should appear.
5. Reports → View monthly totals and chart.
6. Stop the app and run it again with the same `--web-port=5000`. Transactions should still be present if browser site storage has not been cleared.
7. Settings → Copy transactions as CSV → paste into a text file and save the file as `.csv` if you need a basic manual export.

## Storage and limitations

- `shared_preferences` is intended for small, simple local data. It is **not a database intended for large or sensitive financial records** and does not guarantee durable backups.
- Entries and budgets are **per local installation / browser origin**. Flutter web debug servers often pick a new random port each run, which changes the browser origin. Always use `flutter run -d chrome --web-port=5000` when testing storage in Chrome. Chrome and your Android phone do not sync. Clearing browser storage or uninstalling the app may delete data.
- The CSV feature **copies text to the clipboard**; it does not directly create a file or support re-import.
- Budget limits apply to categories and repeat each month, while spending is calculated separately for the selected month.
- No bank API, multi-user login, notifications, encryption, authentication, or cloud backup is included.
- For production use, add an appropriate database, backups, encryption/security review, and financial rounding rules (e.g. store amounts as integer cents).

## Dependency

`shared_preferences: ^2.5.3` in `pubspec.yaml`. `flutter pub get` picks a compatible version for your installed SDK. This plugin supports the existing browser/desktop and mobile target platforms.

## Tests

Pure model and formatter tests live in `test/transaction_model_test.dart` and `test/widget_test.dart`. No device is required to run them via `flutter test`.

## Troubleshooting

- **Missing package**: run `flutter pub get` from the project root, not from inside `lib`.
- **Default Flutter Demo still appears**: make sure the `lib/main.dart` in your **existing** project was replaced, then stop the process and run `flutter run -d chrome --web-port=5000` again.
- **Storage plugin error after hot reload**: stop and fully restart the app.
- **Package or SDK incompatibility**: try `flutter pub add shared_preferences` in your project to get a compatible version, then `flutter pub get`.
- **Old test mentions MyApp / increment counter**: replace `test/widget_test.dart` with the version in this ZIP.

