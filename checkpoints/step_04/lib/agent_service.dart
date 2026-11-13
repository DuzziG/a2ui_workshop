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

    return 'Here is a card I wrote by hand.';
  }

  void dispose() => processor.dispose();
}
