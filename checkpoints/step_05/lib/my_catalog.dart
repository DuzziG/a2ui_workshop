// lib/my_catalog.dart
import 'dart:async';
import 'package:a2ui_core/a2ui_core.dart';
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart' hide ValidationResult;

// 1. Describe the component: its name and the properties Gemini may set.
//    Gemini reads this schema and the descriptions in its prompt.
final cookingTimer = ComponentImplementation(
  name: 'CookingTimer',
  schema: Schema.object(
    description: 'A kitchen countdown timer that the user can start, pause and reset.',
    properties: {
      'minutes': _dynamic('Number', 'How long the timer runs, in minutes, such as 10.'),
      'label': _dynamic('String', 'What the timer is for, such as "Boil the pasta".'),
    },
    required: ['minutes'],
  ),
  // 2. Build it: the resolved properties in, a Flutter widget out.
  builder: (context, node, props, buildChild) => _CookingTimer(
    minutes: props.number('minutes') ?? 5,
    label: props.string('label') ?? 'Timer',
  ),
);

// 3. Your own catalog, which sits next to the basic one.
final myCatalog = CatalogImplementation(
  id: 'https://example.com/fridge_chef/catalog.json',
  protocolVersion: A2uiProtocolVersion.v1_0,
  components: [cookingTimer],
);

// A value Gemini can give as a literal or bind to the data model, with a description.
Schema _dynamic(String type, String description) =>
    Schema.fromMap({r'$ref': 'common_types.json#/\$defs/Dynamic$type', 'description': description});

// The timer itself: a ring that empties as the time runs out.
class _CookingTimer extends StatefulWidget {
  const _CookingTimer({required this.minutes, required this.label});
  final double minutes;
  final String label;

  @override
  State<_CookingTimer> createState() => _CookingTimerState();
}

class _CookingTimerState extends State<_CookingTimer> {
  late int _total = (widget.minutes * 60).round();
  late int _left = _total;
  Timer? _ticker;

  bool get _running => _ticker != null;

  // Gemini changed the minutes: start over.
  @override
  void didUpdateWidget(_CookingTimer old) {
    super.didUpdateWidget(old);
    if (old.minutes != widget.minutes) _reset();
  }

  void _startOrPause() {
    if (_running) {
      _ticker?.cancel();
      setState(() => _ticker = null);
    } else if (_left > 0) {
      setState(() => _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick()));
    }
  }

  void _tick() => setState(() {
    _left--;
    if (_left <= 0) {
      _ticker?.cancel();
      _ticker = null;
    }
  });

  void _reset() {
    _ticker?.cancel();
    setState(() {
      _ticker = null;
      _total = (widget.minutes * 60).round();
      _left = _total;
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final done = _left <= 0;
    final time = '${_left ~/ 60}:${(_left % 60).toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // The ring, with the time left inside it.
          SizedBox.square(
            dimension: 64,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: _total == 0 ? 0 : _left / _total,
                  strokeWidth: 6,
                  backgroundColor: colors.surfaceContainerHighest,
                  color: done ? Colors.green : colors.primary,
                ),
                Center(child: Text(done ? 'Done!' : time, style: const TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(widget.label, style: Theme.of(context).textTheme.titleMedium)),
          IconButton.filledTonal(
            tooltip: _running ? 'Pause' : 'Start',
            onPressed: done ? null : _startOrPause,
            icon: Icon(_running ? Icons.pause : Icons.play_arrow),
          ),
          IconButton(tooltip: 'Reset', onPressed: _reset, icon: const Icon(Icons.replay)),
        ],
      ),
    );
  }
}
