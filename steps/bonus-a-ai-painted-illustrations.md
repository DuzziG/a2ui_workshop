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

3.  **Ask for it in the persona** in `lib/agent_service.dart`. In its list of what goes on the card, add a line that asks for an Illustration. In Potion Lab, it goes right under the heading line:

    ```dart
    - a Card whose first child is the potion's name as a "## " heading
    - an Illustration of the potion, with a prompt that names a fun art style
    ```

> **Note:** pictures use more of your free quota than text. If one comes back broken, you may have hit the limit for now.

> 🎨 **Make it yours:** pick an art style that fits your app, such as pixel art, watercolor or a movie poster, and put it in the persona. Or let the user choose a style with a `ChoicePicker`.

---

[← Step 12: Stream the UI](12-stream-the-ui.md) &nbsp;·&nbsp; [Overview](../README.md) &nbsp;·&nbsp; [Bonus B: A 3D Companion with Flutter Scene →](bonus-b-a-3d-companion-with-flutter-scene.md)
