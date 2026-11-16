[← Step 1: Set Up Your App](01-set-up-your-app.md) &nbsp;·&nbsp; [Overview](../README.md) &nbsp;·&nbsp; [Step 3: Gemini Writes the UI →](03-gemini-writes-the-ui.md)

*Part 2: Speak A2UI · Step 2 of 7*

Before an AI writes A2UI, you will write it yourself. Then, when Gemini does it, you'll recognize every line.

# Step 2: A Recipe Card, by Hand

> 🎯 **Goal:** Gemini still writes the text answer. Next to it, draw an interactive card from JSON you write yourself.

A **surface** is one self-contained piece of UI, like a card in a chat. You build it with **messages**:

* `createSurface` creates an empty surface and names its **catalog**, the set of components it can use.
* `updateComponents` adds components to it. They come as a **flat list**, not a tree: the component with the id `root` is the top, and every component names its children by id.
* `updateDataModel` fills the surface's **data model**: a JSON object that belongs to the surface.

Here is the card you're about to write:

```
root (Card)
 └─ content (Column)
     ├─ header (Row) ── icon (Icon), title (Text)
     ├─ asked (Text)
     ├─ divider (Divider)
     ├─ name_field (TextField)       writes /recipe/name
     ├─ servings_slider (Slider)     writes /recipe/servings
     ├─ preview (Text)               reads both
     └─ cook_button (Button)         emits the action "cook"
```

Components connect to the data model with **bindings**:

* `{'@path': '/recipe/name'}` binds a value to a place in the data model. An input **writes** to it, a text **reads** from it.
* `formatString` builds a text from several values, such as `'Cooking ${/recipe/name}'`.
* A Button has an **action**. Pressing it emits an event with a name and a `context`, read from the data model.

> 📖 **In the A2UI docs:** the [v1.0 specification](https://a2ui.org/specification/v1.0-a2ui/) describes every message and how data binding works, and the [basic catalog guide](https://a2ui.org/specification/v1.0-basic-catalog-implementation-guide/) lists every component you can use, with all its properties. Keep them open: you'll recognize everything in this step.

1.  **Update `lib/agent_service.dart`.** `send` still asks Gemini for its answer (now in `_ask`), and then calls `_draw`, which draws the card you wrote by hand:

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

Restart the app and send anything. Gemini answers, and your card appears. Type a new dish into the form and drag the slider: the preview text follows along. Press **Cook this** and a snack bar shows the action with your values.

> 🧠 **What just happened:** you didn't write a single widget. You described a card, and `a2ui_flutter` turned it into a Material `Card`, `Column`, `TextField`, `Slider` and `Button`. The text field and the preview don't know about each other: they share a path in the data model, and A2UI keeps everything bound to it in sync. The button doesn't run any code of its own either: it emits an **action**. In Step 4 it goes to Gemini.

> 🧪 **Try this:** change the icon (try `favorite`, `home` or `shoppingCart`), and add a `CheckBox` bound to `/recipe/vegetarian` (it binds a `true`/`false` value). Then break it on purpose: rename `root`, or point a child at an id that doesn't exist. What happens? Put it back the way it was before you go on.

> 💾 **Using Git?** `git diff` shows everything this step changed. Save it with `git add -A && git commit -m "Step 2: A Recipe Card, by Hand"`.

> **Stuck?** [`checkpoints/step_02`](../checkpoints/step_02/lib) holds the whole `lib/` folder at the end of this step. Compare it with yours, or copy it over yours: your `lib/api_key.dart` isn't in it, so your key stays. Cloned this repository? From your project folder, `git diff --no-index path/to/a2ui_workshop/checkpoints/step_02/lib lib` shows every line where yours differs.

---

[← Step 1: Set Up Your App](01-set-up-your-app.md) &nbsp;·&nbsp; [Overview](../README.md) &nbsp;·&nbsp; [Step 3: Gemini Writes the UI →](03-gemini-writes-the-ui.md)
