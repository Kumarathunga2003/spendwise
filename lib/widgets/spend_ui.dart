import 'package:material_ui/material_ui.dart';
import '../theme/app_theme.dart';

IconData categoryIcon(String category) {
  switch (category.toLowerCase()) {
    case 'food':
      return Icons.restaurant_rounded;
    case 'groceries':
      return Icons.shopping_basket_rounded;
    case 'transport':
      return Icons.directions_bus_rounded;
    case 'shopping':
      return Icons.shopping_bag_rounded;
    case 'bills':
      return Icons.receipt_long_rounded;
    case 'education':
      return Icons.school_rounded;
    case 'health':
      return Icons.favorite_rounded;
    case 'entertainment':
      return Icons.movie_rounded;
    case 'salary':
      return Icons.work_rounded;
    case 'freelance':
      return Icons.laptop_mac_rounded;
    case 'business':
      return Icons.storefront_rounded;
    case 'gifts':
      return Icons.card_giftcard_rounded;
    default:
      return Icons.account_balance_wallet_rounded;
  }
}

class SpendSectionHeader extends StatelessWidget {
  const SpendSectionHeader(
      {super.key, required this.title, this.subtitle, this.action});
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ])),
          if (action != null) action!,
        ],
      );
}

class SpendIconBadge extends StatelessWidget {
  const SpendIconBadge(
      {super.key, required this.icon, required this.color, this.size = 44});
  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final foreground =
        dark && color == SpendColors.teal ? SpendColors.mint : color;
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: dark ? 0.18 : 0.11),
        borderRadius: BorderRadius.circular(size * 0.33),
      ),
      child: Icon(icon, color: foreground, size: size * 0.48),
    );
  }
}

class SpendEmptyState extends StatelessWidget {
  const SpendEmptyState(
      {super.key,
      required this.title,
      required this.message,
      this.icon = Icons.inbox_outlined,
      this.action});
  final String title;
  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(children: [
            SpendIconBadge(
                icon: icon,
                color: Theme.of(context).colorScheme.primary,
                size: 62),
            const SizedBox(height: 14),
            Text(title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
            if (action != null) ...[const SizedBox(height: 14), action!],
          ]),
        ),
      );
}

class SpendMonthSelector extends StatelessWidget {
  const SpendMonthSelector(
      {super.key,
      required this.label,
      required this.onPrevious,
      required this.onNext});
  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          child: Row(children: [
            IconButton(
                tooltip: 'Previous month',
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left_rounded)),
            Expanded(
                child: Column(children: [
              Text('SELECTED MONTH',
                  style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 4),
              Text(label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium),
            ])),
            IconButton(
                tooltip: 'Next month',
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right_rounded)),
          ]),
        ),
      );
}

class SpendProgress extends StatelessWidget {
  const SpendProgress(
      {super.key,
      required this.value,
      this.color = SpendColors.teal,
      this.height = 9,
      this.label});
  final double value;
  final Color color;
  final double height;
  final String? label;

  @override
  Widget build(BuildContext context) => Semantics(
        label: label ?? 'Progress ${(value * 100).toStringAsFixed(0)} percent',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0).toDouble(),
            minHeight: height,
            color: color,
            backgroundColor: color.withValues(alpha: 0.14),
          ),
        ),
      );
}

class SpendPill extends StatelessWidget {
  const SpendPill(
      {super.key,
      required this.label,
      this.icon,
      this.color = SpendColors.teal});
  final String label;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).brightness == Brightness.dark &&
            color == SpendColors.teal
        ? SpendColors.mint
        : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: foreground.withValues(alpha: 0.12),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, color: foreground, size: 15),
          const SizedBox(width: 5),
        ],
        Text(label,
            style: TextStyle(
                color: foreground, fontSize: 11, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}
