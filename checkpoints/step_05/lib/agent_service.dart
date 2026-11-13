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

  // Draws a form that you wrote by hand, in JSON.
  void _draw(String prompt) {
    // Every surface needs its own id.
    final surfaceId = 'card_${_surfaceCount++}';

    processor.processMessages([
      // Message 1: create an empty surface that uses the basic catalog.
      {
        'version': '1.0',
        'createSurface': {'surfaceId': surfaceId, 'catalogId': BasicCatalog.v1_0Id},
      },
      // Message 2: put some data in the surface's data model.
      {
        'version': '1.0',
        'updateDataModel': {
          'surfaceId': surfaceId,
          'value': {
            'potion': {'name': prompt, 'strength': 5},
          },
        },
      },
      // Message 3: the components. Inputs and texts point at the data with '@path'.
      {
        'version': '1.0',
        'updateComponents': {
          'surfaceId': surfaceId,
          'components': [
            {'id': 'root', 'component': 'Card', 'child': 'content'},
            {'id': 'content', 'component': 'Column', 'children': ['title', 'name_field', 'strength_slider', 'preview', 'brew_button']},
            {'id': 'title', 'component': 'Text', 'text': '## Brew a potion'},
            // Typing here writes into /potion/name...
            {'id': 'name_field', 'component': 'TextField', 'label': 'Potion name', 'value': {'@path': '/potion/name'}},
            {'id': 'strength_slider', 'component': 'Slider', 'label': 'Strength', 'min': 1, 'max': 10, 'value': {'@path': '/potion/strength'}},
            // ...and this text reads it back, so it updates as you type.
            {
              'id': 'preview',
              'component': 'Text',
              'text': {
                '@call': 'formatString',
                'args': {'value': r'You are brewing ${/potion/name} at strength ${/potion/strength}.'},
              },
            },
            {
              'id': 'brew_button',
              'component': 'Button',
              'variant': 'primary',
              'child': 'brew_label',
              // Pressing the button emits an action named 'brew', with the current values.
              'action': {
                'event': {
                  'name': 'brew',
                  'context': {
                    'name': {'@path': '/potion/name'},
                    'strength': {'@path': '/potion/strength'},
                  },
                },
              },
            },
            {'id': 'brew_label', 'component': 'Text', 'text': 'Brew it!'},
          ],
        },
      },
    ]);
  }

  void dispose() => processor.dispose();
}
