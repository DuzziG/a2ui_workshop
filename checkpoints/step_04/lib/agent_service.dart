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
Answer a "cook" action with one encouraging sentence, and update the SAME surface, using its surfaceId again:
replace what is inside the Card with the dish's name as a "## " heading, the ingredients with every amount
scaled to the servings in the context, and the steps as a numbered List of Text. Do not create a new surface for it.
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
