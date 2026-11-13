[← Step 3: The App Shell](03-the-app-shell.md) &nbsp;·&nbsp; [Overview](../README.md) &nbsp;·&nbsp; [Step 5: Data and Actions, by Hand →](05-data-and-actions-by-hand.md)

*Part 2: Speak A2UI*

Before an AI writes A2UI, you will write it yourself. Then, when Gemini does it, you'll recognize every line.

# Step 4: Your First Surface, by Hand

> 🎯 **Goal:** Gemini still writes the text answer. Next to it, draw a card from JSON you write yourself.

A **surface** is one self-contained piece of UI, like a card in a chat. You build it with **messages**:

* `createSurface` creates an empty surface and names its **catalog**, the set of components it can use.
* `updateComponents` adds components to it. They come as a **flat list**, not a tree: the component with the id `root` is the top, and every component names its children by id.

```
root (Card)
 └─ content (Column)
     ├─ header (Row) ── icon (Icon), title (Text)
     ├─ body (Text)
     ├─ divider (Divider)
     └─ footer (Text)
```

**Update `lib/agent_service.dart`.** `send` still asks Gemini for its answer (now in `_ask`), and then calls `_draw`, which draws a card you wrote by hand:

```dart
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
```

Run the app and send anything. Gemini answers, and your card appears.

> 🧠 **What just happened:** you didn't write a single widget. You described a card, and `a2ui_flutter` turned it into a Material `Card`, `Column`, `Row`, `Icon` and `Text`. Texts can use a little Markdown: a line starting with `## ` becomes a heading.

> 🎨 **Make it yours:** make this the welcome card of *your* app. Change the title and the icon (try `favorite`, `home`, `photo` or `shoppingCart`), and add a second `Row`. Break it on purpose too: rename `root`, or point a child at an id that doesn't exist. What happens?

---

[← Step 3: The App Shell](03-the-app-shell.md) &nbsp;·&nbsp; [Overview](../README.md) &nbsp;·&nbsp; [Step 5: Data and Actions, by Hand →](05-data-and-actions-by-hand.md)
