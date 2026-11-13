// lib/agent_service.dart
import 'package:a2ui_core/a2ui_core.dart';
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:a2ui_flutter/basic_catalog.dart';

class AgentService {
  // The renderer: it applies A2UI messages and remembers every surface.
  final processor = MessageProcessor<ComponentImplementation>(catalogs: [basicCatalog()]);

  int _surfaceCount = 0;

  Future<String> send(String prompt) async {
    // Pretend to think for a second.
    await Future.delayed(const Duration(seconds: 1));

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

    return 'Try the form: the preview follows your input.';
  }

  void dispose() => processor.dispose();
}
