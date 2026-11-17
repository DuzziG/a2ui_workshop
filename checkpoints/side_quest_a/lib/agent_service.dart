// lib/agent_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:a2ui_agent/a2ui_agent.dart';
import 'package:a2ui_core/a2ui_core.dart';
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:a2ui_flutter/basic_catalog.dart';
import 'package:dartantic_ai/dartantic_ai.dart';
import 'api_key.dart';
import 'my_catalog.dart';

class AgentService {
  // 1. The catalogs: every component the app can draw. Yours comes after the basic one.
  static final _catalogs = [basicCatalog(), myCatalog];

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
    // A2UI Express: a compact language that compiles to the same A2UI messages.
    inferenceFormatFactory: const ExpressFormatFactory(),
  ).createProcessor(
    A2uiRendererCapabilities.forCatalogIds([for (final catalog in _catalogs) catalog.id], version: A2uiProtocolVersion.v1_0),
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
Before you suggest a dish, call checkPantry: the user has those staples too, so you may use them.
Give every new surface a new surfaceId. Never answer with text only.

When the user presses a button, the next user turn is JSON: {"messages": [...]} with an action,
its name, the surfaceId of its surface, and its context.
Answer a "cook" action with one encouraging sentence, and update the SAME surface. It already exists, so never create it again:
only send its new components, with its surfaceId. Replace what is inside the Card with the dish's name as a "## " heading, the ingredients with every amount
scaled to the servings in the context, and the steps as a numbered List of Text.
Put a CookingTimer right after every step that needs waiting, such as boiling, baking or resting,
with its minutes and a short label.
Below the steps, put an "Add to shopping list" Button with an event action named "shop", whose context holds
the ingredients the user is missing. Answer a "shop" action by calling addToShoppingList with them, and add
the whole shopping list it returns to the same surface, as a List of CheckBox.
''';

  // 5. YOUR rules: functions that your code decides, not the AI.
  //    Gemini asks to call them, the agent runs them, and Gemini reads the result.
  static const _pantry = ['salt', 'pepper', 'olive oil', 'butter', 'flour', 'rice', 'garlic'];
  final List<String> _shoppingList = [];

  late final _tools = [
    Tool<Map<String, dynamic>>(
      name: 'checkPantry',
      description: 'Lists the staples the user always has in the kitchen.',
      onCall: (input) {
        _toolLog.add('checkPantry() -> $_pantry');
        return {'staples': _pantry};
      },
    ),
    Tool<Map<String, dynamic>>(
      name: 'addToShoppingList',
      description: 'Adds items to the user\'s shopping list, and returns the whole list.',
      inputSchema: S.object(
        properties: {'items': S.list(items: S.string(), description: 'The items to add, such as "2 eggs".')},
        required: ['items'],
      ),
      onCall: (input) {
        final items = [for (final item in input['items'] as List? ?? const []) '$item'];
        _shoppingList.addAll(items.where((item) => !_shoppingList.contains(item)));
        _toolLog.add('addToShoppingList(items: $items) -> $_shoppingList');
        return {'shoppingList': _shoppingList};
      },
    ),
  ];

  // The function calls of the last turn, for the X-ray view.
  final List<String> _toolLog = [];

  // 6. Gemini, reached with your API key, with your functions.
  late final _gemini = Agent.forProvider(
    GoogleProvider(apiKey: geminiApiKey),
    chatModelName: 'gemini-3.6-flash',
    tools: _tools,
  );

  // 7. The conversation so far. The system message holds your persona first,
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

  // Streams one message to Gemini, with any attachments, and draws the reply as it arrives.
  Future<String> _generate(String prompt, [List<Part> attachments = const []]) async {
    _toolLog.clear();
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
    lastRawReply = [
      '[${reply.length} characters in $seconds s]',
      for (final call in _toolLog) '[function] $call',
      '\n$reply',
    ].join('\n');

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
