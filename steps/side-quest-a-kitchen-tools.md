[← Step 7: Make It Yours](07-make-it-yours.md) &nbsp;·&nbsp; [Overview](../README.md) &nbsp;·&nbsp; [Side Quest B: AI-Painted Dishes →](side-quest-b-ai-painted-dishes.md)

*Side Quests*

Each side quest adds one more feature to your app. They're written for Fridge Chef, with ideas for your own app in every **Make it yours**. They don't depend on each other: do one, two or all three, in any order. Each checkpoint holds Fridge Chef at the end of Step 6, plus that one side quest.

# Side Quest A: Kitchen Tools

> 🎯 **Goal:** your code decides the things that matter, and Gemini follows.

Ask a model what's in your cupboard and it will happily guess. Ask it to keep a shopping list and it forgets it after a few turns. **Function calling** fixes that: you give Gemini functions written in Dart, and it calls them when it needs a real answer.

Each function is a `Tool`: a name, a description, a schema for its inputs, and `onCall`, the Dart code that runs. When Gemini asks for one, `dartantic_ai` runs it, hands the result back to Gemini, and Gemini carries on, all inside one request.

Fridge Chef gets two:

* `checkPantry` returns the staples you always have, from a list in your code.
* `addToShoppingList` adds what's missing to a shopping list that your app keeps, and returns the whole list.

All the changes are in `lib/agent_service.dart`:

1.  **Add the functions.** Replace part 5 (the `_gemini` line) with this. It adds the functions as part 5, and gives them to Gemini with `tools` in part 6. Then change the number in the next comment, `// 6. The conversation so far`, to `7`.

    ```dart
      // 5. YOUR rules: functions that your code decides, not the AI.
      //    Gemini asks to call them, the agent runs them, and Gemini reads the result.
      static const _pantry = ['salt', 'pepper', 'olive oil', 'butter', 'flour', 'rice', 'garlic'];
      final List<String> _shoppingList = [];

      late final _tools = [
        Tool<Map<String, dynamic>>(
          name: 'checkPantry',
          description: 'Lists the staples the user always has in the kitchen.',
          onCall: (input) {
            _toolLog.add('checkPantry() -> $_pantry');
            return {'staples': _pantry};
          },
        ),
        Tool<Map<String, dynamic>>(
          name: 'addToShoppingList',
          description: 'Adds items to the user\'s shopping list, and returns the whole list.',
          inputSchema: S.object(
            properties: {'items': S.list(items: S.string(), description: 'The items to add, such as "2 eggs".')},
            required: ['items'],
          ),
          onCall: (input) {
            final items = [for (final item in input['items'] as List? ?? const []) '$item'];
            _shoppingList.addAll(items.where((item) => !_shoppingList.contains(item)));
            _toolLog.add('addToShoppingList(items: $items) -> $_shoppingList');
            return {'shoppingList': _shoppingList};
          },
        ),
      ];

      // The function calls of the last turn, for the X-ray view.
      final List<String> _toolLog = [];

      // 6. Gemini, reached with your API key, with your functions.
      late final _gemini = Agent.forProvider(
        GoogleProvider(apiKey: geminiApiKey),
        chatModelName: 'gemini-3.6-flash',
        tools: _tools,
      );
    ```

2.  **Log every call into the X-ray.** Replace the whole `_generate` method with this version. It clears the log at the start of every turn, and adds a `[function]` line for each call above Gemini's reply.

    ```dart
      // Streams one message to Gemini, with any attachments, and draws the reply as it arrives.
      Future<String> _generate(String prompt, [List<Part> attachments = const []]) async {
        _toolLog.clear();
        final stopwatch = Stopwatch()..start();
        final reply = StringBuffer();
        final newMessages = <ChatMessage>[];
        final answer = StreamedAnswer(_a2uiAgent, renderer: processor);
        try {
          await for (final chunk in _gemini.sendStream(prompt, history: _history, attachments: attachments)) {
            reply.write(chunk.output);
            answer.feed(chunk.output); // Each chunk updates the surfaces right away.
            newMessages.addAll(chunk.messages);
          }
          answer.close();
          _history.addAll(newMessages); // Remember this turn.
        } catch (e) {
          return 'Error: $e';
        }
        // How long the reply took, and how long it is, on top of the X-ray.
        final seconds = (stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1);
        lastRawReply = [
          '[${reply.length} characters in $seconds s]',
          for (final call in _toolLog) '[function] $call',
          '\n$reply',
        ].join('\n');

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

3.  **Tell the persona when to call them.** Here is Fridge Chef's whole persona after this side quest. Two things changed: a new line before `Give every new surface`, which asks Gemini to call `checkPantry` first, and a new paragraph at the end, about the **Add to shopping list** button. Following Fridge Chef? Replace your `_persona` with this. Made it your own in Step 7? Add lines like them to yours, for your own functions.

    ```dart
      // 4. YOUR idea: who the agent is, and what its UI looks like.
      static const _persona = '''
    You are Chef Pip, a cheerful little chef who hates wasting food.
    The user tells you what is in their fridge, or what they feel like eating, or shows you a photo of their fridge.
    You suggest one dish they can cook with it. When you get a photo, use only what you can see in it, plus salt, pepper and oil.

    Always answer with one short, friendly sentence, and exactly one new A2UI surface, a recipe card:
    - a Card whose first child is the dish's name as a "## " heading
    - one line on why this dish works with what they have
    - the cooking time and the difficulty as caption Text
    - the ingredients as a List of Text, with amounts for 2 servings
    - a Slider labeled "Servings", from 1 to 8, bound to /servings, which starts at 2
    - a "Cook this" Button with an event action named "cook", whose context holds the dish's name,
      and the servings bound to /servings
    Before you suggest a dish, call checkPantry: the user has those staples too, so you may use them.
    Give every new surface a new surfaceId. Never answer with text only.

    When the user presses a button, the next user turn is JSON: {"messages": [...]} with an action,
    its name, the surfaceId of its surface, and its context.
    Answer a "cook" action with one encouraging sentence, and update the SAME surface. It already exists, so never create it again:
    only send its new components, with its surfaceId. Replace what is inside the Card with the dish's name as a "## " heading, the ingredients with every amount
    scaled to the servings in the context, and the steps as a numbered List of Text.
    Put a CookingTimer right after every step that needs waiting, such as boiling, baking or resting,
    with its minutes and a short label.
    Below the steps, put an "Add to shopping list" Button with an event action named "shop", whose context holds
    the ingredients the user is missing. Answer a "shop" action by calling addToShoppingList with them, and add
    the whole shopping list it returns to the same surface, as a List of CheckBox.
    ''';
    ```

Restart the app, ask for a dish and open X-ray. You'll see lines like `[function] checkPantry() -> [salt, pepper, ...]` above Gemini's reply. Press **Add to shopping list**, then ask for another dish and add to the list again: it keeps growing, because it lives in your code, not in Gemini's memory.

> 🧠 **What just happened:** Gemini can't see your pantry, so it *asks* your app, and has to use the answer. The truth lives in your code, and the AI builds the UI around it.

> 🎨 **Make it yours:** what in your app should be decided by code, not by the AI? Some ideas:
> * a score, a health bar or a hunger level that your app keeps track of
> * a die roll, or a random pick from your own list
> * the real date and time (the model doesn't know it)
> * a list of quiz questions, levels or items that you wrote

> 💾 **Using Git?** `git diff` shows everything this step changed. Save it with `git add -A && git commit -m "Side Quest A: Kitchen Tools"`.

> **Stuck?** [`checkpoints/side_quest_a`](../checkpoints/side_quest_a/lib) holds the whole `lib/` folder at the end of this step. Compare it with yours, or copy it over yours: your `lib/api_key.dart` isn't in it, so your key stays. Cloned this repository? From your project folder, `git diff --no-index path/to/a2ui_workshop/checkpoints/side_quest_a/lib lib` shows every line where yours differs.

---

[← Step 7: Make It Yours](07-make-it-yours.md) &nbsp;·&nbsp; [Overview](../README.md) &nbsp;·&nbsp; [Side Quest B: AI-Painted Dishes →](side-quest-b-ai-painted-dishes.md)
