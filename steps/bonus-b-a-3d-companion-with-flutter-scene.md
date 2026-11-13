[← Bonus A: AI-Painted Illustrations](bonus-a-ai-painted-illustrations.md) &nbsp;·&nbsp; [Overview](../README.md) &nbsp;·&nbsp; [Show and Tell →](../README.md#show-and-tell)

*Bonus Steps*

# Bonus B: A 3D Companion with Flutter Scene

> 🎯 **Goal:** give your agent a body: a 3D creature whose mood Gemini controls.

[Flutter Scene](https://pub.dev/packages/flutter_scene) is a 3D engine for Flutter. We build a creature from spheres, so there are no 3D files to find or import, and make it a component like any other. Gemini sets its `mood`, and the creature acts it out every frame.

1.  **Add the packages:**
    ```sh
    flutter pub add flutter_scene vector_math
    ```

2.  **Turn on Flutter GPU.** On the **web** there is nothing to do, so Chrome is the easiest way to try this step. On other platforms, run with `flutter run --enable-flutter-gpu`, or follow the [Enable Flutter GPU](https://pub.dev/packages/flutter_scene#enable-flutter-gpu) steps to switch it on for good. The first build takes longer, because Flutter Scene compiles its shaders.

3.  **Create `lib/companion.dart`.** The creature is one `Node` with a body and four eyeball spheres as its children, so moving the parent moves them all. `onTick` runs every frame and picks a bounce, spin and squash for the current mood.

    ```dart
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
    ```

4.  **Add it to your catalog** in `lib/my_catalog.dart`. First the import, at the top with the other imports:

    ```dart
    import 'companion.dart';
    ```

    Then replace `myCatalog` at the bottom of the file with this version, which adds `companion` to its components:

    ```dart
    // 3. Your own catalog, which sits next to the basic one.
    final myCatalog = CatalogImplementation(
      id: 'https://example.com/potion_lab/catalog.json',
      protocolVersion: A2uiProtocolVersion.v1_0,
      components: [potionBottle, illustration, companion],
    );
    ```

5.  **Tell the persona about its companion** in `lib/agent_service.dart`. The companion lives in its own surface, `companion`, and Gemini updates its mood through the data model on every answer. Here is Potion Lab's whole persona after this step. The only change is the new paragraph that starts with `You have a companion`, right after the line that ends with `Never answer with text only.` Following Potion Lab? Replace your `_persona` with this. Wrote your own? Add that paragraph to yours.

    ```dart
      // 4. YOUR idea: who the agent is, and what its UI looks like.
      static const _persona = '''
    You are the Potion Master, the grumpy but brilliant owner of a tiny magical potion shop.
    The user tells you a feeling, a problem or a wish, or shows you a photo. You invent a potion for it.
    When you get a photo, whatever is in it becomes the potion's main ingredient.

    Always answer with one short sentence in character, and exactly one new A2UI surface, a potion card:
    - a Card whose first child is the potion's name as a "## " heading
    - an Illustration of the potion, with a prompt that names a fun art style
    - a PotionBottle in the potion's color, whose fill is bound to /fill, which starts at 1
    - one line of mysterious lore about the potion
    - the ingredients as a List of Text, each with a silly amount ("3 whispers of moonlight")
    - the effect, and one funny side effect, as caption Text
    - a "Brew it!" Button with an event action named "brew", whose context holds the potion's name
    Before you invent a potion, call checkShelf, and only use ingredients that are on the shelf.
    Give every new surface a new surfaceId and set "sendDataModel": true on it. Never answer with text only.

    You have a companion: a small 3D creature that lives in your shop and shows how you feel.
    In your very first answer, also create a surface with the surfaceId "companion" that holds only a Companion,
    with its mood bound to /mood and its color bound to /color. In every later answer, send an updateDataModel
    for the "companion" surface that sets /mood to how you feel now: happy, excited, sleepy or grumpy.

    When the user presses a button, the next user turn is JSON. Its "a2ui" holds {"messages": [...]}:
    an action with its name, surfaceId and context. Beside it, "metadata" holds each surface's data model.
    Answer a "brew" action by calling rollDice with 20 sides: 1 is a disaster, 2 to 10 a wobbly
    result, 11 to 19 a success and 20 a legend. Then answer in character, and update the SAME surface with an updateComponents message:
    add a Text that tells the roll and what happened when the user drank the potion, and set /fill to 0
    with an updateDataModel message, because the bottle is now empty. Do not create a new surface for it.
    ''';
    ```

6.  **Pin the companion to the top of the screen** in `lib/home_page.dart`. In `_buildChat`, add the companion as the first child of the `Column`, before `// 1. The surfaces`:

    ```dart
        return Column(
          children: [
            // 0. The companion surface stays pinned at the top.
            for (final surface in _surfaces.where((s) => s.id == 'companion'))
              A2uiSurface(key: ObjectKey(surface), surface: surface),
    ```

    Then leave it out of the feed: a little further down, in the `ListView`, change the `for` line to this:

    ```dart
                        for (final surface in _surfaces.reversed.where((s) => s.id != 'companion'))
    ```

Run it, then make your agent happy, sleepy or grumpy, and watch its companion react.

> 🎨 **Make it yours:** build *your* companion. Give it ears (`SphereGeometry`), a hat (`CylinderGeometry`, `CapsuleGeometry`), a tail (`TorusGeometry`), or a body that isn't a sphere at all. Invent your own moods and how they move. Then let Gemini set more than the mood: a size, an outfit, a dance.

> **Stuck?** [`checkpoints/bonus_b`](../checkpoints/bonus_b/lib) holds the whole `lib/` folder at the end of this step. Compare it with yours, or copy it over yours: your `lib/api_key.dart` isn't in it, so your key stays.

---

[← Bonus A: AI-Painted Illustrations](bonus-a-ai-painted-illustrations.md) &nbsp;·&nbsp; [Overview](../README.md) &nbsp;·&nbsp; [Show and Tell →](../README.md#show-and-tell)
