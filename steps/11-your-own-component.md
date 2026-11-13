[← Step 10: Rules the AI Can't Bend](10-rules-the-ai-cant-bend.md) &nbsp;·&nbsp; [Overview](../README.md) &nbsp;·&nbsp; [Step 12: Stream the UI →](12-stream-the-ui.md)

*Part 4: Make It Truly Yours · Step 11 of 12*

# Step 11: Your Own Component

> 🎯 **Goal:** design and draw a widget, and let Gemini use it like any built-in one.

The basic catalog only gets you so far. Now you add a component that exists only in *your* app. You write three things:

1.  a **schema**: its name and the properties Gemini may set, each with a description. Gemini reads this in its prompt.
2.  a **builder**: turns those properties into a Flutter widget. You can use any Flutter you like here.
3.  a **catalog**: your components, with an id of your own, registered next to the basic catalog.

Potion Lab draws a `PotionBottle` with a `CustomPainter`. The `fill` property is bound to the data model, so when Gemini sets `/fill` to 0 after a brew, the liquid drains away with an animation.

1.  **Create `lib/my_catalog.dart`.** The schema is written with `json_schema_builder`, which you added in Step 2:

    ```dart
    // lib/my_catalog.dart
    import 'package:a2ui_core/a2ui_core.dart';
    import 'package:a2ui_flutter/a2ui_flutter.dart';
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
    ```

2.  **Register your catalog in `lib/agent_service.dart`.** Add the import at the top, with the other imports:

    ```dart
    import 'my_catalog.dart';
    ```

    Replace parts 1 to 3 (from `// 1. The catalog` down to the end of `_a2uiAgent`) with this version, which uses both catalogs everywhere the basic one was:

    ```dart
      // 1. The catalogs: every component the app can draw. Yours comes after the basic one.
      static final _catalogs = [basicCatalog(), myCatalog];

      // 2. The renderer: it applies A2UI messages and remembers every surface.
      final processor = MessageProcessor<ComponentImplementation>(catalogs: _catalogs);

      // 3. The A2UI agent kit: writes a prompt that teaches Gemini our catalogs,
      //    and checks Gemini's reply against them.
      final _a2uiAgent = A2uiGenerator(
        catalogs: [for (final catalog in _catalogs) CatalogConfig(catalog)],
        inferenceFormatFactory: const DirectJsonFormatFactory(),
      ).createProcessor(
        A2uiRendererCapabilities.forCatalogIds([for (final catalog in _catalogs) catalog.id], version: A2uiProtocolVersion.v1_0),
      );
    ```

    Then tell your persona about your component. Here is Potion Lab's whole persona after this step. Two things changed: a new line in the list of what goes on the card asks for the `PotionBottle`, and the paragraph about the `brew` action now asks Gemini to empty the bottle with an `updateDataModel`. Following Potion Lab? Replace your `_persona` with this. Wrote your own? Make the same two changes to yours: ask for your component, and say when Gemini should update it.

    ```dart
      // 4. YOUR idea: who the agent is, and what its UI looks like.
      static const _persona = '''
    You are the Potion Master, the grumpy but brilliant owner of a tiny magical potion shop.
    The user tells you a feeling, a problem or a wish, or shows you a photo. You invent a potion for it.
    When you get a photo, whatever is in it becomes the potion's main ingredient.

    Always answer with one short sentence in character, and exactly one new A2UI surface, a potion card:
    - a Card whose first child is the potion's name as a "## " heading
    - a PotionBottle in the potion's color, whose fill is bound to /fill, which starts at 1
    - one line of mysterious lore about the potion
    - the ingredients as a List of Text, each with a silly amount ("3 whispers of moonlight")
    - the effect, and one funny side effect, as caption Text
    - a "Brew it!" Button with an event action named "brew", whose context holds the potion's name
    Before you invent a potion, call checkShelf, and only use ingredients that are on the shelf.
    Give every new surface a new surfaceId and set "sendDataModel": true on it. Never answer with text only.

    When the user presses a button, the next user turn is JSON. Its "a2ui" holds {"messages": [...]}:
    an action with its name, surfaceId and context. Beside it, "metadata" holds each surface's data model.
    Answer a "brew" action by calling rollDice with 20 sides: 1 is a disaster, 2 to 10 a wobbly
    result, 11 to 19 a success and 20 a legend. Then answer in character, and update the SAME surface with an updateComponents message:
    add a Text that tells the roll and what happened when the user drank the potion, and set /fill to 0
    with an updateDataModel message, because the bottle is now empty. Do not create a new surface for it.
    ''';
    ```

Run it. Every potion now comes in a bottle of its own color, and brewing empties it.

> 🧠 **What just happened:** Gemini never saw your Dart code, only your schema and its descriptions. That was enough for it to use the component, pick a color and bind the fill. The builder decides how it looks; Gemini decides when and with what values.

> 🎨 **Make it yours:** this is the most important challenge of the workshop. Design the one widget that makes your app *yours*:
> * a **health bar** or **mood meter** that fills and changes color
> * a **dice** face, a **card** from a deck, a **map** with a marker
> * a **pet** drawn from circles that looks happy or sad
> * a **countdown** ring, a **trophy**, a **progress** path
>
> Start from the bottle: change the painter, rename the properties, and write good descriptions so Gemini knows what they mean. To level up, make it interactive: read about `props.writable` and `props.action` in the [a2ui_flutter docs](https://pub.dev/packages/a2ui_flutter#defining-custom-components).

> **Stuck?** [`checkpoints/step_11`](../checkpoints/step_11/lib) holds the whole `lib/` folder at the end of this step. Compare it with yours, or copy it over yours: your `lib/api_key.dart` isn't in it, so your key stays.

---

[← Step 10: Rules the AI Can't Bend](10-rules-the-ai-cant-bend.md) &nbsp;·&nbsp; [Overview](../README.md) &nbsp;·&nbsp; [Step 12: Stream the UI →](12-stream-the-ui.md)
