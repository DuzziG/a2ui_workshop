[← Step 4: Snap and Cook](04-snap-and-cook.md) &nbsp;·&nbsp; [Overview](../README.md) &nbsp;·&nbsp; [Step 6: Fast →](06-fast.md)

*Part 4: Reliable and Fast · Step 5 of 7*

# Step 5: Your Own Component

> 🎯 **Goal:** design a widget, and let Gemini use it like any built-in one.

The basic catalog only gets you so far: it has no timer, and no icon for food. Now you add a component that exists only in *your* app. You write three things:

1.  a **schema**: its name and the properties Gemini may set, each with a description. Gemini reads this in its prompt.
2.  a **builder**: turns those properties into a Flutter widget. You can use any Flutter you like here, including state and animations.
3.  a **catalog**: your components, with an id of your own, registered next to the basic catalog.

Fridge Chef adds a `CookingTimer`: a ring that empties as the time runs out, with buttons to start, pause and reset it. Gemini only decides the `minutes` and the `label`. The ticking, the buttons and the look are all your code.

1.  **Create `lib/my_catalog.dart`.** The schema is written with `json_schema_builder`, which you added in Step 1:

    ```dart
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

    Then tell your persona about your component. Here is Fridge Chef's whole persona after this step. The only change is the last sentence, which asks for a `CookingTimer` after every step that needs waiting. Replace your `_persona` with this.

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

    When the user presses a button, the next user turn is JSON: {"messages": [...]} with an action,
    its name, the surfaceId of its surface, and its context.
    Answer a "cook" action with one encouraging sentence, and update the SAME surface, using its surfaceId again:
    replace what is inside the Card with the dish's name as a "## " heading, the ingredients with every amount
    scaled to the servings in the context, and the steps as a numbered List of Text. Do not create a new surface for it.
    Put a CookingTimer right after every step that needs waiting, such as boiling, baking or resting,
    with its minutes and a short label.
    ''';
    ```

Restart the app, ask for a dish and press **Cook this**. Every step that needs waiting now comes with a timer.

Now try to break it: ask for something the catalog doesn't have, like *"Show the recipe as a chess board"* or *"Add a video of it"*. Gemini either makes do with the components it has, or writes one that doesn't exist, and the app tells you it couldn't draw it. Either way, nothing outside your catalog reaches the screen.

> 🧠 **What just happened:** Gemini never saw your Dart code, only your schema and its descriptions. That was enough for it to use the component and pick sensible values. This is the **reliable** promise: the AI decides *what* to show, but only from the set of things you built and allowed.

> 🧪 **Try this:** change the ring's colors, or the size of the time. Then change the description of `minutes` to "always 1", restart, and see Gemini follow your schema over common sense. Put it back before you go on.

> 💾 **Using Git?** `git diff` shows everything this step changed. Save it with `git add -A && git commit -m "Step 5: Your Own Component"`.

> **Stuck?** [`checkpoints/step_05`](../checkpoints/step_05/lib) holds the whole `lib/` folder at the end of this step. Compare it with yours, or copy it over yours: your `lib/api_key.dart` isn't in it, so your key stays. Cloned this repository? From your project folder, `git diff --no-index path/to/a2ui_workshop/checkpoints/step_05/lib lib` shows every line where yours differs.

---

[← Step 4: Snap and Cook](04-snap-and-cook.md) &nbsp;·&nbsp; [Overview](../README.md) &nbsp;·&nbsp; [Step 6: Fast →](06-fast.md)
