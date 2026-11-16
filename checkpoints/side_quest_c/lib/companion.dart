// lib/companion.dart
import 'dart:math';
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:flutter/material.dart' hide Material;
import 'package:flutter_scene/scene.dart';
import 'package:json_schema_builder/json_schema_builder.dart' hide ValidationResult;
import 'package:vector_math/vector_math.dart' as vm;

// A little 3D creature, built from spheres, whose mood the agent controls.
final companion = ComponentImplementation(
  name: 'Companion',
  schema: Schema.object(
    description: "The agent's 3D companion. It acts out its mood.",
    properties: {
      'mood': Schema.fromMap({
        r'$ref': r'common_types.json#/$defs/DynamicString',
        'description': 'One of: happy, excited, sleepy, grumpy.',
      }),
      'color': Schema.fromMap({
        r'$ref': r'common_types.json#/$defs/DynamicString',
        'description': 'Its body color as a hex code, such as #4CAF50.',
      }),
    },
    required: ['mood'],
  ),
  builder: (context, node, props, buildChild) => SizedBox(
    height: 180,
    child: CompanionView(mood: props.string('mood') ?? 'happy', color: props.string('color') ?? '#4CAF50'),
  ),
);

class CompanionView extends StatefulWidget {
  const CompanionView({super.key, required this.mood, required this.color});
  final String mood;
  final String color;

  @override
  State<CompanionView> createState() => _CompanionViewState();
}

class _CompanionViewState extends State<CompanionView> {
  final _scene = Scene();
  final _creature = Node(); // Moves as one: the body and eyes are its children.
  final _bodyMaterial = PhysicallyBasedMaterial();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    // The shaders load first, then we build the creature from spheres.
    Scene.initializeStaticResources().then((_) {
      final white = PhysicallyBasedMaterial()..baseColorFactor = vm.Vector4(1, 1, 1, 1);
      final black = PhysicallyBasedMaterial()..baseColorFactor = vm.Vector4(0.05, 0.05, 0.05, 1);
      _creature.add(Node(mesh: Mesh(SphereGeometry(radius: 0.8), _bodyMaterial)));
      for (final side in [-1.0, 1.0]) {
        _creature.add(Node(mesh: Mesh(SphereGeometry(radius: 0.22), white))..position = vm.Vector3(0.3 * side, 0.25, -0.65));
        _creature.add(Node(mesh: Mesh(SphereGeometry(radius: 0.1), black))..position = vm.Vector3(0.3 * side, 0.25, -0.85));
      }
      _scene.add(_creature);
      if (mounted) setState(() => _ready = true);
    });
  }

  // Runs every frame: move the creature the way its mood says.
  void _act(Duration elapsed, double deltaSeconds) {
    final hex = int.tryParse(widget.color.replaceFirst('#', ''), radix: 16) ?? 0x4CAF50;
    _bodyMaterial.baseColorFactor = vm.Vector4(((hex >> 16) & 0xFF) / 255, ((hex >> 8) & 0xFF) / 255, (hex & 0xFF) / 255, 1);

    final t = elapsed.inMilliseconds / 1000;
    final (bounce, spin, squash) = switch (widget.mood) {
      'excited' => ((sin(t * 12) * 0.4).abs(), t * 4, 1.0),
      'sleepy' => (0.0, sin(t) * 0.2, 0.85 + sin(t * 1.5) * 0.05),
      'grumpy' => (0.0, sin(t * 30) * 0.08, 0.9),
      _ => ((sin(t * 5) * 0.2).abs(), sin(t * 2) * 0.4, 1.0), // happy
    };
    _creature.position = vm.Vector3(0, bounce - 0.2, 0);
    _creature.rotation = vm.Quaternion.axisAngle(vm.Vector3(0, 1, 0), spin);
    _creature.scale = vm.Vector3(1, squash, 1);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const Center(child: CircularProgressIndicator());
    return SceneView(
      _scene,
      camera: PerspectiveCamera(position: vm.Vector3(0, 0.4, -3.2), target: vm.Vector3(0, 0, 0)),
      onTick: _act,
    );
  }
}
