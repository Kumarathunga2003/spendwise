import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// A native Flutter chart: no chart packages, network calls, or sample data.
class SpendDonut extends StatelessWidget {
  const SpendDonut(
      {super.key,
      required this.values,
      required this.total,
      required this.colors});
  final List<double> values;
  final List<Color> colors;
  final double total;

  @override
  Widget build(BuildContext context) => Semantics(
        label:
            'Expenses total ${money(total)}, across ${values.length} categories',
        child: SizedBox(
          width: 188,
          height: 188,
          child: Stack(alignment: Alignment.center, children: [
            CustomPaint(
              size: const Size(184, 184),
              painter: _DonutPainter(values: values, colors: colors),
            ),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text('SPENT', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 4),
              SizedBox(
                  width: 131,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(money(total),
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800)),
                  )),
            ]),
          ]),
        ),
      );
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.values, required this.colors});
  final List<double> values;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (sum, v) => sum + v);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 13;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final background = Paint()
      ..color = SpendColors.teal.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 19;
    canvas.drawCircle(center, radius, background);
    if (total <= 0) return;
    var start = -math.pi / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 19;
    for (var index = 0; index < values.length; index++) {
      final sweep = values[index] / total * math.pi * 2;
      final padding = math.min(0.022, sweep / 5);
      paint.color = colors[index % colors.length];
      if (sweep > padding * 2) {
        canvas.drawArc(
            rect, start + padding, sweep - padding * 2, false, paint);
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.values.toString() != values.toString() ||
      old.colors.toString() != colors.toString();
}
