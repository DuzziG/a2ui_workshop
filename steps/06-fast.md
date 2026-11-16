[← Step 5: Your Own Component](05-your-own-component.md) &nbsp;·&nbsp; [Overview](../README.md) &nbsp;·&nbsp; [Step 7: Make It Yours →](07-make-it-yours.md)

*Part 4: Reliable and Fast · Step 6 of 7*

# Step 6: Fast

> 🎯 **Goal:** watch the UI build itself while Gemini is still writing it, then make the reply shorter.

Right now you wait for Gemini's whole reply, then everything appears at once. Two changes make it feel fast:

* **Streaming:** Gemini sends its reply in chunks, and `StreamedAnswer` can read chunk by chunk, so surfaces appear as they are written.
* **A2UI Express:** a compact language for A2UI that the model writes instead of JSON. `a2ui_agent` compiles it into the very same A2UI messages, so nothing else in your app changes.

1.  **Let half-written surfaces show.** In `lib/agent_service.dart`, replace part 2 (the renderer) with this version, which uses `ValidationConfig.relaxed`:

    ```dart
      // 2. The renderer: it applies A2UI messages and remembers every surface.
      //    Relaxed validation lets a half-written surface show while it streams in.
      final processor = MessageProcessor<ComponentImplementation>(
        catalogs: _catalogs,
        validationConfig: ValidationConfig.relaxed,
      );
    ```

2.  **Stream the reply.** Replace the whole `_generate` method with this streaming version, and delete `_render` below it: the new `_generate` does its job. It also times every reply and counts its characters, and puts both on top of the X-ray.

    ```dart
      // Streams one message to Gemini, with any attachments, and draws the reply as it arrives.
      Future<String> _generate(String prompt, [List<Part> attachments = const []]) async {
        final stopwatch = Stopwatch()..start();
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
        // How long the reply took, and how long it is, on top of the X-ray.
        final seconds = (stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1);
        lastRawReply = '[${reply.length} characters in $seconds s]\n\n$reply';

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

    Restart the app, ask for a dish and watch the card grow. Open X-ray and note the line at the top, such as `[2154 characters in 6.3 s]`.

3.  **Switch to Express.** In part 3, change `const DirectJsonFormatFactory()` to `const ExpressFormatFactory()`. That's the whole change:

    ```dart
      // 3. The A2UI agent kit: writes a prompt that teaches Gemini our catalogs,
      //    and checks Gemini's reply against them.
      final _a2uiAgent = A2uiGenerator(
        catalogs: [for (final catalog in _catalogs) CatalogConfig(catalog)],
        // A2UI Express: a compact language that compiles to the same A2UI messages.
        inferenceFormatFactory: const ExpressFormatFactory(),
      ).createProcessor(
        A2uiRendererCapabilities.forCatalogIds([for (final catalog in _catalogs) catalog.id], version: A2uiProtocolVersion.v1_0),
      );
    ```

    **Restart** the app (the prompt snippet is built when the service starts), and ask the same question again.

Open X-ray. Gemini now writes the UI between `<a2ui>` tags, like this:

```
<a2ui>
surface("omelette_1")
$/servings = 2
root = Card(col)
col = Column([title, why, ings, servings, cook])
title = Text("## Spinach and feta omelette")
servings = Slider("Servings", 1, 8, $/servings)
cook = Button(cookLabel, "primary", Event("cook", {dish: "Spinach and feta omelette", servings: $/servings}))
...
</a2ui>
```

Compare the numbers at the top with the ones you noted: the same card in far fewer characters. The prompt gets smaller too: with Fridge Chef's two catalogs, the Express rules are about 25,000 characters instead of about 45,000, and Gemini reads them on every turn.

> 🧠 **What just happened:** each chunk Gemini streams is fed to the parser, which applies every message as soon as it is complete. Express even fills in texts word by word. It also made the model write less for the same UI, and fewer tokens means a faster, cheaper reply. `HomePage`, your catalog and your persona didn't change at all: the A2UI messages that reach the renderer are the same.

> 🧪 **Try this:** the first component Gemini writes appears first. Move the heading line to the end of the persona's list, restart, and watch the card build in a different order. Put it back before you go on.

> 💾 **Using Git?** `git diff` shows everything this step changed. Save it with `git add -A && git commit -m "Step 6: Fast"`.

> **Stuck?** [`checkpoints/step_06`](../checkpoints/step_06/lib) holds the whole `lib/` folder at the end of this step. Compare it with yours, or copy it over yours: your `lib/api_key.dart` isn't in it, so your key stays. Cloned this repository? From your project folder, `git diff --no-index path/to/a2ui_workshop/checkpoints/step_06/lib lib` shows every line where yours differs.

---

[← Step 5: Your Own Component](05-your-own-component.md) &nbsp;·&nbsp; [Overview](../README.md) &nbsp;·&nbsp; [Step 7: Make It Yours →](07-make-it-yours.md)
