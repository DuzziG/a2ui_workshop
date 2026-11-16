[← Side Quest A: Kitchen Tools](side-quest-a-kitchen-tools.md) &nbsp;·&nbsp; [Overview](../README.md) &nbsp;·&nbsp; [Side Quest C: A 3D Chef Companion →](side-quest-c-a-3d-chef-companion.md)

*Side Quests*

# Side Quest B: AI-Painted Dishes

> 🎯 **Goal:** a component that asks an image model to paint a picture.

A component's builder can do anything a widget can, including calling another AI. `Illustration` takes a `prompt` that Gemini writes, and an image model paints it.

1.  **Create `lib/illustration.dart`.** It asks an image model for a picture with `generateMedia`. A cache stops it from painting the same picture twice when the surface rebuilds.

    ```dart
    // lib/illustration.dart
    import 'dart:typed_data';
    import 'package:a2ui_flutter/a2ui_flutter.dart';
    import 'package:dartantic_ai/dartantic_ai.dart' show Agent, DataPart, GoogleProvider;
    import 'package:flutter/material.dart';
    import 'package:json_schema_builder/json_schema_builder.dart' hide ValidationResult;
    import 'api_key.dart';

    // A picture that an image model paints from a description Gemini writes.
    final illustration = ComponentImplementation(
      name: 'Illustration',
      schema: Schema.object(
        description: 'A picture painted by an AI artist.',
        properties: {
          'prompt': Schema.fromMap({
            r'$ref': r'common_types.json#/$defs/DynamicString',
            'description': 'What the picture shows and its art style, in one sentence.',
          }),
        },
        required: ['prompt'],
      ),
      builder: (context, node, props, buildChild) => _IllustrationView(prompt: props.string('prompt') ?? ''),
    );

    class _IllustrationView extends StatefulWidget {
      const _IllustrationView({required this.prompt});
      final String prompt;

      @override
      State<_IllustrationView> createState() => _IllustrationViewState();
    }

    class _IllustrationViewState extends State<_IllustrationView> {
      // The artist: a Gemini model that paints pictures.
      static final _artist = Agent.forProvider(GoogleProvider(apiKey: geminiApiKey), mediaModelName: 'gemini-3.1-flash-image');

      // Pictures already painted, by prompt, so a rebuild doesn't paint again.
      static final _cache = <String, Future<Uint8List?>>{};

      late Future<Uint8List?> _image;

      @override
      void initState() {
        super.initState();
        _image = _paint(widget.prompt);
      }

      @override
      void didUpdateWidget(_IllustrationView old) {
        super.didUpdateWidget(old);
        if (old.prompt != widget.prompt) _image = _paint(widget.prompt);
      }

      static Future<Uint8List?> _paint(String prompt) => _cache.putIfAbsent(prompt, () async {
        final result = await _artist.generateMedia(prompt, mimeTypes: const ['image/png']);
        return result.assets.whereType<DataPart>().firstOrNull?.bytes;
      });

      @override
      Widget build(BuildContext context) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 200,
            width: double.infinity,
            child: FutureBuilder(
              future: _image,
              builder: (context, snapshot) => switch (snapshot) {
                AsyncSnapshot(:final Uint8List data) => Image.memory(data, fit: BoxFit.cover),
                AsyncSnapshot(hasError: true) || AsyncSnapshot(connectionState: ConnectionState.done) =>
                  const ColoredBox(color: Colors.black12, child: Icon(Icons.broken_image)),
                _ => const ColoredBox(color: Colors.black12, child: Center(child: CircularProgressIndicator())),
              },
            ),
          ),
        );
      }
    }
    ```

2.  **Add it to your catalog** in `lib/my_catalog.dart`. First the import, at the top with the other imports:

    ```dart
    import 'illustration.dart';
    ```

    Then add `illustration` to the `components` list of `myCatalog`. For Fridge Chef, it looks like this:

    ```dart
    // 3. Your own catalog, which sits next to the basic one.
    final myCatalog = CatalogImplementation(
      id: 'https://example.com/fridge_chef/catalog.json',
      protocolVersion: A2uiProtocolVersion.v1_0,
      components: [cookingTimer, illustration],
    );
    ```

3.  **Ask for it in the persona** in `lib/agent_service.dart`. Here is Fridge Chef's whole persona after this side quest. The only change is a new line in the list of what goes on the card, right under the heading line, asking for an `Illustration`. Following Fridge Chef? Replace your `_persona` with this. Made it your own in Step 7? Add a line like it to yours.

    ```dart
      // 4. YOUR idea: who the agent is, and what its UI looks like.
      static const _persona = '''
    You are Chef Pip, a cheerful little chef who hates wasting food.
    The user tells you what is in their fridge, or what they feel like eating, or shows you a photo of their fridge.
    You suggest one dish they can cook with it. When you get a photo, use only what you can see in it, plus salt, pepper and oil.

    Always answer with one short, friendly sentence, and exactly one new A2UI surface, a recipe card:
    - a Card whose first child is the dish's name as a "## " heading
    - an Illustration of the finished dish, with a prompt for a bright, cozy food photo
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

> **Note:** pictures use more of your free quota than text. If one comes back broken, you may have hit the limit for now.

> 🎨 **Make it yours:** pick an art style that fits your app, such as pixel art, watercolor or a movie poster, and put it in the persona. Or let the user choose a style with a `ChoicePicker`.

> 💾 **Using Git?** `git diff` shows everything this step changed. Save it with `git add -A && git commit -m "Side Quest B: AI-Painted Dishes"`.

> **Stuck?** [`checkpoints/side_quest_b`](../checkpoints/side_quest_b/lib) holds the whole `lib/` folder at the end of this step. Compare it with yours, or copy it over yours: your `lib/api_key.dart` isn't in it, so your key stays. Cloned this repository? From your project folder, `git diff --no-index path/to/a2ui_workshop/checkpoints/side_quest_b/lib lib` shows every line where yours differs.

---

[← Side Quest A: Kitchen Tools](side-quest-a-kitchen-tools.md) &nbsp;·&nbsp; [Overview](../README.md) &nbsp;·&nbsp; [Side Quest C: A 3D Chef Companion →](side-quest-c-a-3d-chef-companion.md)
