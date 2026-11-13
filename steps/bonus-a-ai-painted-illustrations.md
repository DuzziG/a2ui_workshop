[← Step 12: Stream the UI](12-stream-the-ui.md) &nbsp;·&nbsp; [Overview](../README.md) &nbsp;·&nbsp; [Bonus B: A 3D Companion with Flutter Scene →](bonus-b-a-3d-companion-with-flutter-scene.md)

*Bonus Steps*

# Bonus A: AI-Painted Illustrations

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

    Then replace `myCatalog` at the bottom of the file with this version, which adds `illustration` to its components:

    ```dart
    // 3. Your own catalog, which sits next to the basic one.
    final myCatalog = CatalogImplementation(
      id: 'https://example.com/potion_lab/catalog.json',
      protocolVersion: A2uiProtocolVersion.v1_0,
      components: [potionBottle, illustration],
    );
    ```

3.  **Ask for it in the persona** in `lib/agent_service.dart`. Here is Potion Lab's whole persona after this step. The only change is a new line in the list of what goes on the card, right under the heading line, asking for an `Illustration`. Following Potion Lab? Replace your `_persona` with this. Wrote your own? Add a line like it to yours.

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

    When the user presses a button, the next user turn is JSON. Its "a2ui" holds {"messages": [...]}:
    an action with its name, surfaceId and context. Beside it, "metadata" holds each surface's data model.
    Answer a "brew" action by calling rollDice with 20 sides: 1 is a disaster, 2 to 10 a wobbly
    result, 11 to 19 a success and 20 a legend. Then answer in character, and update the SAME surface with an updateComponents message:
    add a Text that tells the roll and what happened when the user drank the potion, and set /fill to 0
    with an updateDataModel message, because the bottle is now empty. Do not create a new surface for it.
    ''';
    ```

> **Note:** pictures use more of your free quota than text. If one comes back broken, you may have hit the limit for now.

> 🎨 **Make it yours:** pick an art style that fits your app, such as pixel art, watercolor or a movie poster, and put it in the persona. Or let the user choose a style with a `ChoicePicker`.

> **Stuck?** [`checkpoints/bonus_a`](../checkpoints/bonus_a/lib) holds the whole `lib/` folder at the end of this step. Compare it with yours, or copy it over yours: your `lib/api_key.dart` isn't in it, so your key stays.

---

[← Step 12: Stream the UI](12-stream-the-ui.md) &nbsp;·&nbsp; [Overview](../README.md) &nbsp;·&nbsp; [Bonus B: A 3D Companion with Flutter Scene →](bonus-b-a-3d-companion-with-flutter-scene.md)
