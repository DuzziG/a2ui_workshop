// lib/agent_service.dart
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:a2ui_agent/a2ui_agent.dart' hide TextPart; // firebase_ai has its own TextPart
import 'package:a2ui_core/a2ui_core.dart';
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:a2ui_flutter/basic_catalog.dart';
import 'package:firebase_ai/firebase_ai.dart';
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
    // Show texts and labels word by word, while Gemini is still writing them.
    inferenceFormatFactory: const DirectJsonFormatFactory(progressiveKeys: {'text', 'label'}),
  ).createProcessor(
    A2uiRendererCapabilities.forCatalogIds([for (final catalog in _catalogs) catalog.id], version: A2uiProtocolVersion.v1_0),
  );

  // 4. YOUR idea: who the agent is, and what its UI looks like.
  static const _persona = '''
You are the Potion Master, the grumpy but brilliant owner of a tiny magical potion shop.
The user tells you a feeling, a problem or a wish, or shows you a photo. You invent a potion for it.
When you get a photo, whatever is in it becomes the potion's main ingredient.

Always answer with one short sentence in character, and exactly one new A2UI surface, a potion card:
- a Card whose first child is the potion's name as a "## " heading
- an Illustration of the potion, with a prompt that names a fun art style
- a PotionBottle in the potion's color, whose fill is bound to /fill, which starts at 1
- one line of mysterious lore about the potion
- the ingredients as a List of Text, each with a silly amount ("3 whispers of moonlight")
- the effect, and one funny side effect, as caption Text
- a "Brew it!" Button with an event action named "brew", whose context holds the potion's name
Before you invent a potion, call checkShelf, and only use ingredients that are on the shelf.
Give every new surface a new surfaceId and set "sendDataModel": true on it. Never answer with text only.

You have a companion: a small 3D creature that lives in your shop and shows how you feel.
In your very first answer, also create a surface with the surfaceId "companion" that holds only a Companion,
with its mood bound to /mood and its color bound to /color. In every later answer, send an updateDataModel
for the "companion" surface that sets /mood to how you feel now: happy, excited, sleepy or grumpy.

When the user presses a button, the next user turn is JSON. Its "a2ui" holds {"messages": [...]}:
an action with its name, surfaceId and context. Beside it, "metadata" holds each surface's data model.
Answer a "brew" action by calling rollDice with 20 sides: 1 is a disaster, 2 to 10 a wobbly
result, 11 to 19 a success and 20 a legend. Then answer in character, and update the SAME surface with an updateComponents message:
add a Text that tells the roll and what happened when the user drank the potion, and set /fill to 0
with an updateDataModel message, because the bottle is now empty. Do not create a new surface for it.
''';

  // 5. YOUR rules: functions that your code decides, not the AI.
  //    Gemini asks to call them, the chat runs them, and Gemini reads the result.
  static const _shelf = ['dragon scale', 'moonlight', 'frog giggle', 'cinnamon', 'thunder in a jar', 'unicorn hair'];
  final _random = Random();

  late final _tools = [
    Tool.functionDeclarations([
      AutoFunctionDeclaration(
        name: 'rollDice',
        description: 'Rolls a die and returns the number it lands on.',
        parameters: {'sides': Schema.integer(description: 'How many sides the die has, such as 20.')},
        callable: (args) {
          final sides = (args['sides'] as num?)?.toInt() ?? 20;
          final roll = _random.nextInt(sides) + 1;
          _toolLog.add('rollDice(sides: $sides) -> $roll');
          return {'roll': roll};
        },
      ),
      AutoFunctionDeclaration(
        name: 'checkShelf',
        description: 'Lists the ingredients the shop has in stock.',
        parameters: {},
        callable: (args) {
          _toolLog.add('checkShelf() -> $_shelf');
          return {'ingredients': _shelf};
        },
      ),
    ]),
  ];

  // The function calls of the last turn, for the X-ray view.
  final List<String> _toolLog = [];

  // 6. The model: your persona first, then the A2UI rules, and your functions.
  late final _model = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-3.6-flash',
    systemInstruction: Content.system('$_persona\n${_a2uiAgent.promptSnippet}'),
    tools: _tools,
  );

  // 7. A chat remembers the conversation, so Gemini knows which surfaces it made.
  late final _chat = _model.startChat();

  // The last raw reply from Gemini, for the X-ray view.
  String lastRawReply = '';

  Future<String> send(String prompt) => _generate(Content.text(prompt));

  // A photo plus a short instruction, in one message.
  Future<String> sendPhoto(Uint8List bytes, String mimeType) => _generate(
    Content.multi([
      TextPart('Here is a photo. Make a potion from what you see.'),
      InlineDataPart(mimeType, bytes),
    ]),
  );

  // A button press inside a surface, sent back to Gemini as JSON.
  Future<String> sendAction(A2uiRendererAction action) {
    final dataModel = processor.getRendererDataModel();
    final message = jsonEncode({
      'a2ui': RendererToAgentMessagePayload.of(ActionMessage(version: '1.0', action: action)).toJson(),
      if (dataModel != null) 'metadata': {'a2uiRendererDataModel': dataModel},
    });
    return _generate(Content.text(message));
  }

  // Streams one message to Gemini and draws the reply as it arrives.
  Future<String> _generate(Content content) async {
    _toolLog.clear();
    final reply = StringBuffer();
    final answer = StreamedAnswer(_a2uiAgent, renderer: processor);
    try {
      await for (final chunk in _chat.sendMessageStream(content)) {
        reply.write(chunk.text ?? '');
        answer.feed(chunk.text ?? ''); // Each chunk updates the surfaces right away.
      }
      answer.close();
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

  void dispose() => processor.dispose();
}
