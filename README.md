# Dream It, Render It
### Build a generative UI app in Flutter with A2UI and Gemini

In this workshop you build an app where an AI doesn't answer with text: it answers with **real, interactive Flutter UI**. Cards, forms, sliders, buttons, and in the end, components you design and draw yourself.

The app is **yours**. You pick the idea in Step 0, and every step ends with a **Make it yours** challenge. By the end, no two apps in the room will look alike.

## What is A2UI?

[A2UI](https://a2ui.org/) (Agent-to-UI) is an open protocol in which an AI agent **describes** a user interface as JSON ("a Card with a heading, a slider and a button"), and your app **draws** it with its own native widgets.

```
 ┌──────────┐   JSON messages    ┌──────────────────┐   Flutter widgets   ┌──────────┐
 │  Gemini  │ ─────────────────▶ │ MessageProcessor │ ──────────────────▶ │  Screen  │
 │ (agent)  │ ◀───────────────── │  (a2ui_flutter)  │ ◀────────────────── │  (user)  │
 └──────────┘   actions + data   └──────────────────┘     taps, typing    └──────────┘
```

Two things make A2UI safe and fun to build with:

* **The agent never sends code.** It can only use the components in your **catalog**, so it can't run anything you didn't build.
* **You decide what the catalog holds.** Add your own components, and the AI learns to use them.

## What you will learn

* **Part 1, Set up:** a Flutter app with Firebase and the A2UI packages.
* **Part 2, Speak A2UI:** write A2UI by hand first, so you know exactly what the AI will write later: surfaces, components, the data model, data binding and actions.
* **Part 3, Hand the AI the pen:** let Gemini write the UI, give it a personality, show it photos, send button presses back to it, and give it functions so your code makes the rules.
* **Part 4, Make it truly yours:** design and draw your own component, and stream the UI in as Gemini writes it.
* **Bonus:** AI-painted illustrations, and a 3D companion built with [Flutter Scene](https://pub.dev/packages/flutter_scene).

> **Something not working?** Check [Troubleshooting](TROUBLESHOOTING.md) for the problems we've already hit.
>
> **Stuck?** The [`checkpoints`](checkpoints) folder holds the complete `lib/` folder at the end of every step. Copy one over yours, but keep your own `lib/firebase_options.dart`.

---

## Step 0: Pick Your Idea

Before writing any code, decide what your app is. Write it down in one sentence: *"My app is a ___ that ___."* You will turn that sentence into your agent's personality in Step 7.

All the examples in this guide build **Potion Lab**: a grumpy Potion Master invents potions for whatever you are feeling. Use it to follow along, but your app can be anything. Need ideas?

| Idea | What the AI shows you |
| ---- | --------------------- |
| **Dungeon Master** | Rooms, monsters and choices for a text adventure, with your health and inventory |
| **Pet Simulator** | A virtual pet that gets hungry, bored and sleepy, with buttons to feed and play |
| **Quiz Show Host** | Quiz cards on any topic, with a score and a dramatic host |
| **Outfit Judge** | Show it a photo of your outfit, get a scorecard and a tip |
| **Fridge Chef** | Show it your fridge, get recipe cards with checklists |
| **Travel Planner** | A day plan for any city, as a timeline with checkboxes |
| **Band Generator** | A band name, logo idea, setlist and tour poster |
| **Alien Translator** | Translate anything into an alien language, with a pronunciation guide |

> 🎨 **Make it yours:** a mix of two ideas is often the most fun. A quiz show hosted by a pirate? A pet that is also a dungeon?

---

# Part 1: Set Up

## Prerequisites

* **Flutter SDK 3.38 or newer** (Dart 3.10 or newer). Run `flutter upgrade` to get the latest stable version.
* **Somewhere to run it:** we recommend **Chrome**, which needs no extra setup. You can also run on a phone or as a desktop app: for iOS and macOS you need Xcode, and for Android you need Android Studio.
* **A Firebase project**, with Gemini enabled:
    1. Open the [Firebase console](https://console.firebase.google.com/) and create a new project. Any name works.
    2. You can turn off Google Analytics.
    3. Open **AI Logic** and click **Get started**. Choose the free **Gemini Developer API**.

## Step 1: Install the Command Line Tools

1.  **Install the Firebase CLI.** This needs `npm`, which comes with Node.js. [docs](https://firebase.google.com/docs/cli#mac-linux-npm)
    ```sh
    npm install -g firebase-tools
    ```
2.  **Log into Firebase:**
    ```sh
    firebase login
    ```
3.  **Install the FlutterFire CLI:** [docs](https://firebase.google.com/docs/flutter/setup)
    ```sh
    dart pub global activate flutterfire_cli
    ```

    > **`flutterfire: command not found`?** The command was installed in a folder your terminal doesn't search yet. Add it to your `PATH` and open a new terminal, as shown in [Troubleshooting](TROUBLESHOOTING.md#1-flutterfire-is-not-found-after-installing-it). Or, for now, run `dart pub global run flutterfire_cli:flutterfire configure` in place of `flutterfire configure`.

## Step 2: Create Your Project

1.  **Create the app** and go into its folder:
    ```sh
    flutter create my_a2ui_app
    cd my_a2ui_app
    ```
    Run every command from this folder from now on.

2.  **Add the packages.** `firebase_core` connects the app to Firebase, so add it before you run `flutterfire configure`. `a2ui_core` reads A2UI messages and keeps the state of every surface. `a2ui_flutter` draws those surfaces as Flutter widgets.
    ```sh
    flutter pub add firebase_core a2ui_flutter a2ui_core
    ```

3.  **Connect it to Firebase.** Pick your project and the platforms you want. This writes `lib/firebase_options.dart`.
    ```sh
    flutterfire configure
    ```

    > **On a Mac, does it stop with `cannot load such file -- xcodeproj`?** FlutterFire needs the `xcodeproj` Ruby gem to add the iOS config to your Xcode project. Your Firebase apps were already created, so install the gem with `sudo gem install xcodeproj` and run `flutterfire configure` again, this time picking your existing project. Or skip iOS for now: select only **android** and **web**. Either way, check that `lib/firebase_options.dart` exists afterwards. [More in Troubleshooting](TROUBLESHOOTING.md#2-flutterfire-configure-stops-with-cannot-load-such-file----xcodeproj).
    >
    > **Did you create the project from here, with `<create a new project>`?** Then enable Gemini for it too: in the Firebase console, open your project, go to **AI Logic**, click **Get started** and choose the **Gemini Developer API**.

## Step 3: The App Shell

> 🎯 **Goal:** an app with a prompt box that talks to a placeholder agent.

We split the app in two, and keep it that way for the whole workshop:

* `AgentService` holds everything about A2UI and AI.
* `HomePage` only shows things and passes on what the user does.

That way, most later steps only change the service.

> **About the Material import:** these files import `package:flutter/material.dart`, because that's what `a2ui_flutter` is built with. On Flutter 3.47 and newer, your editor marks that line with a blue *deprecated* hint and suggests `package:material_ui`. It's only a hint, not an error, and the app runs fine. Don't switch to `material_ui` yet: it's a separate copy of Material, and A2UI's text fields crash under it because they can't find their Material localizations.

We create the files in the order they depend on each other, so your editor never shows an import that doesn't exist yet.

1.  **Create `lib/agent_service.dart`.** For now it pretends to think and answers with text. It already owns a `MessageProcessor`, the A2UI renderer, which we use in the next step.

    ```dart
    // lib/agent_service.dart
    import 'package:a2ui_core/a2ui_core.dart';
    import 'package:a2ui_flutter/a2ui_flutter.dart';
    import 'package:a2ui_flutter/basic_catalog.dart';

    class AgentService {
      // The renderer: it applies A2UI messages and remembers every surface.
      final processor = MessageProcessor<ComponentImplementation>(catalogs: [basicCatalog()]);

      Future<String> send(String prompt) async {
        // Pretend to think for a second.
        await Future.delayed(const Duration(seconds: 1));
        return 'You said "$prompt". Soon I will answer with real UI!';
      }

      void dispose() => processor.dispose();
    }
    ```

2.  **Create `lib/home_page.dart`.** It shows three things, top to bottom: the surfaces, the agent's text reply, and the prompt box. It subscribes to the processor, so whenever a surface is created or deleted, the screen updates.

    ```dart
    // lib/home_page.dart
    import 'package:a2ui_core/a2ui_core.dart';
    import 'package:a2ui_flutter/a2ui_flutter.dart';
    import 'package:flutter/material.dart';
    import 'agent_service.dart';

    class HomePage extends StatefulWidget {
      const HomePage({super.key, required this.title});
      final String title;

      @override
      State<HomePage> createState() => _HomePageState();
    }

    class _HomePageState extends State<HomePage> {
      final _promptController = TextEditingController();
      final _agent = AgentService();
      final List<SurfaceModel<ComponentImplementation>> _surfaces = [];
      String _reply = '';
      bool _isLoading = false;

      @override
      void initState() {
        super.initState();
        // Whenever the processor creates or deletes a surface, update the screen.
        _agent.processor.model.onSurfaceCreated.subscribe((surface) => setState(() => _surfaces.add(surface)));
        _agent.processor.model.onSurfaceDeleted.subscribe((id) => setState(() => _surfaces.removeWhere((s) => s.id == id)));
      }

      // Sends what the user typed to the agent.
      Future<void> _sendPrompt() async {
        final prompt = _promptController.text.trim();
        if (prompt.isEmpty) return;
        _promptController.clear();
        await _run(() => _agent.send(prompt));
      }

      // Runs one request to the agent and shows its reply.
      Future<void> _run(Future<String> Function() request) async {
        if (_isLoading) return;
        setState(() {
          _isLoading = true;
          _reply = '';
        });

        final reply = await request();

        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _reply = reply;
        });
      }

      @override
      void dispose() {
        _promptController.dispose();
        _agent.dispose();
        super.dispose();
      }

      @override
      Widget build(BuildContext context) {
        final colors = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(backgroundColor: colors.inversePrimary, title: Text(widget.title)),
          body: Column(
            children: [
              // 1. The surfaces: newest at the bottom, like a chat.
              Expanded(
                child: _surfaces.isEmpty
                    ? const Center(child: Text('Nothing here yet. Ask for something!'))
                    : ListView(
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        children: [
                          for (final surface in _surfaces.reversed)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: A2uiSurface(key: ObjectKey(surface), surface: surface),
                            ),
                        ],
                      ),
              ),
              // 2. The agent's text reply, and a progress bar while it works.
              if (_isLoading) const LinearProgressIndicator(),
              if (_reply.isNotEmpty)
                Container(
                  width: double.infinity,
                  color: colors.secondaryContainer,
                  padding: const EdgeInsets.all(12),
                  child: Text(_reply),
                ),
              // 3. The prompt box.
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _promptController,
                          decoration: const InputDecoration(hintText: 'Ask for something...', border: OutlineInputBorder()),
                          onSubmitted: (_) => _sendPrompt(),
                        ),
                      ),
                      IconButton.filled(onPressed: _isLoading ? null : _sendPrompt, icon: const Icon(Icons.send)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }
    ```

3.  **Replace `lib/main.dart`.** It starts Firebase, then shows the home page.

    ```dart
    // lib/main.dart
    import 'package:firebase_core/firebase_core.dart';
    import 'package:flutter/material.dart';
    import 'firebase_options.dart';
    import 'home_page.dart';

    void main() async {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      runApp(const MyApp());
    }

    class MyApp extends StatelessWidget {
      const MyApp({super.key});

      @override
      Widget build(BuildContext context) {
        return MaterialApp(
          title: 'My A2UI App',
          theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
          home: const HomePage(title: 'My A2UI App'),
        );
      }
    }
    ```

Run the app with `flutter run -d chrome` (or pick another device with `flutter run`), type something and press send.

> 🧠 **What just happened:** nothing magical yet, and that's the point. `HomePage` doesn't know where answers come from. Next we make `AgentService` answer with UI, and `HomePage` won't change at all.

> 🎨 **Make it yours:** rename the app in `main.dart`, pick a `seedColor` that fits your idea, and change the prompt box's hint text.

---

# Part 2: Speak A2UI

Before an AI writes A2UI, you will write it yourself. Then, when Gemini does it, you'll recognize every line.

## Step 4: Your First Surface, by Hand

> 🎯 **Goal:** draw a card from JSON you write yourself.

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

**Update `lib/agent_service.dart`:**

```dart
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
```

Run the app and send anything. A card appears.

> 🧠 **What just happened:** you didn't write a single widget. You described a card, and `a2ui_flutter` turned it into a Material `Card`, `Column`, `Row`, `Icon` and `Text`. Texts can use a little Markdown: a line starting with `## ` becomes a heading.

> 🎨 **Make it yours:** make this the welcome card of *your* app. Change the title and the icon (try `favorite`, `home`, `photo` or `shoppingCart`), and add a second `Row`. Break it on purpose too: rename `root`, or point a child at an id that doesn't exist. What happens?

## Step 5: Data and Actions, by Hand

> 🎯 **Goal:** a form whose inputs, texts and button are wired together, still without AI.

Every surface has a **data model**: a JSON object that belongs to the surface. Components connect to it with **bindings**:

* `{'@path': '/potion/name'}` binds a value to a place in the data model. An input **writes** to it, a text **reads** from it.
* `formatString` builds a text from several values, such as `'Hello ${/user/name}'`.
* A Button has an **action**. Pressing it emits an event with a name and a `context` read from the data model.

1.  **Update `lib/agent_service.dart`.** There is a new message, `updateDataModel`, which fills the data model.

    ```dart
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
    ```

2.  **Listen for actions in `lib/home_page.dart`.** In `initState`, under the `onSurfaceDeleted` line, subscribe to `onAction`. Then add the `_showAction` method below `initState`:

    ```dart
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

# Part 3: Hand the AI the Pen

## Step 6: Gemini Writes the UI

> 🎯 **Goal:** replace your hand-written JSON with Gemini's.

How does Gemini learn A2UI? The `a2ui_agent` package handles both sides:

* `A2uiGenerator` writes a **prompt snippet** that teaches the model the A2UI rules and every component in your catalog, with each property described as a JSON schema.
* `StreamedAnswer` reads Gemini's reply. Text goes back to the page, and every `<a2ui-json>` block is checked against your catalog and handed to the processor. Anything that breaks the rules is rejected instead of drawn.

1.  **Add the packages:**
    ```sh
    flutter pub add firebase_ai a2ui_agent
    ```

2.  **Update `lib/agent_service.dart`.** The hand-written messages are gone. Gemini writes them now.

    ```dart
    // lib/agent_service.dart
    import 'package:a2ui_agent/a2ui_agent.dart';
    import 'package:a2ui_core/a2ui_core.dart';
    import 'package:a2ui_flutter/a2ui_flutter.dart';
    import 'package:a2ui_flutter/basic_catalog.dart';
    import 'package:firebase_ai/firebase_ai.dart';

    class AgentService {
      // 1. The catalog: every component the app can draw.
      static final _catalog = basicCatalog();

      // 2. The renderer: it applies A2UI messages and remembers every surface.
      final processor = MessageProcessor<ComponentImplementation>(catalogs: [_catalog]);

      // 3. The A2UI agent kit: writes a prompt that teaches Gemini our catalog,
      //    and checks Gemini's reply against it.
      final _a2uiAgent = A2uiGenerator(
        catalogs: [CatalogConfig(_catalog)],
        inferenceFormatFactory: const DirectJsonFormatFactory(),
      ).createProcessor(
        A2uiRendererCapabilities.forCatalogIds([BasicCatalog.v1_0Id], version: A2uiProtocolVersion.v1_0),
      );

      // 4. The model, with the A2UI rules as its system instruction.
      late final _model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-3.6-flash',
        systemInstruction: Content.system(_a2uiAgent.promptSnippet),
      );

      // The last raw reply from Gemini, for the X-ray view.
      String lastRawReply = '';

      Future<String> send(String prompt) async {
        try {
          final response = await _model.generateContent([Content.text(prompt)]);
          return _render(response.text ?? '');
        } catch (e) {
          return 'Error: $e';
        }
      }

      // Splits a reply into text for the page and A2UI messages for the processor.
      String _render(String reply) {
        lastRawReply = reply;
        final answer = StreamedAnswer(_a2uiAgent, renderer: processor);
        answer.feed(reply);
        answer.close();

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
    ```

3.  **Add an X-ray view to `lib/home_page.dart`.** It shows Gemini's raw reply, so you can see the JSON behind the UI. Add a `_showXray` field to the state class:

    ```dart
      bool _isLoading = false;
      bool _showXray = false;
    ```

    Give the `AppBar` a button that toggles it:

    ```dart
          appBar: AppBar(
            backgroundColor: colors.inversePrimary,
            title: Text(widget.title),
            actions: [
              // X-ray: show the raw reply Gemini wrote.
              IconButton(
                icon: Icon(_showXray ? Icons.code_off : Icons.code),
                onPressed: () => setState(() => _showXray = !_showXray),
              ),
            ],
          ),
    ```

    And show the panel just above the prompt box:

    ```dart
              if (_showXray)
                Container(
                  height: 200,
                  width: double.infinity,
                  color: Colors.black87,
                  padding: const EdgeInsets.all(8),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      _agent.lastRawReply.isEmpty ? 'No reply yet.' : _agent.lastRawReply,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.greenAccent),
                    ),
                  ),
                ),
    ```

Run it and ask for anything:

* *"A sign-up form for a newsletter"*
* *"A weather card for Tokyo"*
* *"A to-do list for a picnic"*

Then press the **X-ray** button `</>` and read the reply.

> 🧠 **What just happened:** Gemini wrote the same kinds of messages you wrote in Steps 4 and 5, wrapped in `<a2ui-json>` tags with some text around them. The prompt snippet taught it the format, and your catalog limited it to components your app can draw.

> 🎨 **Make it yours:** ask for UI from *your* idea, and use X-ray to see how Gemini built it. Ask for something the basic catalog can't really do, such as a chess board or a chart. How does Gemini get by?

## Step 7: Give It a Personality

> 🎯 **Goal:** turn a general assistant into *your* app.

A system instruction tells the model who it is. With A2UI, you can describe its **UI** as well as its tone: which surfaces it shows, what goes in them, and how they are laid out.

**Update `lib/agent_service.dart`.** Add a persona, and put it before the A2UI rules in the system instruction. The rest of the file stays the same.

```dart
  // 4. YOUR idea: who the agent is, and what its UI looks like.
  static const _persona = '''
You are the Potion Master, the grumpy but brilliant owner of a tiny magical potion shop.
The user tells you a feeling, a problem or a wish. You invent a potion for it.

Always answer with one short sentence in character, and exactly one new A2UI surface, a potion card:
- a Card whose first child is the potion's name as a "## " heading
- one line of mysterious lore about the potion
- the ingredients as a List of Text, each with a silly amount ("3 whispers of moonlight")
- the effect, and one funny side effect, as caption Text
- a "Brew it!" Button with an event action named "brew"
Give every new surface a new surfaceId. Never answer with text only.
''';

  // 5. The model: your persona first, then the A2UI rules.
  late final _model = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-3.6-flash',
    systemInstruction: Content.system('$_persona\n${_a2uiAgent.promptSnippet}'),
  );
```

Run it and tell the Potion Master how you feel: *"I have an exam tomorrow"*, *"I'm hungry"*, *"my cat ignores me"*.

> 🧠 **What just happened:** the UI rules in your persona work like a design brief. Gemini follows them on every answer, so your app looks consistent, even though no layout code exists.

> 🎨 **Make it yours:** this is where your idea comes alive. Rewrite `_persona` from your sentence in Step 0. Give your agent:
> * **a character**: a name, a voice, a quirk
> * **a signature surface**: the exact card it always answers with, component by component
> * **one button** with an action name, which we use in Step 9
>
> Tip: describe the layout as a list, like the example. The more specific you are, the more consistent your app looks.

## Step 8: Show It the World

> 🎯 **Goal:** send a photo, get UI back.

Gemini is **multimodal**: it understands images as well as text. One message can carry both.

1.  **Add the image picker:**
    ```sh
    flutter pub add image_picker
    ```
    On iOS, add `NSPhotoLibraryUsageDescription` to `ios/Runner/Info.plist`. On macOS, add the `com.apple.security.files.user-selected.read-only` entitlement. On the web and Android there is nothing to set up. See the [image_picker docs](https://pub.dev/packages/image_picker) for details.

2.  **Update `lib/agent_service.dart`.** Both kinds of message now go through one `_generate` method, and `sendPhoto` sends the picture with a short instruction. We also tell the persona what to do with photos. Note the `hide TextPart`: `firebase_ai` and `a2ui_agent` both have a class with that name, and here we want Firebase's.

    ```dart
    // lib/agent_service.dart
    import 'dart:typed_data';
    import 'package:a2ui_agent/a2ui_agent.dart' hide TextPart; // firebase_ai has its own TextPart
    import 'package:a2ui_core/a2ui_core.dart';
    import 'package:a2ui_flutter/a2ui_flutter.dart';
    import 'package:a2ui_flutter/basic_catalog.dart';
    import 'package:firebase_ai/firebase_ai.dart';

    class AgentService {
      // 1. The catalog: every component the app can draw.
      static final _catalog = basicCatalog();

      // 2. The renderer: it applies A2UI messages and remembers every surface.
      final processor = MessageProcessor<ComponentImplementation>(catalogs: [_catalog]);

      // 3. The A2UI agent kit: writes a prompt that teaches Gemini our catalog,
      //    and checks Gemini's reply against it.
      final _a2uiAgent = A2uiGenerator(
        catalogs: [CatalogConfig(_catalog)],
        inferenceFormatFactory: const DirectJsonFormatFactory(),
      ).createProcessor(
        A2uiRendererCapabilities.forCatalogIds([BasicCatalog.v1_0Id], version: A2uiProtocolVersion.v1_0),
      );

      // 4. YOUR idea: who the agent is, and what its UI looks like.
      static const _persona = '''
    You are the Potion Master, the grumpy but brilliant owner of a tiny magical potion shop.
    The user tells you a feeling, a problem or a wish, or shows you a photo. You invent a potion for it.
    When you get a photo, whatever is in it becomes the potion's main ingredient.

    Always answer with one short sentence in character, and exactly one new A2UI surface, a potion card:
    - a Card whose first child is the potion's name as a "## " heading
    - one line of mysterious lore about the potion
    - the ingredients as a List of Text, each with a silly amount ("3 whispers of moonlight")
    - the effect, and one funny side effect, as caption Text
    - a "Brew it!" Button with an event action named "brew"
    Give every new surface a new surfaceId. Never answer with text only.
    ''';

      // 5. The model: your persona first, then the A2UI rules.
      late final _model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-3.6-flash',
        systemInstruction: Content.system('$_persona\n${_a2uiAgent.promptSnippet}'),
      );

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

      // Sends one message to Gemini and draws the reply.
      Future<String> _generate(Content content) async {
        try {
          final response = await _model.generateContent([content]);
          return _render(response.text ?? '');
        } catch (e) {
          return 'Error: $e';
        }
      }

      // Splits a reply into text for the page and A2UI messages for the processor.
      String _render(String reply) {
        lastRawReply = reply;
        final answer = StreamedAnswer(_a2uiAgent, renderer: processor);
        answer.feed(reply);
        answer.close();

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
    ```

3.  **Add a photo button to `lib/home_page.dart`.** Import the picker, add a `_sendPhoto` method next to `_sendPrompt`, and put a camera button in front of the prompt box:

    ```dart
    import 'package:image_picker/image_picker.dart';
    ```

    ```dart
      // Lets the user pick a photo and sends it to the agent.
      Future<void> _sendPhoto() async {
        final photo = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1024);
        if (photo == null) return;
        final bytes = await photo.readAsBytes();
        await _run(() => _agent.sendPhoto(bytes, photo.mimeType ?? 'image/jpeg'));
      }
    ```

    ```dart
                      IconButton(onPressed: _isLoading ? null : _sendPhoto, icon: const Icon(Icons.photo_camera)),
    ```

Run it and send a photo of anything: your shoe, your lunch, your neighbor's cat.

> 🧠 **What just happened:** `Content.multi` puts text and image parts in one message. Gemini looked at the picture, and your persona told it what to make of it.

> 🎨 **Make it yours:** decide what a photo *means* in your app. In a Dungeon Master, the photo becomes the next room. In a Fridge Chef, it's the ingredients. In an Outfit Judge, it's the whole point. Update the persona and the text in `sendPhoto`. To use the camera on a phone, try `ImageSource.camera`.

## Step 9: Close the Loop

> 🎯 **Goal:** buttons in Gemini's UI talk back to Gemini.

So far, UI only flows one way. Remember the action from Step 5? Now we send it to Gemini as the next message, and Gemini answers by **updating the surface it already made**. That turns a chat into an app.

Two things are needed:

* A **chat session** (`startChat`), so Gemini remembers the surfaces it created.
* The action as **JSON**, with the surface's current data model beside it, so Gemini knows what was pressed and what the user entered.

1.  **Update `lib/agent_service.dart`.** The persona explains the action messages and how to answer them, and `sendAction` sends them.

    ```dart
    // lib/agent_service.dart
    import 'dart:convert';
    import 'dart:typed_data';
    import 'package:a2ui_agent/a2ui_agent.dart' hide TextPart; // firebase_ai has its own TextPart
    import 'package:a2ui_core/a2ui_core.dart';
    import 'package:a2ui_flutter/a2ui_flutter.dart';
    import 'package:a2ui_flutter/basic_catalog.dart';
    import 'package:firebase_ai/firebase_ai.dart';

    class AgentService {
      // 1. The catalog: every component the app can draw.
      static final _catalog = basicCatalog();

      // 2. The renderer: it applies A2UI messages and remembers every surface.
      final processor = MessageProcessor<ComponentImplementation>(catalogs: [_catalog]);

      // 3. The A2UI agent kit: writes a prompt that teaches Gemini our catalog,
      //    and checks Gemini's reply against it.
      final _a2uiAgent = A2uiGenerator(
        catalogs: [CatalogConfig(_catalog)],
        inferenceFormatFactory: const DirectJsonFormatFactory(),
      ).createProcessor(
        A2uiRendererCapabilities.forCatalogIds([BasicCatalog.v1_0Id], version: A2uiProtocolVersion.v1_0),
      );

      // 4. YOUR idea: who the agent is, and what its UI looks like.
      static const _persona = '''
    You are the Potion Master, the grumpy but brilliant owner of a tiny magical potion shop.
    The user tells you a feeling, a problem or a wish, or shows you a photo. You invent a potion for it.
    When you get a photo, whatever is in it becomes the potion's main ingredient.

    Always answer with one short sentence in character, and exactly one new A2UI surface, a potion card:
    - a Card whose first child is the potion's name as a "## " heading
    - one line of mysterious lore about the potion
    - the ingredients as a List of Text, each with a silly amount ("3 whispers of moonlight")
    - the effect, and one funny side effect, as caption Text
    - a "Brew it!" Button with an event action named "brew", whose context holds the potion's name
    Give every new surface a new surfaceId and set "sendDataModel": true on it. Never answer with text only.

    When the user presses a button, the next user turn is JSON. Its "a2ui" holds {"messages": [...]}:
    an action with its name, surfaceId and context. Beside it, "metadata" holds each surface's data model.
    Answer a "brew" action in character, and update the SAME surface with an updateComponents message:
    add a Text that tells what happened when the user drank the potion. Do not create a new surface for it.
    ''';

      // 5. The model: your persona first, then the A2UI rules.
      late final _model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-3.6-flash',
        systemInstruction: Content.system('$_persona\n${_a2uiAgent.promptSnippet}'),
      );

      // 6. A chat remembers the conversation, so Gemini knows which surfaces it made.
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

      // Sends one message to Gemini and draws the reply.
      Future<String> _generate(Content content) async {
        try {
          final response = await _chat.sendMessage(content);
          return _render(response.text ?? '');
        } catch (e) {
          return 'Error: $e';
        }
      }

      // Splits a reply into text for the page and A2UI messages for the processor.
      String _render(String reply) {
        lastRawReply = reply;
        final answer = StreamedAnswer(_a2uiAgent, renderer: processor);
        answer.feed(reply);
        answer.close();

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
    ```

2.  **Send actions to the agent in `lib/home_page.dart`.** Replace the `onAction` line and the `_showAction` method from Step 5 with:

    ```dart
        // When a button inside a surface is pressed, send the action to the agent.
        _agent.processor.model.onAction.subscribe((action) => _run(() => _agent.sendAction(action)));
      }
    ```

Run it, get a potion and press **Brew it!**. The card itself changes to show what happened. Open X-ray to see the update Gemini sent.

The message Gemini receives looks like this:

```json
{
  "a2ui": {"messages": [{"version": "1.0", "action": {
    "name": "brew", "surfaceId": "potion_1", "sourceComponentId": "brew_button",
    "timestamp": "2026-11-13T12:10:07.253Z", "context": {"potion": "Liquid Courage"}}}]},
  "metadata": {"a2uiRendererDataModel": {"version": "1.0", "surfaces": {
    "potion_1": {"fill": 1}}}}
}
```

> 🧠 **What just happened:** you built the full A2UI loop. Gemini describes UI, the user acts on it, the action goes back, and Gemini updates the UI. Gemini sent an `updateComponents` for an existing surface instead of creating a new one, because your persona told it to.

> 🎨 **Make it yours:** make your button do something. A *Feed* button that changes your pet's mood, a *Next room* button that redraws the dungeon, an *Answer* button that scores the quiz. Add inputs too (a `TextField`, a `ChoicePicker`): their values arrive in the data model.

## Step 10: Rules the AI Can't Bend

> 🎯 **Goal:** your code decides the things that matter, and Gemini follows.

Ask a model to "roll a die" and it will happily pick whatever number makes a good story. Ask it what's in stock and it will invent things. **Function calling** fixes that: you give Gemini functions written in Dart, and it calls them when it needs a real answer.

With `AutoFunctionDeclaration`, the chat session runs your function, hands the result to Gemini, and Gemini carries on, all inside one `sendMessage` call.

**Update `lib/agent_service.dart`.** Add the functions and pass them to the model with `tools`. The persona tells Gemini when to call them. Every call is logged into the X-ray view, so you can watch it happen.

```dart
// lib/agent_service.dart
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:a2ui_agent/a2ui_agent.dart' hide TextPart; // firebase_ai has its own TextPart
import 'package:a2ui_core/a2ui_core.dart';
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:a2ui_flutter/basic_catalog.dart';
import 'package:firebase_ai/firebase_ai.dart';

class AgentService {
  // 1. The catalog: every component the app can draw.
  static final _catalog = basicCatalog();

  // 2. The renderer: it applies A2UI messages and remembers every surface.
  final processor = MessageProcessor<ComponentImplementation>(catalogs: [_catalog]);

  // 3. The A2UI agent kit: writes a prompt that teaches Gemini our catalog,
  //    and checks Gemini's reply against it.
  final _a2uiAgent = A2uiGenerator(
    catalogs: [CatalogConfig(_catalog)],
    inferenceFormatFactory: const DirectJsonFormatFactory(),
  ).createProcessor(
    A2uiRendererCapabilities.forCatalogIds([BasicCatalog.v1_0Id], version: A2uiProtocolVersion.v1_0),
  );

  // 4. YOUR idea: who the agent is, and what its UI looks like.
  static const _persona = '''
You are the Potion Master, the grumpy but brilliant owner of a tiny magical potion shop.
The user tells you a feeling, a problem or a wish, or shows you a photo. You invent a potion for it.
When you get a photo, whatever is in it becomes the potion's main ingredient.

Always answer with one short sentence in character, and exactly one new A2UI surface, a potion card:
- a Card whose first child is the potion's name as a "## " heading
- one line of mysterious lore about the potion
- the ingredients as a List of Text, each with a silly amount ("3 whispers of moonlight")
- the effect, and one funny side effect, as caption Text
- a "Brew it!" Button with an event action named "brew", whose context holds the potion's name
Before you invent a potion, call checkShelf, and only use ingredients that are on the shelf.
Give every new surface a new surfaceId and set "sendDataModel": true on it. Never answer with text only.

When the user presses a button, the next user turn is JSON. Its "a2ui" holds {"messages": [...]}:
an action with its name, surfaceId and context. Beside it, "metadata" holds each surface's data model.
Answer a "brew" action by calling rollDice with 20 sides: 1 is a disaster, 2 to 10 a wobbly
result, 11 to 19 a success and 20 a legend. Then answer in character, and update the SAME surface with an updateComponents message:
add a Text that tells the roll and what happened when the user drank the potion. Do not create a new surface for it.
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

  // Sends one message to Gemini and draws the reply.
  Future<String> _generate(Content content) async {
    _toolLog.clear();
    try {
      final response = await _chat.sendMessage(content);
      return _render(response.text ?? '');
    } catch (e) {
      return 'Error: $e';
    }
  }

  // Splits a reply into text for the page and A2UI messages for the processor.
  String _render(String reply) {
    lastRawReply = [for (final call in _toolLog) '[function] $call', reply].join('\n');
    final answer = StreamedAnswer(_a2uiAgent, renderer: processor);
    answer.feed(reply);
    answer.close();

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
```

Ask for a potion, brew it, and open X-ray. You'll see lines like `[function] rollDice(sides: 20) -> 17` above Gemini's reply.

> 🧠 **What just happened:** Gemini can't roll the die itself, so it *asks* your app to, and has to use the result. The truth lives in your code; the AI tells the story around it.

> 🎨 **Make it yours:** what in your app should be decided by code, not by the AI? Some ideas:
> * a score, a health bar or a hunger level that your app keeps track of
> * the real date and time (the model doesn't know it)
> * a list of quiz questions, levels or items that you wrote
> * a timer, or a random pick from your own list

---

# Part 4: Make It Truly Yours

## Step 11: Your Own Component

> 🎯 **Goal:** design and draw a widget, and let Gemini use it like any built-in one.

The basic catalog only gets you so far. Now you add a component that exists only in *your* app. You write three things:

1.  a **schema**: its name and the properties Gemini may set, each with a description. Gemini reads this in its prompt.
2.  a **builder**: turns those properties into a Flutter widget. You can use any Flutter you like here.
3.  a **catalog**: your components, with an id of your own, registered next to the basic catalog.

Potion Lab draws a `PotionBottle` with a `CustomPainter`. The `fill` property is bound to the data model, so when Gemini sets `/fill` to 0 after a brew, the liquid drains away with an animation.

1.  **Add the schema package:**
    ```sh
    flutter pub add json_schema_builder
    ```

2.  **Create `lib/my_catalog.dart`:**

    ```dart
    // lib/my_catalog.dart
    import 'package:a2ui_core/a2ui_core.dart';
    import 'package:a2ui_flutter/a2ui_flutter.dart';
    import 'package:flutter/material.dart';
    import 'package:json_schema_builder/json_schema_builder.dart' hide ValidationResult;

    // 1. Describe the component: its name and the properties Gemini may set.
    //    Gemini reads this schema and the descriptions in its prompt.
    final potionBottle = ComponentImplementation(
      name: 'PotionBottle',
      schema: Schema.object(
        description: 'A glass potion bottle filled with a colored liquid.',
        properties: {
          'color': _dynamic('String', 'The liquid color as a hex code, such as #7B2FF7.'),
          'fill': _dynamic('Number', 'How full the bottle is, from 0 (empty) to 1 (full).'),
          'label': _dynamic('String', 'A short label written under the bottle.'),
        },
        required: ['color', 'fill'],
      ),
      // 2. Build it: the resolved properties in, a Flutter widget out.
      builder: (context, node, props, buildChild) {
        final color = _parseHex(props.string('color'));
        final fill = (props.number('fill') ?? 1).clamp(0, 1).toDouble();
        return Column(
          children: [
            // Animate the liquid when Gemini changes the fill.
            TweenAnimationBuilder<double>(
              tween: Tween(end: fill),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, _) => CustomPaint(
                size: const Size(100, 140),
                painter: _BottlePainter(color: color, fill: value),
              ),
            ),
            if (props.string('label') case final label?) Text(label, style: Theme.of(context).textTheme.labelLarge),
          ],
        );
      },
    );

    // 3. Your own catalog, which sits next to the basic one.
    final myCatalog = CatalogImplementation(
      id: 'https://example.com/potion_lab/catalog.json',
      protocolVersion: A2uiProtocolVersion.v1_0,
      components: [potionBottle],
    );

    // A value Gemini can give as a literal or bind to the data model, with a description.
    Schema _dynamic(String type, String description) =>
        Schema.fromMap({r'$ref': 'common_types.json#/\$defs/Dynamic$type', 'description': description});

    Color _parseHex(String? hex) {
      final value = int.tryParse((hex ?? '').replaceFirst('#', ''), radix: 16);
      return value == null ? Colors.purple : Color(0xFF000000 | value);
    }

    // Draws a round flask with a neck, filled from the bottom.
    class _BottlePainter extends CustomPainter {
      _BottlePainter({required this.color, required this.fill});
      final Color color;
      final double fill;

      @override
      void paint(Canvas canvas, Size size) {
        final center = Offset(size.width / 2, size.height * 0.62);
        final radius = size.width * 0.45;
        final neck = Rect.fromCenter(center: Offset(size.width / 2, size.height * 0.2), width: size.width * 0.3, height: size.height * 0.3);
        // One outline: the round body and the neck merged together.
        final bottle = Path.combine(
          PathOperation.union,
          Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
          Path()..addRect(neck),
        );

        // The liquid: a rectangle that rises from the bottom of the round body,
        // clipped to the bottle's shape.
        canvas.save();
        canvas.clipPath(bottle);
        final top = center.dy + radius - 2 * radius * fill;
        canvas.drawRect(Rect.fromLTRB(0, top, size.width, size.height), Paint()..color = color);
        canvas.restore();

        // The glass outline and a cork.
        canvas.drawPath(bottle, Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = Colors.blueGrey);
        canvas.drawRect(Rect.fromLTWH(neck.left - 4, 0, neck.width + 8, size.height * 0.08), Paint()..color = Colors.brown);
      }

      @override
      bool shouldRepaint(_BottlePainter old) => old.color != color || old.fill != fill;
    }
    ```

3.  **Register your catalog in `lib/agent_service.dart`.** Import `my_catalog.dart`, use both catalogs everywhere the basic one was, and tell the persona about your component:

    ```dart
      // 1. The catalogs: every component the app can draw. Yours comes after the basic one.
      static final _catalogs = [basicCatalog(), myCatalog];

      // 2. The renderer: it applies A2UI messages and remembers every surface.
      final processor = MessageProcessor<ComponentImplementation>(catalogs: _catalogs);

      // 3. The A2UI agent kit: writes a prompt that teaches Gemini our catalogs,
      //    and checks Gemini's reply against them.
      final _a2uiAgent = A2uiGenerator(
        catalogs: [for (final catalog in _catalogs) CatalogConfig(catalog)],
        inferenceFormatFactory: const DirectJsonFormatFactory(),
      ).createProcessor(
        A2uiRendererCapabilities.forCatalogIds([for (final catalog in _catalogs) catalog.id], version: A2uiProtocolVersion.v1_0),
      );
    ```

    ```dart
    - a PotionBottle in the potion's color, whose fill is bound to /fill, which starts at 1
    ```

    ```dart
    add a Text that tells the roll and what happened when the user drank the potion, and set /fill to 0
    with an updateDataModel message, because the bottle is now empty. Do not create a new surface for it.
    ```

Run it. Every potion now comes in a bottle of its own color, and brewing empties it.

> 🧠 **What just happened:** Gemini never saw your Dart code, only your schema and its descriptions. That was enough for it to use the component, pick a color and bind the fill. The builder decides how it looks; Gemini decides when and with what values.

> 🎨 **Make it yours:** this is the most important challenge of the workshop. Design the one widget that makes your app *yours*:
> * a **health bar** or **mood meter** that fills and changes color
> * a **dice** face, a **card** from a deck, a **map** with a marker
> * a **pet** drawn from circles that looks happy or sad
> * a **countdown** ring, a **trophy**, a **progress** path
>
> Start from the bottle: change the painter, rename the properties, and write good descriptions so Gemini knows what they mean. To level up, make it interactive: read about `props.writable` and `props.action` in the [a2ui_flutter docs](https://pub.dev/packages/a2ui_flutter#defining-custom-components).

## Step 12: Stream the UI

> 🎯 **Goal:** watch the UI build itself while Gemini is still writing it.

Gemini can stream its reply in chunks, and `StreamedAnswer` can read chunk by chunk. Put them together and surfaces appear on screen as they are written.

**Update `lib/agent_service.dart`.** Three changes:

* the processor uses `ValidationConfig.relaxed`, so a half-written surface can already show
* `progressiveKeys` shows `text` and `label` values word by word
* `_generate` uses `sendMessageStream` and feeds each chunk as it arrives

```dart
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
```

```dart
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
```

`HomePage` doesn't change: it already keeps the surfaces on screen while it loads.

> 🧠 **What just happened:** each chunk Gemini streams is fed to the parser, which applies every message as soon as it is complete. The function calls from Step 10 still work: `sendMessageStream` runs them between chunks.

> 🎨 **Make it yours:** look at your persona's layout with fresh eyes. The first component Gemini writes appears first, so put the exciting part at the top.

---

# Bonus Steps

## Bonus A: AI-Painted Illustrations

> 🎯 **Goal:** a component that asks an image model to paint a picture.

A component's builder can do anything a widget can, including calling another AI. `Illustration` takes a `prompt` that Gemini writes, and an image model paints it.

1.  **Create `lib/illustration.dart`.** The image model answers with pictures as well as text, so we ask for both `responseModalities`. A cache stops it from painting the same picture twice when the surface rebuilds. Note the `show` on the `firebase_ai` import: `firebase_ai` has its own `Schema`, which would clash with `json_schema_builder`'s.

    ```dart
    // lib/illustration.dart
    import 'dart:typed_data';
    import 'package:a2ui_flutter/a2ui_flutter.dart';
    // Only what we need from firebase_ai: it has its own Schema, which would clash.
    import 'package:firebase_ai/firebase_ai.dart' show Content, FirebaseAI, GenerationConfig, ResponseModalities;
    import 'package:flutter/material.dart';
    import 'package:json_schema_builder/json_schema_builder.dart' hide ValidationResult;

    // A picture that an image model paints from a description Gemini writes.
    final illustration = ComponentImplementation(
      name: 'Illustration',
      schema: Schema.object(
        description: 'A picture painted by an AI artist.',
        properties: {
          'prompt': Schema.fromMap({
            r'$ref': r'common_types.json#/$defs/DynamicString',
            'description': 'What the picture shows and its art style, in one sentence.',
          }),
        },
        required: ['prompt'],
      ),
      builder: (context, node, props, buildChild) => _IllustrationView(prompt: props.string('prompt') ?? ''),
    );

    class _IllustrationView extends StatefulWidget {
      const _IllustrationView({required this.prompt});
      final String prompt;

      @override
      State<_IllustrationView> createState() => _IllustrationViewState();
    }

    class _IllustrationViewState extends State<_IllustrationView> {
      // The image model: it answers with pictures as well as text.
      static final _artist = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-3.1-flash-image',
        generationConfig: GenerationConfig(responseModalities: [ResponseModalities.text, ResponseModalities.image]),
      );

      // Pictures already painted, by prompt, so a rebuild doesn't paint again.
      static final _cache = <String, Future<Uint8List?>>{};

      late Future<Uint8List?> _image;

      @override
      void initState() {
        super.initState();
        _image = _paint(widget.prompt);
      }

      @override
      void didUpdateWidget(_IllustrationView old) {
        super.didUpdateWidget(old);
        if (old.prompt != widget.prompt) _image = _paint(widget.prompt);
      }

      static Future<Uint8List?> _paint(String prompt) => _cache.putIfAbsent(prompt, () async {
        final response = await _artist.generateContent([Content.text(prompt)]);
        return response.inlineDataParts.firstOrNull?.bytes;
      });

      @override
      Widget build(BuildContext context) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 200,
            width: double.infinity,
            child: FutureBuilder(
              future: _image,
              builder: (context, snapshot) => switch (snapshot) {
                AsyncSnapshot(:final Uint8List data) => Image.memory(data, fit: BoxFit.cover),
                AsyncSnapshot(hasError: true) || AsyncSnapshot(connectionState: ConnectionState.done) =>
                  const ColoredBox(color: Colors.black12, child: Icon(Icons.broken_image)),
                _ => const ColoredBox(color: Colors.black12, child: Center(child: CircularProgressIndicator())),
              },
            ),
          ),
        );
      }
    }
    ```

2.  **Add it to your catalog** in `lib/my_catalog.dart`:

    ```dart
    import 'illustration.dart';
    ```

    ```dart
      components: [potionBottle, illustration],
    ```

3.  **Ask for it in the persona** in `lib/agent_service.dart`:

    ```dart
    - an Illustration of the potion, with a prompt that names a fun art style
    ```

> **Note:** pictures use more of your free quota than text. If one comes back broken, you may have hit the limit for now.

> 🎨 **Make it yours:** pick an art style that fits your app, such as pixel art, watercolor or a movie poster, and put it in the persona. Or let the user choose a style with a `ChoicePicker`.

## Bonus B: A 3D Companion with Flutter Scene

> 🎯 **Goal:** give your agent a body: a 3D creature whose mood Gemini controls.

[Flutter Scene](https://pub.dev/packages/flutter_scene) is a 3D engine for Flutter. We build a creature from spheres, so there are no 3D files to find or import, and make it a component like any other. Gemini sets its `mood`, and the creature acts it out every frame.

1.  **Add the packages:**
    ```sh
    flutter pub add flutter_scene vector_math
    ```

2.  **Turn on Flutter GPU.** On the **web** there is nothing to do, so Chrome is the easiest way to try this step. On other platforms, run with `flutter run --enable-flutter-gpu`, or follow the [Enable Flutter GPU](https://pub.dev/packages/flutter_scene#enable-flutter-gpu) steps to switch it on for good. The first build takes longer, because Flutter Scene compiles its shaders.

3.  **Create `lib/companion.dart`.** The creature is one `Node` with a body and four eyeball spheres as its children, so moving the parent moves them all. `onTick` runs every frame and picks a bounce, spin and squash for the current mood.

    ```dart
    // lib/companion.dart
    import 'dart:math';
    import 'package:a2ui_flutter/a2ui_flutter.dart';
    import 'package:flutter/material.dart' hide Material;
    import 'package:flutter_scene/scene.dart';
    import 'package:json_schema_builder/json_schema_builder.dart' hide ValidationResult;
    import 'package:vector_math/vector_math.dart' as vm;

    // A little 3D creature, built from spheres, whose mood the agent controls.
    final companion = ComponentImplementation(
      name: 'Companion',
      schema: Schema.object(
        description: "The agent's 3D companion. It acts out its mood.",
        properties: {
          'mood': Schema.fromMap({
            r'$ref': r'common_types.json#/$defs/DynamicString',
            'description': 'One of: happy, excited, sleepy, grumpy.',
          }),
          'color': Schema.fromMap({
            r'$ref': r'common_types.json#/$defs/DynamicString',
            'description': 'Its body color as a hex code, such as #4CAF50.',
          }),
        },
        required: ['mood'],
      ),
      builder: (context, node, props, buildChild) => SizedBox(
        height: 180,
        child: CompanionView(mood: props.string('mood') ?? 'happy', color: props.string('color') ?? '#4CAF50'),
      ),
    );

    class CompanionView extends StatefulWidget {
      const CompanionView({super.key, required this.mood, required this.color});
      final String mood;
      final String color;

      @override
      State<CompanionView> createState() => _CompanionViewState();
    }

    class _CompanionViewState extends State<CompanionView> {
      final _scene = Scene();
      final _creature = Node(); // Moves as one: the body and eyes are its children.
      final _bodyMaterial = PhysicallyBasedMaterial();
      bool _ready = false;

      @override
      void initState() {
        super.initState();
        // The shaders load first, then we build the creature from spheres.
        Scene.initializeStaticResources().then((_) {
          final white = PhysicallyBasedMaterial()..baseColorFactor = vm.Vector4(1, 1, 1, 1);
          final black = PhysicallyBasedMaterial()..baseColorFactor = vm.Vector4(0.05, 0.05, 0.05, 1);
          _creature.add(Node(mesh: Mesh(SphereGeometry(radius: 0.8), _bodyMaterial)));
          for (final side in [-1.0, 1.0]) {
            _creature.add(Node(mesh: Mesh(SphereGeometry(radius: 0.22), white))..position = vm.Vector3(0.3 * side, 0.25, -0.65));
            _creature.add(Node(mesh: Mesh(SphereGeometry(radius: 0.1), black))..position = vm.Vector3(0.3 * side, 0.25, -0.85));
          }
          _scene.add(_creature);
          if (mounted) setState(() => _ready = true);
        });
      }

      // Runs every frame: move the creature the way its mood says.
      void _act(Duration elapsed, double deltaSeconds) {
        final hex = int.tryParse(widget.color.replaceFirst('#', ''), radix: 16) ?? 0x4CAF50;
        _bodyMaterial.baseColorFactor = vm.Vector4(((hex >> 16) & 0xFF) / 255, ((hex >> 8) & 0xFF) / 255, (hex & 0xFF) / 255, 1);

        final t = elapsed.inMilliseconds / 1000;
        final (bounce, spin, squash) = switch (widget.mood) {
          'excited' => ((sin(t * 12) * 0.4).abs(), t * 4, 1.0),
          'sleepy' => (0.0, sin(t) * 0.2, 0.85 + sin(t * 1.5) * 0.05),
          'grumpy' => (0.0, sin(t * 30) * 0.08, 0.9),
          _ => ((sin(t * 5) * 0.2).abs(), sin(t * 2) * 0.4, 1.0), // happy
        };
        _creature.position = vm.Vector3(0, bounce - 0.2, 0);
        _creature.rotation = vm.Quaternion.axisAngle(vm.Vector3(0, 1, 0), spin);
        _creature.scale = vm.Vector3(1, squash, 1);
      }

      @override
      Widget build(BuildContext context) {
        if (!_ready) return const Center(child: CircularProgressIndicator());
        return SceneView(
          _scene,
          camera: PerspectiveCamera(position: vm.Vector3(0, 0.4, -3.2), target: vm.Vector3(0, 0, 0)),
          onTick: _act,
        );
      }
    }
    ```

4.  **Add it to your catalog** in `lib/my_catalog.dart`:

    ```dart
    import 'companion.dart';
    ```

    ```dart
      components: [potionBottle, illustration, companion],
    ```

5.  **Tell the persona about its companion** in `lib/agent_service.dart`. The companion lives in its own surface, `companion`, and Gemini updates its mood through the data model on every answer:

    ```dart
    You have a companion: a small 3D creature that lives in your shop and shows how you feel.
    In your very first answer, also create a surface with the surfaceId "companion" that holds only a Companion,
    with its mood bound to /mood and its color bound to /color. In every later answer, send an updateDataModel
    for the "companion" surface that sets /mood to how you feel now: happy, excited, sleepy or grumpy.
    ```

6.  **Pin the companion to the top of the screen** in `lib/home_page.dart`. Show the `companion` surface above the feed, and leave it out of the feed itself:

    ```dart
              // 0. The companion surface stays pinned at the top.
              for (final surface in _surfaces.where((s) => s.id == 'companion'))
                A2uiSurface(key: ObjectKey(surface), surface: surface),
    ```

    ```dart
                          for (final surface in _surfaces.reversed.where((s) => s.id != 'companion'))
    ```

Run it, then make your agent happy, sleepy or grumpy, and watch its companion react.

> 🎨 **Make it yours:** build *your* companion. Give it ears (`SphereGeometry`), a hat (`CylinderGeometry`, `CapsuleGeometry`), a tail (`TorusGeometry`), or a body that isn't a sphere at all. Invent your own moods and how they move. Then let Gemini set more than the mood: a size, an outfit, a dance.

---

## Show and Tell

You now have an app that nobody else has: your idea, your persona, your rules and your own components, with an AI that builds the UI on the fly. Show it off!

## Going Further

* [a2ui.org](https://a2ui.org/): the A2UI protocol, its messages and the basic catalog
* [`a2ui_flutter`](https://pub.dev/packages/a2ui_flutter): Markdown in texts, interactive custom components, and the v0.9 protocol
* [`a2ui_agent`](https://pub.dev/packages/a2ui_agent): the compact Express format, trimming a catalog, and running the agent on a Dart server
* [The official A2UI example](https://github.com/a2ui-project/a2ui/tree/main/dart/a2ui_flutter/example): a full chat that also sends rendering errors back to the model, so it can fix its own UI
* [Flutter Scene docs](https://fscene.dev): 3D models, materials, lighting, physics and more

> **Security note:** treat any agent outside your control as untrusted. A malicious agent could imitate a real interface to trick users. In this workshop the agent is your own app talking to Gemini, but keep it in mind before you render UI from someone else's agent.
