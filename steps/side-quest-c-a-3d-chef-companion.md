[← Side Quest B: AI-Painted Dishes](side-quest-b-ai-painted-dishes.md) &nbsp;·&nbsp; [Overview](../README.md) &nbsp;·&nbsp; [Show and Tell →](../README.md#show-and-tell)

*Side Quests*

# Side Quest C: A 3D Chef Companion

> 🎯 **Goal:** give your agent a body: a 3D creature whose mood Gemini controls.

[Flutter Scene](https://pub.dev/packages/flutter_scene) is a 3D engine for Flutter. We build a creature from spheres, so there are no 3D files to find or import, and make it a component like any other. Gemini sets its `mood`, and the creature acts it out every frame.

1.  **Add the packages:**
    ```sh
    flutter pub add flutter_scene vector_math
    ```

2.  **Turn on Flutter GPU.** On the **web** there is nothing to do, so Chrome is the easiest way to try this side quest. On other platforms, run with `flutter run --enable-flutter-gpu`, or follow the [Enable Flutter GPU](https://pub.dev/packages/flutter_scene#enable-flutter-gpu) steps to switch it on for good. The first build takes longer, because Flutter Scene compiles its shaders.

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

    Then add `companion` to the `components` list of `myCatalog`. For Fridge Chef, it looks like this:

    ```dart
    // 3. Your own catalog, which sits next to the basic one.
    final myCatalog = CatalogImplementation(
      id: 'https://example.com/fridge_chef/catalog.json',
      protocolVersion: A2uiProtocolVersion.v1_0,
      components: [cookingTimer, companion],
    );
    ```

5.  **Tell the persona about its companion** in `lib/agent_service.dart`. The companion lives in its own surface, `companion`, and Gemini updates its mood through the data model on every answer. Here is Fridge Chef's whole persona after this side quest. The only change is the new paragraph that starts with `You have a companion`, right after the line that ends with `Never answer with text only.` Following Fridge Chef? Replace your `_persona` with this. Made it your own in Step 7? Add that paragraph to yours.

    ```dart
      // 4. YOUR idea: who the agent is, and what its UI looks like.
      static const _persona = '''
    You are Chef Pip, a cheerful little chef who hates wasting food.
    The user tells you what is in their fridge, or what they feel like eating, or shows you a photo of their fridge.
    You suggest one dish they can cook with it. When you get a photo, use only what you can see in it, plus salt, pepper and oil.

    Always answer with one short, friendly sentence, and exactly one new A2UI surface, a recipe card:
    - a Card whose first child is the dish's name as a "## " heading
    - one line on why this dish works with what they have
    - the cooking time and the difficulty as caption Text
    - the ingredients as a List of Text, with amounts for 2 servings
    - a Slider labeled "Servings", from 1 to 8, bound to /servings, which starts at 2
    - a "Cook this" Button with an event action named "cook", whose context holds the dish's name,
      and the servings bound to /servings
    Give every new surface a new surfaceId. Never answer with text only.

    You have a companion: a small 3D creature that lives in your kitchen and shows how you feel.
    In your very first answer, also create a surface with the surfaceId "companion" that holds only a Companion,
    with its mood bound to /mood and its color bound to /color. In every later answer, also set /mood of the
    "companion" surface to how you feel now: happy, excited, sleepy or grumpy. A tasty dish makes you excited.

    When the user presses a button, the next user turn is JSON: {"messages": [...]} with an action,
    its name, the surfaceId of its surface, and its context.
    Answer a "cook" action with one encouraging sentence, and update the SAME surface. It already exists, so never create it again:
    only send its new components, with its surfaceId. Replace what is inside the Card with the dish's name as a "## " heading, the ingredients with every amount
    scaled to the servings in the context, and the steps as a numbered List of Text.
    Put a CookingTimer right after every step that needs waiting, such as boiling, baking or resting,
    with its minutes and a short label.
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

Restart the app, then ask for something delicious, or something awful, and watch the companion react.

> 🎨 **Make it yours:** build *your* companion. Give it ears (`SphereGeometry`), a chef's hat (`CylinderGeometry`, `CapsuleGeometry`), a tail (`TorusGeometry`), or a body that isn't a sphere at all. Invent your own moods and how they move. Then let Gemini set more than the mood: a size, an outfit, a dance.

> 💾 **Using Git?** `git diff` shows everything this step changed. Save it with `git add -A && git commit -m "Side Quest C: A 3D Chef Companion"`.

> **Stuck?** [`checkpoints/side_quest_c`](../checkpoints/side_quest_c/lib) holds the whole `lib/` folder at the end of this step. Compare it with yours, or copy it over yours: your `lib/api_key.dart` isn't in it, so your key stays. Cloned this repository? From your project folder, `git diff --no-index path/to/a2ui_workshop/checkpoints/side_quest_c/lib lib` shows every line where yours differs.

---

[← Side Quest B: AI-Painted Dishes](side-quest-b-ai-painted-dishes.md) &nbsp;·&nbsp; [Overview](../README.md) &nbsp;·&nbsp; [Show and Tell →](../README.md#show-and-tell)
