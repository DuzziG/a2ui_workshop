[← Step 11: Your Own Component](11-your-own-component.md) &nbsp;·&nbsp; [Overview](../README.md) &nbsp;·&nbsp; [Bonus A: AI-Painted Illustrations →](bonus-a-ai-painted-illustrations.md)

*Part 4: Make It Truly Yours*

# Step 12: Stream the UI

> 🎯 **Goal:** watch the UI build itself while Gemini is still writing it.

Gemini can stream its reply in chunks, and `StreamedAnswer` can read chunk by chunk. Put them together and surfaces appear on screen as they are written.

**Update `lib/agent_service.dart`.** Three changes:

* the processor uses `ValidationConfig.relaxed`, so a half-written surface can already show
* `progressiveKeys` shows `text` and `label` values word by word
* `_generate` uses `sendStream` and feeds each chunk as it arrives

Replace parts 2 and 3 (the renderer and the A2UI agent kit) with:

```dart
  // 2. The renderer: it applies A2UI messages and remembers every surface.
  //    Relaxed validation lets a half-written surface show while it streams in.
  final processor = MessageProcessor<ComponentImplementation>(
    catalogs: _catalogs,
    validationConfig: ValidationConfig.relaxed,
  );

  // 3. The A2UI agent kit: writes a prompt that teaches Gemini our catalogs,
  //    and checks Gemini's reply against them.
  final _a2uiAgent = A2uiGenerator(
    catalogs: [for (final catalog in _catalogs) CatalogConfig(catalog)],
    // Show texts and labels word by word, while Gemini is still writing them.
    inferenceFormatFactory: const DirectJsonFormatFactory(progressiveKeys: {'text', 'label'}),
  ).createProcessor(
    A2uiRendererCapabilities.forCatalogIds([for (final catalog in _catalogs) catalog.id], version: A2uiProtocolVersion.v1_0),
  );
```

Then replace the whole `_generate` method with this streaming version:

```dart
  // Streams one message to Gemini, with any attachments, and draws the reply as it arrives.
  Future<String> _generate(String prompt, [List<Part> attachments = const []]) async {
    _toolLog.clear();
    final reply = StringBuffer();
    final newMessages = <ChatMessage>[];
    final answer = StreamedAnswer(_a2uiAgent, renderer: processor);
    try {
      await for (final chunk in _gemini.sendStream(prompt, history: _history, attachments: attachments)) {
        reply.write(chunk.output);
        answer.feed(chunk.output); // Each chunk updates the surfaces right away.
        newMessages.addAll(chunk.messages);
      }
      answer.close();
      _history.addAll(newMessages); // Remember this turn.
    } catch (e) {
      return 'Error: $e';
    }
    lastRawReply = [for (final call in _toolLog) '[function] $call', '$reply'].join('\n');

    return [
      for (final part in answer.parts)
        switch (part) {
          AnswerTextPart(:final text) => text.trim(),
          AnswerErrorPart(:final error) => 'Gemini wrote UI I could not draw: ${error.message}',
          AnswerSurfacePart() => '',
        },
    ].where((text) => text.isNotEmpty).join('\n');
  }
```

`HomePage` doesn't change: it already keeps the surfaces on screen while it loads.

> 🧠 **What just happened:** each chunk Gemini streams is fed to the parser, which applies every message as soon as it is complete. The function calls from Step 10 still work: `sendStream` runs them between chunks.

> 🎨 **Make it yours:** look at your persona's layout with fresh eyes. The first component Gemini writes appears first, so put the exciting part at the top.

---

[← Step 11: Your Own Component](11-your-own-component.md) &nbsp;·&nbsp; [Overview](../README.md) &nbsp;·&nbsp; [Bonus A: AI-Painted Illustrations →](bonus-a-ai-painted-illustrations.md)
