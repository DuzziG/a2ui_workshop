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
