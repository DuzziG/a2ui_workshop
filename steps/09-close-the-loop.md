[← Step 8: Show It the World](08-show-it-the-world.md) &nbsp;·&nbsp; [Overview](../README.md) &nbsp;·&nbsp; [Step 10: Rules the AI Can't Bend →](10-rules-the-ai-cant-bend.md)

*Part 3: Hand the AI the Pen · Step 9 of 12*

# Step 9: Close the Loop

> 🎯 **Goal:** buttons in Gemini's UI talk back to Gemini.

So far, UI only flows one way. Remember the action from Step 5? Now we send it to Gemini as the next message, and Gemini answers by **updating the surface it already made**. That turns a chat into an app.

Gemini already remembers the conversation (that's `_history`, from Step 3), so it knows which surfaces it created. What's missing is the action itself. We send it as **JSON**, with the surface's current data model beside it, so Gemini knows what was pressed and what the user entered.

1.  **Update `lib/agent_service.dart`.** The persona explains the action messages and how to answer them, and `sendAction` sends them.

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
    You are the Potion Master, the grumpy but brilliant owner of a tiny magical potion shop.
    The user tells you a feeling, a problem or a wish, or shows you a photo. You invent a potion for it.
    When you get a photo, whatever is in it becomes the potion's main ingredient.

    Always answer with one short sentence in character, and exactly one new A2UI surface, a potion card:
    - a Card whose first child is the potion's name as a "## " heading
    - one line of mysterious lore about the potion
    - the ingredients as a List of Text, each with a silly amount ("3 whispers of moonlight")
    - the effect, and one funny side effect, as caption Text
    - a "Brew it!" Button with an event action named "brew", whose context holds the potion's name
    Give every new surface a new surfaceId and set "sendDataModel": true on it. Never answer with text only.

    When the user presses a button, the next user turn is JSON. Its "a2ui" holds {"messages": [...]}:
    an action with its name, surfaceId and context. Beside it, "metadata" holds each surface's data model.
    Answer a "brew" action in character, and update the SAME surface with an updateComponents message:
    add a Text that tells what happened when the user drank the potion. Do not create a new surface for it.
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

      // A button press inside a surface, sent back to Gemini as JSON.
      Future<String> sendAction(A2uiRendererAction action) {
        final dataModel = processor.getRendererDataModel();
        return _generate(
          jsonEncode({
            'a2ui': RendererToAgentMessagePayload.of(ActionMessage(version: '1.0', action: action)).toJson(),
            if (dataModel != null) 'metadata': {'a2uiRendererDataModel': dataModel},
          }),
        );
      }

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

2.  **Send actions to the agent in `lib/home_page.dart`.** Replace `initState` with this version: its last line now sends each action to the agent. Then delete the `_showAction` method from Step 5, which nothing uses anymore.

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

Run it, get a potion and press **Brew it!**. The card itself changes to show what happened. Open X-ray to see the update Gemini sent.

The message Gemini receives looks like this:

```json
{
  "a2ui": {"messages": [{"version": "1.0", "action": {
    "name": "brew", "surfaceId": "potion_1", "sourceComponentId": "brew_button",
    "timestamp": "2026-11-13T12:10:07.253Z", "context": {"potion": "Liquid Courage"}}}]},
  "metadata": {"a2uiRendererDataModel": {"version": "1.0", "surfaces": {
    "potion_1": {"fill": 1}}}}
}
```

> 🧠 **What just happened:** you built the full A2UI loop. Gemini describes UI, the user acts on it, the action goes back, and Gemini updates the UI. Gemini sent an `updateComponents` for an existing surface instead of creating a new one, because your persona told it to.

> 🎨 **Make it yours:** make your button do something. A *Feed* button that changes your pet's mood, a *Next room* button that redraws the dungeon, an *Answer* button that scores the quiz. Add inputs too (a `TextField`, a `ChoicePicker`): their values arrive in the data model.

> **Stuck?** [`checkpoints/step_09`](../checkpoints/step_09/lib) holds the whole `lib/` folder at the end of this step. Compare it with yours, or copy it over yours: your `lib/api_key.dart` isn't in it, so your key stays.

---

[← Step 8: Show It the World](08-show-it-the-world.md) &nbsp;·&nbsp; [Overview](../README.md) &nbsp;·&nbsp; [Step 10: Rules the AI Can't Bend →](10-rules-the-ai-cant-bend.md)
