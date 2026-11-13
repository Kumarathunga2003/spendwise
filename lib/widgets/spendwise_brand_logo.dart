import 'package:material_ui/material_ui.dart';

/// The single brand icon used throughout SpendWise.
/// All platforms use the same assets/branding artwork.
class SpendWiseBrandLogo extends StatelessWidget {
  const SpendWiseBrandLogo({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/branding/spendwise_wallet_transparent.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        semanticLabel: 'SpendWise app logo',
        errorBuilder: (context, error, stackTrace) => SizedBox(
          width: size,
          height: size,
          child: const Icon(Icons.account_balance_wallet_outlined),
        ),
      );
}

/// The designed "SpendWise" name artwork, with day and night variants.
class SpendWiseWordmark extends StatelessWidget {
  const SpendWiseWordmark(
      {super.key, this.width = 150, this.onDarkSurface = false});

  final double width;
  final bool onDarkSurface;

  @override
  Widget build(BuildContext context) {
    final light =
        !onDarkSurface && Theme.of(context).brightness == Brightness.light;
    return Image.asset(
      light
          ? 'assets/branding/spendwise_wordmark_light.png'
          : 'assets/branding/spendwise_wordmark.png',
      width: width,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: 'SpendWise',
    );
  }
}

/// Full logo and tagline used for welcoming and app-information layouts.
class SpendWiseBrandLockup extends StatelessWidget {
  const SpendWiseBrandLockup({super.key, this.width = 290});

  final double width;

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SpendWiseBrandLogo(size: width * 0.23),
        SizedBox(width: width * 0.035),
        Flexible(
          child: Image.asset(
            light
                ? 'assets/branding/spendwise_wordmark_tagline_light.png'
                : 'assets/branding/spendwise_wordmark_tagline.png',
            width: width * 0.73,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            semanticLabel: 'SpendWise — Safer everyday money tracking',
          ),
        ),
      ],
    );
  }
}
