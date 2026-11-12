import 'package:material_ui/material_ui.dart';

/// Reusable SpendWise brand symbol. Register assets/branding/ in pubspec.yaml.
class SpendWiseBrandLogo extends StatelessWidget {
  const SpendWiseBrandLogo({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/branding/spendwise_launcher.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        semanticLabel: 'SpendWise logo',
      );
}

/// Full SpendWise logo for onboarding or an About screen.
class SpendWiseWordmark extends StatelessWidget {
  const SpendWiseWordmark({super.key, this.width = 220});

  final double width;

  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/branding/spendwise_wordmark.png',
        width: width,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        semanticLabel: 'SpendWise',
      );
}
