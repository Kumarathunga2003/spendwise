import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendwise/theme/app_theme.dart';
import 'package:spendwise/widgets/spend_ui.dart';

void main() {
  for (final width in <double>[320, 390, 600]) {
    testWidgets('Design components fit a ${width.toInt()}px viewport',
        (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SpendSectionHeader(
                    title: 'Recent activity',
                    subtitle: 'Your latest money movements',
                  ),
                  const SizedBox(height: 16),
                  SpendEmptyState(
                    title: 'Your activity starts here',
                    message:
                        'Add income or expenses to see your financial history.',
                  ),
                  const SizedBox(height: 16),
                  SpendMonthSelector(
                    label: 'November 2026',
                    onPrevious: _noop,
                    onNext: _noop,
                  ),
                ],
              ),
            ),
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
      expect(find.text('Your activity starts here'), findsOneWidget);
    });
  }
}

void _noop() {}
