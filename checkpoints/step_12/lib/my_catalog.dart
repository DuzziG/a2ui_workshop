// lib/my_catalog.dart
import 'package:a2ui_core/a2ui_core.dart';
import 'package:a2ui_flutter/a2ui_flutter.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart' hide ValidationResult;

// 1. Describe the component: its name and the properties Gemini may set.
//    Gemini reads this schema and the descriptions in its prompt.
final potionBottle = ComponentImplementation(
  name: 'PotionBottle',
  schema: Schema.object(
    description: 'A glass potion bottle filled with a colored liquid.',
    properties: {
      'color': _dynamic('String', 'The liquid color as a hex code, such as #7B2FF7.'),
      'fill': _dynamic('Number', 'How full the bottle is, from 0 (empty) to 1 (full).'),
      'label': _dynamic('String', 'A short label written under the bottle.'),
    },
    required: ['color', 'fill'],
  ),
  // 2. Build it: the resolved properties in, a Flutter widget out.
  builder: (context, node, props, buildChild) {
    final color = _parseHex(props.string('color'));
    final fill = (props.number('fill') ?? 1).clamp(0, 1).toDouble();
    return Column(
      children: [
        // Animate the liquid when Gemini changes the fill.
        TweenAnimationBuilder<double>(
          tween: Tween(end: fill),
          duration: const Duration(milliseconds: 800),
          builder: (context, value, _) => CustomPaint(
            size: const Size(100, 140),
            painter: _BottlePainter(color: color, fill: value),
          ),
        ),
        if (props.string('label') case final label?) Text(label, style: Theme.of(context).textTheme.labelLarge),
      ],
    );
  },
);

// 3. Your own catalog, which sits next to the basic one.
final myCatalog = CatalogImplementation(
  id: 'https://example.com/potion_lab/catalog.json',
  protocolVersion: A2uiProtocolVersion.v1_0,
  components: [potionBottle],
);

// A value Gemini can give as a literal or bind to the data model, with a description.
Schema _dynamic(String type, String description) =>
    Schema.fromMap({r'$ref': 'common_types.json#/\$defs/Dynamic$type', 'description': description});

Color _parseHex(String? hex) {
  final value = int.tryParse((hex ?? '').replaceFirst('#', ''), radix: 16);
  return value == null ? Colors.purple : Color(0xFF000000 | value);
}

// Draws a round flask with a neck, filled from the bottom.
class _BottlePainter extends CustomPainter {
  _BottlePainter({required this.color, required this.fill});
  final Color color;
  final double fill;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.62);
    final radius = size.width * 0.45;
    final neck = Rect.fromCenter(center: Offset(size.width / 2, size.height * 0.2), width: size.width * 0.3, height: size.height * 0.3);
    // One outline: the round body and the neck merged together.
    final bottle = Path.combine(
      PathOperation.union,
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
      Path()..addRect(neck),
    );

    // The liquid: a rectangle that rises from the bottom of the round body,
    // clipped to the bottle's shape.
    canvas.save();
    canvas.clipPath(bottle);
    final top = center.dy + radius - 2 * radius * fill;
    canvas.drawRect(Rect.fromLTRB(0, top, size.width, size.height), Paint()..color = color);
    canvas.restore();

    // The glass outline and a cork.
    canvas.drawPath(bottle, Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = Colors.blueGrey);
    canvas.drawRect(Rect.fromLTWH(neck.left - 4, 0, neck.width + 8, size.height * 0.08), Paint()..color = Colors.brown);
  }

  @override
  bool shouldRepaint(_BottlePainter old) => old.color != color || old.fill != fill;
}
