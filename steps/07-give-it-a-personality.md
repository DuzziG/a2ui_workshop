[← Step 6: Gemini Writes the UI](06-gemini-writes-the-ui.md) &nbsp;·&nbsp; [Overview](../README.md) &nbsp;·&nbsp; [Step 8: Show It the World →](08-show-it-the-world.md)

*Part 3: Hand the AI the Pen*

# Step 7: Give It a Personality

> 🎯 **Goal:** turn a general assistant into *your* app.

The system message tells the model who it is. With A2UI, you can describe its **UI** as well as its tone: which surfaces it shows, what goes in them, and how they are laid out.

**Update `lib/agent_service.dart`.** Add a persona, and put it before the A2UI rules in the system message. Replace parts 4 and 5 (from `// 4. Gemini` down to the `_history` line) with this. The rest of the file stays the same.

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

  // 5. Gemini, reached with your API key.
  final _gemini = Agent.forProvider(GoogleProvider(apiKey: geminiApiKey), chatModelName: 'gemini-3.6-flash');

  // 6. The conversation so far. The system message holds your persona first,
  //    then the A2UI rules.
  late final List<ChatMessage> _history = [ChatMessage.system('$_persona\n${_a2uiAgent.promptSnippet}')];
```

Run it and tell the Potion Master how you feel: *"I have an exam tomorrow"*, *"I'm hungry"*, *"my cat ignores me"*.

> 🧠 **What just happened:** the UI rules in your persona work like a design brief. Gemini follows them on every answer, so your app looks consistent, even though no layout code exists.

> 🎨 **Make it yours:** this is where your idea comes alive. Rewrite `_persona` from your sentence in Step 0. Give your agent:
> * **a character**: a name, a voice, a quirk
> * **a signature surface**: the exact card it always answers with, component by component
> * **one button** with an action name, which we use in Step 9
>
> Tip: describe the layout as a list, like the example. The more specific you are, the more consistent your app looks.

---

[← Step 6: Gemini Writes the UI](06-gemini-writes-the-ui.md) &nbsp;·&nbsp; [Overview](../README.md) &nbsp;·&nbsp; [Step 8: Show It the World →](08-show-it-the-world.md)
