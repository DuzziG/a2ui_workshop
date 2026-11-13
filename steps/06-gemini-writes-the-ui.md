[← Step 5: Data and Actions, by Hand](05-data-and-actions-by-hand.md) &nbsp;·&nbsp; [Overview](../README.md) &nbsp;·&nbsp; [Step 7: Give It a Personality →](07-give-it-a-personality.md)

*Part 3: Hand the AI the Pen · Step 6 of 12*

# Step 6: Gemini Writes the UI

> 🎯 **Goal:** replace your hand-written JSON with Gemini's.

How does Gemini learn A2UI? The `a2ui_agent` package handles both sides:

* `A2uiGenerator` writes a **prompt snippet** that teaches the model the A2UI rules and every component in your catalog, with each property described as a JSON schema.
* `StreamedAnswer` reads Gemini's reply. Text goes back to the page, and every `<a2ui-json>` block is checked against your catalog and handed to the processor. Anything that breaks the rules is rejected instead of drawn.

1.  **Update `lib/agent_service.dart`.** The hand-written messages are gone: Gemini writes them now. The system message now holds the prompt snippet, so Gemini learns A2UI before your first message.

    ```dart
    // lib/agent_service.dart
    import 'package:a2ui_agent/a2ui_agent.dart';
    import 'package:a2ui_core/a2ui_core.dart';
    import 'package:a2ui_flutter/a2ui_flutter.dart';
    import 'package:a2ui_flutter/basic_catalog.dart';
    import 'package:dartantic_ai/dartantic_ai.dart';
    import 'api_key.dart';

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

      // 4. Gemini, reached with your API key.
      final _gemini = Agent.forProvider(GoogleProvider(apiKey: geminiApiKey), chatModelName: 'gemini-3.6-flash');

      // 5. The conversation so far. The system message now holds the A2UI rules.
      late final List<ChatMessage> _history = [ChatMessage.system(_a2uiAgent.promptSnippet)];

      // The last raw reply from Gemini, for the X-ray view.
      String lastRawReply = '';

      Future<String> send(String prompt) async {
        try {
          final result = await _gemini.send(prompt, history: _history);
          _history.addAll(result.messages); // Remember this turn.
          return _render(result.output);
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

2.  **Create `lib/xray_view.dart`.** The X-ray view shows Gemini's raw reply, so you can see the JSON behind the UI. It indents every `<a2ui-json>` block so it's easy to read, and has a button to copy the reply.

    ```dart
    // lib/xray_view.dart
    import 'dart:convert';
    import 'package:flutter/material.dart';
    import 'package:flutter/services.dart';

    // Shows Gemini's raw reply, with every A2UI block pretty-printed.
    class XrayView extends StatelessWidget {
      const XrayView({super.key, required this.reply});
      final String reply;

      @override
      Widget build(BuildContext context) {
        final text = reply.isEmpty ? 'No reply yet. Ask Gemini for something!' : _prettify(reply);
        return ColoredBox(
          color: const Color(0xFF1E1E2E),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // A header with a copy button.
              Container(
                color: Colors.black26,
                padding: const EdgeInsets.only(left: 16),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text("X-ray: Gemini's last reply", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      tooltip: 'Copy',
                      icon: const Icon(Icons.copy, color: Colors.white70, size: 18),
                      onPressed: () => Clipboard.setData(ClipboardData(text: text)),
                    ),
                  ],
                ),
              ),
              // The reply itself, scrollable and selectable.
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    text,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.4, color: Color(0xFFA6E3A1)),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      // Indents the JSON inside every <a2ui-json> block, so it's easy to read.
      static String _prettify(String reply) => reply.replaceAllMapped(
        RegExp(r'<a2ui-json>(.*?)</a2ui-json>', dotAll: true),
        (match) {
          try {
            final json = const JsonEncoder.withIndent('  ').convert(jsonDecode(match[1]!));
            return '<a2ui-json>\n$json\n</a2ui-json>';
          } on FormatException {
            return match[0]!; // Not valid JSON: show it as it is.
          }
        },
      );
    }
    ```

3.  **Show it from `lib/home_page.dart`.** Add the import at the top, with the other imports:

    ```dart
    import 'xray_view.dart';
    ```

    Add a `_showXray` field right under `bool _isLoading = false;`:

    ```dart
      bool _isLoading = false;
      bool _showXray = false;
    ```

    Then replace the whole `build` method with this one. It gives the `AppBar` a button that toggles the X-ray, and chooses the body by screen width. On a wide screen, such as Chrome on a laptop, the chat and the X-ray sit side by side. On a narrow screen, the X-ray fills it until you press the button again. `_buildChat` below it stays the same.

    ```dart
      @override
      Widget build(BuildContext context) {
        final colors = Theme.of(context).colorScheme;
        return Scaffold(
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
          // X-ray off: just the chat. On a wide screen: the chat and the X-ray side by side.
          // On a narrow screen: the X-ray fills the screen.
          body: !_showXray
              ? _buildChat(context)
              : LayoutBuilder(
                  builder: (context, constraints) => constraints.maxWidth >= 800
                      ? Row(
                          children: [
                            Expanded(child: _buildChat(context)),
                            Expanded(child: XrayView(reply: _agent.lastRawReply)),
                          ],
                        )
                      : XrayView(reply: _agent.lastRawReply),
                ),
        );
      }
    ```

Run it and ask for anything:

* *"A sign-up form for a newsletter"*
* *"A weather card for Tokyo"*
* *"A to-do list for a picnic"*

Then press the **X-ray** button `</>` and read the reply.

> 🧠 **What just happened:** Gemini wrote the same kinds of messages you wrote in Steps 4 and 5, wrapped in `<a2ui-json>` tags with some text around them. The prompt snippet taught it the format, and your catalog limited it to components your app can draw.

> 🎨 **Make it yours:** ask for UI from *your* idea, and use X-ray to see how Gemini built it. Ask for something the basic catalog can't really do, such as a chess board or a chart. How does Gemini get by?

> **Stuck?** [`checkpoints/step_06`](../checkpoints/step_06/lib) holds the whole `lib/` folder at the end of this step. Compare it with yours, or copy it over yours: your `lib/api_key.dart` isn't in it, so your key stays.

---

[← Step 5: Data and Actions, by Hand](05-data-and-actions-by-hand.md) &nbsp;·&nbsp; [Overview](../README.md) &nbsp;·&nbsp; [Step 7: Give It a Personality →](07-give-it-a-personality.md)
