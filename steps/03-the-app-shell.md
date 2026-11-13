[← Step 2: Create Your Project](02-create-your-project.md) &nbsp;·&nbsp; [Overview](../README.md) &nbsp;·&nbsp; [Step 4: Your First Surface, by Hand →](04-your-first-surface-by-hand.md)

*Part 1: Set Up · Step 3 of 12*

# Step 3: The App Shell

> 🎯 **Goal:** an app with a prompt box that chats with Gemini.

We split the app in two, and keep it that way for the whole workshop:

* `AgentService` holds everything about A2UI and AI.
* `HomePage` only shows things and passes on what the user does.

That way, most later steps only change the service.

> **About the Material import:** these files import `package:flutter/material.dart`, because that's what `a2ui_flutter` is built with. On Flutter 3.47 and newer, your editor marks that line with a blue *deprecated* hint and suggests `package:material_ui`. It's only a hint, not an error, and the app runs fine. Don't switch to `material_ui` yet: it's a separate copy of Material, and A2UI's text fields crash under it because they can't find their Material localizations.

We create the files in the order they depend on each other, so your editor never shows an import that doesn't exist yet.

1.  **Create `lib/agent_service.dart`.** It sends your messages to Gemini and returns its answers. It keeps the conversation in `_history`, so Gemini remembers what you said. The first message in it is a **system message**: instructions that tell Gemini how to behave. The service also owns a `MessageProcessor`, the A2UI renderer, which we use in the next step.

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

      // Gemini, reached with your API key.
      final _gemini = Agent.forProvider(GoogleProvider(apiKey: geminiApiKey), chatModelName: 'gemini-3.6-flash');

      // The conversation so far. The system message tells Gemini how to behave.
      final List<ChatMessage> _history = [
        ChatMessage.system('You are a friendly assistant. Answer in one or two short sentences.'),
      ];

      Future<String> send(String prompt) async {
        try {
          final result = await _gemini.send(prompt, history: _history);
          _history.addAll(result.messages); // Remember this turn.
          return result.output;
        } catch (e) {
          return 'Error: $e';
        }
      }

      void dispose() => processor.dispose();
    }
    ```

2.  **Create `lib/home_page.dart`.** It shows three things, top to bottom: the surfaces, the agent's text reply, and the prompt box. They live in their own method, `_buildChat`, so we can put something next to them later. The page subscribes to the processor, so whenever a surface is created or deleted, the screen updates.

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
          body: _buildChat(context),
        );
      }

      // The chat: the surfaces, the agent's reply and the prompt box.
      Widget _buildChat(BuildContext context) {
        final colors = Theme.of(context).colorScheme;
        return Column(
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
        );
      }
    }
    ```

3.  **Replace `lib/main.dart`.** It shows the home page, or a reminder if you haven't pasted your API key yet.

    ```dart
    // lib/main.dart
    import 'package:flutter/material.dart';
    import 'api_key.dart';
    import 'home_page.dart';

    void main() => runApp(const MyApp());

    class MyApp extends StatelessWidget {
      const MyApp({super.key});

      @override
      Widget build(BuildContext context) {
        final hasKey = geminiApiKey.isNotEmpty && !geminiApiKey.startsWith('PASTE');
        return MaterialApp(
          title: 'My A2UI App',
          debugShowCheckedModeBanner: false, // The DEBUG banner would cover the app bar's buttons.
          theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
          home: hasKey
              ? const HomePage(title: 'My A2UI App')
              : const Scaffold(body: Center(child: Text('Paste your Gemini API key into lib/api_key.dart, then restart the app.'))),
        );
      }
    }
    ```

Run the app with `flutter run -d chrome` (or pick another device with `flutter run`). Say hello: Gemini answers.

> **Getting `API key not valid` or another error?** Check [Troubleshooting](../TROUBLESHOOTING.md) now, before you go on. If Gemini answers here, the rest of the workshop will work too.

> 🧠 **What just happened:** your app is chatting with Gemini, but only in text. `HomePage` doesn't know where answers come from. Next we add UI to the answers, and `HomePage` won't change at all.

> 🎨 **Make it yours:** rename the app in `main.dart`, pick a `seedColor` that fits your idea, and change the prompt box's hint text. Then change the system message in `agent_service.dart`, and see how Gemini's answers change.

> **Stuck?** [`checkpoints/step_03`](../checkpoints/step_03/lib) holds the whole `lib/` folder at the end of this step. Compare it with yours, or copy it over yours: your `lib/api_key.dart` isn't in it, so your key stays.

---

[← Step 2: Create Your Project](02-create-your-project.md) &nbsp;·&nbsp; [Overview](../README.md) &nbsp;·&nbsp; [Step 4: Your First Surface, by Hand →](04-your-first-surface-by-hand.md)
