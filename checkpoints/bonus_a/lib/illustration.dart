// lib/illustration.dart
import 'dart:typed_data';
import 'package:a2ui_flutter/a2ui_flutter.dart';
// Only what we need from firebase_ai: it has its own Schema, which would clash.
import 'package:firebase_ai/firebase_ai.dart' show Content, FirebaseAI, GenerationConfig, ResponseModalities;
import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart' hide ValidationResult;

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
  // The image model: it answers with pictures as well as text.
  static final _artist = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-3.1-flash-image',
    generationConfig: GenerationConfig(responseModalities: [ResponseModalities.text, ResponseModalities.image]),
  );

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
    final response = await _artist.generateContent([Content.text(prompt)]);
    return response.inlineDataParts.firstOrNull?.bytes;
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
