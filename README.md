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

* **Part 1, Set up:** a Flutter app with the A2UI packages, chatting with Gemini.
* **Part 2, Speak A2UI:** write A2UI by hand first, so you know exactly what the AI will write later: surfaces, components, the data model, data binding and actions.
* **Part 3, Hand the AI the pen:** let Gemini write the UI, give it a personality, show it photos, send button presses back to it, and give it functions so your code makes the rules.
* **Part 4, Make it truly yours:** design and draw your own component, and stream the UI in as Gemini writes it.
* **Bonus:** AI-painted illustrations, and a 3D companion built with [Flutter Scene](https://pub.dev/packages/flutter_scene).

> **Something not working?** Check [Troubleshooting](TROUBLESHOOTING.md) for the problems we've already hit.
>
> **Stuck?** The [`checkpoints`](checkpoints) folder holds the complete `lib/` folder at the end of every step. Copy one over yours: your `lib/api_key.dart` isn't in them, so it stays.

---

## Before You Start

* **Flutter SDK 3.38 or newer** (Dart 3.10 or newer). Run `flutter upgrade` to get the latest stable version.
* **Somewhere to run it:** we recommend **Chrome**, which needs no extra setup. You can also run on a phone or as a desktop app: for iOS and macOS you need Xcode, and for Android you need Android Studio.
* **A Google account**, to get a free Gemini API key in Step 1.

---

## The Steps

Work through them in order. Every step ends with a working app, and a **Make it yours** challenge.

* [Step 0: Pick Your Idea](steps/00-pick-your-idea.md)

**Part 1: Set Up**

* [Step 1: Get Your Gemini API Key](steps/01-get-your-gemini-api-key.md)
* [Step 2: Create Your Project](steps/02-create-your-project.md)
* [Step 3: The App Shell](steps/03-the-app-shell.md)

**Part 2: Speak A2UI**

* [Step 4: Your First Surface, by Hand](steps/04-your-first-surface-by-hand.md)
* [Step 5: Data and Actions, by Hand](steps/05-data-and-actions-by-hand.md)

**Part 3: Hand the AI the Pen**

* [Step 6: Gemini Writes the UI](steps/06-gemini-writes-the-ui.md)
* [Step 7: Give It a Personality](steps/07-give-it-a-personality.md)
* [Step 8: Show It the World](steps/08-show-it-the-world.md)
* [Step 9: Close the Loop](steps/09-close-the-loop.md)
* [Step 10: Rules the AI Can't Bend](steps/10-rules-the-ai-cant-bend.md)

**Part 4: Make It Truly Yours**

* [Step 11: Your Own Component](steps/11-your-own-component.md)
* [Step 12: Stream the UI](steps/12-stream-the-ui.md)

**Bonus Steps**

* [Bonus A: AI-Painted Illustrations](steps/bonus-a-ai-painted-illustrations.md)
* [Bonus B: A 3D Companion with Flutter Scene](steps/bonus-b-a-3d-companion-with-flutter-scene.md)

**Ready? [Start with Step 0: Pick Your Idea →](steps/00-pick-your-idea.md)**

---

## Show and Tell

You now have an app that nobody else has: your idea, your persona, your rules and your own components, with an AI that builds the UI on the fly. Show it off!

## Going Further

* [a2ui.org](https://a2ui.org/): the A2UI protocol, its messages and the basic catalog
* [`a2ui_flutter`](https://pub.dev/packages/a2ui_flutter): Markdown in texts, interactive custom components, and the v0.9 protocol
* [`a2ui_agent`](https://pub.dev/packages/a2ui_agent): the compact Express format, trimming a catalog, and running the agent on a Dart server
* [The official A2UI example](https://github.com/a2ui-project/a2ui/tree/main/dart/a2ui_flutter/example): a full chat that also sends rendering errors back to the model, so it can fix its own UI
* [Flutter Scene docs](https://fscene.dev): 3D models, materials, lighting, physics and more
* [`dartantic_ai`](https://pub.dev/packages/dartantic_ai): other AI providers, typed outputs and more

> **Before you ship:** your API key is built into the app. That's fine for a workshop and for apps that only run on your own machine, but anyone who downloads a published app could dig the key out and use your quota. For a real app, call Gemini from your own server, or use [Firebase AI Logic](https://firebase.google.com/docs/ai-logic) with App Check, which proves requests come from your app.

> **Security note:** treat any agent outside your control as untrusted. A malicious agent could imitate a real interface to trick users. In this workshop the agent is your own app talking to Gemini, but keep it in mind before you render UI from someone else's agent.
