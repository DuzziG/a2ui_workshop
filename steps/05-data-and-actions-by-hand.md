[← Step 4: Your First Surface, by Hand](04-your-first-surface-by-hand.md) &nbsp;·&nbsp; [Overview](../README.md) &nbsp;·&nbsp; [Step 6: Gemini Writes the UI →](06-gemini-writes-the-ui.md)

*Part 2: Speak A2UI*

# Step 5: Data and Actions, by Hand

> 🎯 **Goal:** a form whose inputs, texts and button are wired together, still without AI.

Every surface has a **data model**: a JSON object that belongs to the surface. Components connect to it with **bindings**:

* `{'@path': '/potion/name'}` binds a value to a place in the data model. An input **writes** to it, a text **reads** from it.
* `formatString` builds a text from several values, such as `'Hello ${/user/name}'`.
* A Button has an **action**. Pressing it emits an event with a name and a `context` read from the data model.

1.  **Update `lib/agent_service.dart`.** Only `_draw` changes. There is a new message, `updateDataModel`, which fills the data model.

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
    ```

2.  **Listen for actions in `lib/home_page.dart`.** Replace `initState` with this version, which adds the `onAction` line at its end, and add the new `_showAction` method right below it:

    ```dart
      @override
      void initState() {
        super.initState();
        // Whenever the processor creates or deletes a surface, update the screen.
        _agent.processor.model.onSurfaceCreated.subscribe((surface) => setState(() => _surfaces.add(surface)));
        _agent.processor.model.onSurfaceDeleted.subscribe((id) => setState(() => _surfaces.removeWhere((s) => s.id == id)));
        // When a button inside a surface is pressed, the processor emits an action.
        _agent.processor.model.onAction.subscribe(_showAction);
      }

      // For now, just show what the action carried.
      void _showAction(A2uiRendererAction action) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action "${action.name}" with ${action.context}')),
        );
      }
    ```

Run it, type a new name into the form and drag the slider: the preview text follows along. Press **Brew it!** and the snack bar shows the action with your values.

> 🧠 **What just happened:** the text field and the preview don't know about each other. They share a path in the data model, and A2UI keeps everything bound to it in sync. The button doesn't run any code of its own either: it emits an **action**. Right now `HomePage` shows it in a snack bar. In Step 9 it goes to Gemini.

> 🎨 **Make it yours:** build the main form of your idea. A character creator with a name and a strength slider? A quiz answer box? Try a `CheckBox` (it binds a `true`/`false` value), or a `ChoicePicker` with `options`.

---

[← Step 4: Your First Surface, by Hand](04-your-first-surface-by-hand.md) &nbsp;·&nbsp; [Overview](../README.md) &nbsp;·&nbsp; [Step 6: Gemini Writes the UI →](06-gemini-writes-the-ui.md)
