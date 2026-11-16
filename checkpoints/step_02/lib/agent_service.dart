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
    ChatMessage.system('You are a friendly, helpful assistant.'),
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

  // Draws a recipe card that you wrote by hand, in JSON.
  void _draw(String prompt) {
    // Every surface needs its own id.
    final surfaceId = 'recipe_${_surfaceCount++}';

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
            'recipe': {'name': 'Spinach and feta omelette', 'servings': 2},
          },
        },
      },
      // Message 3: the components. A flat list: 'root' is the top, and every
      // component points at its children by id. Inputs and texts point at the
      // data with '@path'.
      {
        'version': '1.0',
        'updateComponents': {
          'surfaceId': surfaceId,
          'components': [
            {'id': 'root', 'component': 'Card', 'child': 'content'},
            {
              'id': 'content',
              'component': 'Column',
              'children': ['header', 'asked', 'divider', 'name_field', 'servings_slider', 'preview', 'cook_button'],
            },
            {'id': 'header', 'component': 'Row', 'align': 'center', 'children': ['icon', 'title']},
            {'id': 'icon', 'component': 'Icon', 'name': 'star'},
            {'id': 'title', 'component': 'Text', 'text': '## Tonight\'s dinner'},
            {'id': 'asked', 'component': 'Text', 'variant': 'caption', 'text': 'You asked: $prompt'},
            {'id': 'divider', 'component': 'Divider'},
            // Typing here writes into /recipe/name...
            {'id': 'name_field', 'component': 'TextField', 'label': 'Dish', 'value': {'@path': '/recipe/name'}},
            {'id': 'servings_slider', 'component': 'Slider', 'label': 'Servings', 'min': 1, 'max': 8, 'value': {'@path': '/recipe/servings'}},
            // ...and this text reads it back, so it updates as you type.
            {
              'id': 'preview',
              'component': 'Text',
              'text': {
                '@call': 'formatString',
                'args': {'value': r'Cooking ${/recipe/name} for ${/recipe/servings}.'},
              },
            },
            {
              'id': 'cook_button',
              'component': 'Button',
              'variant': 'primary',
              'child': 'cook_label',
              // Pressing the button emits an action named 'cook', with the current values.
              'action': {
                'event': {
                  'name': 'cook',
                  'context': {
                    'recipe': {'@path': '/recipe/name'},
                    'servings': {'@path': '/recipe/servings'},
                  },
                },
              },
            },
            {'id': 'cook_label', 'component': 'Text', 'text': 'Cook this'},
          ],
        },
      },
    ]);
  }

  void dispose() => processor.dispose();
}
