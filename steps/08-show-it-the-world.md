[← Step 7: Give It a Personality](07-give-it-a-personality.md) &nbsp;·&nbsp; [Overview](../README.md) &nbsp;·&nbsp; [Step 9: Close the Loop →](09-close-the-loop.md)

*Part 3: Hand the AI the Pen · Step 8 of 12*

# Step 8: Show It the World

> 🎯 **Goal:** send a photo, get UI back.

Gemini is **multimodal**: it understands images as well as text. One message can carry both.

1.  **Set up the image picker**, which you added in Step 2. On the web and Android there is nothing to do. On iOS, add `NSPhotoLibraryUsageDescription` to `ios/Runner/Info.plist`. On macOS, add the `com.apple.security.files.user-selected.read-only` entitlement. See the [image_picker docs](https://pub.dev/packages/image_picker) for details.

2.  **Update `lib/agent_service.dart`.** Both kinds of message now go through one `_generate` method. `sendPhoto` attaches the picture to a short instruction as a `DataPart`: the photo's bytes and their type. We also tell the persona what to do with photos.

    ```dart
    // lib/agent_service.dart
    import 'dart:typed_data';
    import 'package:a2ui_agent/a2ui_agent.dart';
    import 'package:a2ui_core/a2ui_core.dart';
    import 'package:a2ui_flutter/a2ui_flutter.dart';
    import 'package:a2ui_flutter/basic_catalog.dart';
    import 'package:dartantic_ai/dartantic_ai.dart';
    import 'api_key.dart';

    class AgentService {
      // 1. The catalog: every component the app can draw.
      static final _catalog = basicCatalog();

      // 2. The renderer: it applies A2UI messages and remembers every surface.
      final processor = MessageProcessor<ComponentImplementation>(catalogs: [_catalog]);

      // 3. The A2UI agent kit: writes a prompt that teaches Gemini our catalog,
      //    and checks Gemini's reply against it.
      final _a2uiAgent = A2uiGenerator(
        catalogs: [CatalogConfig(_catalog)],
        inferenceFormatFactory: const DirectJsonFormatFactory(),
      ).createProcessor(
        A2uiRendererCapabilities.forCatalogIds([BasicCatalog.v1_0Id], version: A2uiProtocolVersion.v1_0),
      );

      // 4. YOUR idea: who the agent is, and what its UI looks like.
      static const _persona = '''
    You are the Potion Master, the grumpy but brilliant owner of a tiny magical potion shop.
    The user tells you a feeling, a problem or a wish, or shows you a photo. You invent a potion for it.
    When you get a photo, whatever is in it becomes the potion's main ingredient.

    Always answer with one short sentence in character, and exactly one new A2UI surface, a potion card:
    - a Card whose first child is the potion's name as a "## " heading
    - one line of mysterious lore about the potion
    - the ingredients as a List of Text, each with a silly amount ("3 whispers of moonlight")
    - the effect, and one funny side effect, as caption Text
    - a "Brew it!" Button with an event action named "brew"
    Give every new surface a new surfaceId. Never answer with text only.
    ''';

      // 5. Gemini, reached with your API key.
      final _gemini = Agent.forProvider(GoogleProvider(apiKey: geminiApiKey), chatModelName: 'gemini-3.6-flash');

      // 6. The conversation so far. The system message holds your persona first,
      //    then the A2UI rules.
      late final List<ChatMessage> _history = [ChatMessage.system('$_persona\n${_a2uiAgent.promptSnippet}')];

      // The last raw reply from Gemini, for the X-ray view.
      String lastRawReply = '';

      Future<String> send(String prompt) => _generate(prompt);

      // A photo, attached to a short instruction.
      Future<String> sendPhoto(Uint8List bytes, String mimeType) => _generate(
        'Here is a photo. Make a potion from what you see.',
        [DataPart(bytes, mimeType: mimeType)],
      );

      // Sends one message to Gemini, with any attachments, and draws the reply.
      Future<String> _generate(String prompt, [List<Part> attachments = const []]) async {
        try {
          final result = await _gemini.send(prompt, history: _history, attachments: attachments);
          _history.addAll(result.messages); // Remember this turn.
          return _render(result.output);
        } catch (e) {
          return 'Error: $e';
        }
      }

      // Splits a reply into text for the page and A2UI messages for the processor.
      String _render(String reply) {
        lastRawReply = reply;
        final answer = StreamedAnswer(_a2uiAgent, renderer: processor);
        answer.feed(reply);
        answer.close();

        return [
          for (final part in answer.parts)
            switch (part) {
              AnswerTextPart(:final text) => text.trim(),
              AnswerErrorPart(:final error) => 'Gemini wrote UI I could not draw: ${error.message}',
              AnswerSurfacePart() => '',
            },
        ].where((text) => text.isNotEmpty).join('\n');
      }

      void dispose() => processor.dispose();
    }
    ```

3.  **Add a photo button to `lib/home_page.dart`.** Add the import at the top, with the other imports:

    ```dart
    import 'package:image_picker/image_picker.dart';
    ```

    Add `_sendPhoto` right below `_sendPrompt`:

    ```dart
      // Lets the user pick a photo and sends it to the agent.
      Future<void> _sendPhoto() async {
        final photo = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1024);
        if (photo == null) return;
        final bytes = await photo.readAsBytes();
        await _run(() => _agent.sendPhoto(bytes, photo.mimeType ?? 'image/jpeg'));
      }
    ```

    In `_buildChat`, replace the prompt box (from `// 3. The prompt box.` to the end of its `SafeArea`) with this version. The only new line is the camera `IconButton` in front of the text field:

    ```dart
            // 3. The prompt box.
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    IconButton(onPressed: _isLoading ? null : _sendPhoto, icon: const Icon(Icons.photo_camera)),
                    Expanded(
                      child: TextField(
                        controller: _promptController,
                        decoration: const InputDecoration(hintText: 'Ask for something...', border: OutlineInputBorder()),
                        onSubmitted: (_) => _sendPrompt(),
                      ),
                    ),
                    IconButton.filled(onPressed: _isLoading ? null : _sendPrompt, icon: const Icon(Icons.send)),
                  ],
                ),
              ),
            ),
    ```

Run it and send a photo of anything: your shoe, your lunch, your neighbor's cat.

> 🧠 **What just happened:** the photo travelled as an attachment, in the same message as the text. Gemini looked at the picture, and your persona told it what to make of it.

> 🎨 **Make it yours:** decide what a photo *means* in your app. In a Dungeon Master, the photo becomes the next room. In a Fridge Chef, it's the ingredients. In an Outfit Judge, it's the whole point. Update the persona and the text in `sendPhoto`. To use the camera on a phone, try `ImageSource.camera`.

> **Stuck?** [`checkpoints/step_08`](../checkpoints/step_08/lib) holds the whole `lib/` folder at the end of this step. Compare it with yours, or copy it over yours: your `lib/api_key.dart` isn't in it, so your key stays.

---

[← Step 7: Give It a Personality](07-give-it-a-personality.md) &nbsp;·&nbsp; [Overview](../README.md) &nbsp;·&nbsp; [Step 9: Close the Loop →](09-close-the-loop.md)
