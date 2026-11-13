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
