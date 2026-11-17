[← Step 3: Gemini Writes the UI](03-gemini-writes-the-ui.md) &nbsp;·&nbsp; [Overview](../README.md) &nbsp;·&nbsp; [Step 5: Your Own Component →](05-your-own-component.md)

*Part 3: Hand the AI the Pen · Step 4 of 7*

# Step 4: Snap and Cook

> 🎯 **Goal:** show Gemini a photo, and make the buttons in its UI talk back to it.

Two things turn the chat into an app.

**Photos.** Gemini is **multimodal**: it understands images as well as text. One message can carry both, so you can show it your fridge instead of typing out what's in it.

**Closing the loop.** So far, UI only flows one way. Remember the action from Step 2? Now we send it to Gemini as the next message, and Gemini answers by **updating the surface it already made**: the recipe card turns into a step-by-step guide, scaled to the servings on the slider.

1.  **Set up the image picker**, which you added in Step 1. On the web and Android there is nothing to do. On iOS, add `NSPhotoLibraryUsageDescription` to `ios/Runner/Info.plist`. On macOS, add the `com.apple.security.files.user-selected.read-only` entitlement. See the [image_picker docs](https://pub.dev/packages/image_picker) for details.

2.  **Update `lib/agent_service.dart`.** All kinds of message now go through one `_generate` method:
    * `sendPhoto` attaches the picture to a short question as a `DataPart`: the photo's bytes and their type.
    * `sendAction` sends a button press to Gemini as JSON.
    * The persona explains both, and how to answer a `cook` action.

    ```dart
    // lib/agent_service.dart
    import 'dart:convert';
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
    Answer a "cook" action with one encouraging sentence, and update the SAME surface. It already exists, so never create it again:
    only send its new components, with its surfaceId. Replace what is inside the Card with the dish's name as a "## " heading, the ingredients with every amount
    scaled to the servings in the context, and the steps as a numbered List of Text.
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
        'Here is a photo of my fridge. What can I cook?',
        [DataPart(bytes, mimeType: mimeType)],
      );

      // A button press inside a surface, sent back to Gemini as JSON.
      Future<String> sendAction(A2uiRendererAction action) => _generate(
        jsonEncode(RendererToAgentMessagePayload.of(ActionMessage(version: '1.0', action: action)).toJson()),
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

3.  **Update `lib/home_page.dart`.** Add the import at the top, with the other imports:

    ```dart
    import 'package:image_picker/image_picker.dart';
    ```

    Replace `initState` with this version: its last line now sends each action to the agent. Then delete the `_showAction` method from Step 2, which nothing uses anymore.

    ```dart
      @override
      void initState() {
        super.initState();
        // Whenever the processor creates or deletes a surface, update the screen.
        _agent.processor.model.onSurfaceCreated.subscribe((surface) => setState(() => _surfaces.add(surface)));
        _agent.processor.model.onSurfaceDeleted.subscribe((id) => setState(() => _surfaces.removeWhere((s) => s.id == id)));
        // When a button inside a surface is pressed, send the action to the agent.
        _agent.processor.model.onAction.subscribe((action) => _run(() => _agent.sendAction(action)));
      }
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

Restart the app and send a photo of a fridge (yours, or any photo you find). Set the servings, press **Cook this**, and watch the card change into the steps. Open X-ray to see the update Gemini sent.

The message Gemini receives when you press the button looks like this:

```json
{"messages": [{"version": "1.0", "action": {
  "name": "cook", "surfaceId": "omelette_1", "sourceComponentId": "cook_button",
  "timestamp": "2026-11-16T12:10:07.253Z",
  "context": {"dish": "Spinach and feta omelette", "servings": 4}}}]}
```

> 📖 **In the A2UI docs:** [actions](https://a2ui.org/concepts/actions/) explains events like `cook`, and the functions that run in the app without going to the agent.

> 🧠 **What just happened:** you built the full A2UI loop. Gemini describes UI, the user acts on it, the action goes back, and Gemini updates the UI. The `servings` in the context came from the slider, through the data model: Gemini never had to ask how many people are eating. And it updated the surface it already had instead of creating a new one, because your persona told it to. A surface is created once, and only updated after that: creating it again is an error, and the app tells you *"Surface … already exists"*.

> 🧪 **Try this:** send a photo that isn't food at all, like your shoes. What does Chef Pip do? Then press **Cook this** with the slider on 1 and on 8, and compare the amounts.

> 💾 **Using Git?** `git diff` shows everything this step changed. Save it with `git add -A && git commit -m "Step 4: Snap and Cook"`.

> **Stuck?** [`checkpoints/step_04`](../checkpoints/step_04/lib) holds the whole `lib/` folder at the end of this step. Compare it with yours, or copy it over yours: your `lib/api_key.dart` isn't in it, so your key stays. Cloned this repository? From your project folder, `git diff --no-index path/to/a2ui_workshop/checkpoints/step_04/lib lib` shows every line where yours differs.

---

[← Step 3: Gemini Writes the UI](03-gemini-writes-the-ui.md) &nbsp;·&nbsp; [Overview](../README.md) &nbsp;·&nbsp; [Step 5: Your Own Component →](05-your-own-component.md)
