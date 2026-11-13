// lib/agent_service.dart
import 'package:a2ui_core/a2ui_core.dart';
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:a2ui_flutter/basic_catalog.dart';
import 'package:dartantic_ai/dartantic_ai.dart';
import 'api_key.dart';

class AgentService {
  // The renderer: it applies A2UI messages and remembers every surface.
  final processor = MessageProcessor<ComponentImplementation>(catalogs: [basicCatalog()]);

  int _surfaceCount = 0;

  // Gemini, reached with your API key.
  final _gemini = Agent.forProvider(GoogleProvider(apiKey: geminiApiKey), chatModelName: 'gemini-3.6-flash');

  // The conversation so far. The system message tells Gemini how to behave.
  final List<ChatMessage> _history = [
    ChatMessage.system('You are a friendly assistant. Answer in one or two short sentences.'),
  ];

  Future<String> send(String prompt) async {
    final reply = await _ask(prompt); // Gemini writes the text...
    _draw(prompt); // ...and you draw the UI, by hand.
    return reply;
  }

  // Asks Gemini for a text answer.
  Future<String> _ask(String prompt) async {
    try {
      final result = await _gemini.send(prompt, history: _history);
      _history.addAll(result.messages); // Remember this turn.
      return result.output;
    } catch (e) {
      return 'Error: $e';
    }
  }

  // Draws a card that you wrote by hand, in JSON.
  void _draw(String prompt) {
    // Every surface needs its own id.
    final surfaceId = 'card_${_surfaceCount++}';

    processor.processMessages([
      // Message 1: create an empty surface that uses the basic catalog.
      {
        'version': '1.0',
        'createSurface': {'surfaceId': surfaceId, 'catalogId': BasicCatalog.v1_0Id},
      },
      // Message 2: fill it with components. A flat list: 'root' is the top,
      // and every component points at its children by id.
      {
        'version': '1.0',
        'updateComponents': {
          'surfaceId': surfaceId,
          'components': [
            {'id': 'root', 'component': 'Card', 'child': 'content'},
            {'id': 'content', 'component': 'Column', 'children': ['header', 'body', 'divider', 'footer']},
            {'id': 'header', 'component': 'Row', 'align': 'center', 'children': ['icon', 'title']},
            {'id': 'icon', 'component': 'Icon', 'name': 'star'},
            {'id': 'title', 'component': 'Text', 'text': '## Potion Lab'},
            {'id': 'body', 'component': 'Text', 'text': 'You asked for: $prompt'},
            {'id': 'divider', 'component': 'Divider'},
            {'id': 'footer', 'component': 'Text', 'variant': 'caption', 'text': 'This card was written by hand, in JSON.'},
          ],
        },
      },
    ]);
  }

  void dispose() => processor.dispose();
}
