# Dream It, Render It
### Build a generative UI app in Flutter with A2UI and Gemini

In this workshop you build an app where an AI doesn't just answer with text: it answers with **real, interactive Flutter UI**. Cards, sliders, buttons, and in the end, components you design yourself.

The app is **yours**. You pick an idea in Step 0, build the example app, **Fridge Chef**, step by step, and then turn it into your idea in Step 7. By the end, no two apps in the room will look alike.

## What is A2UI?

Ask a chatbot for a recipe and you get a wall of text. To cook for four instead of two, you type again and read the wall again.

[A2UI](https://a2ui.org/) (Agent-to-UI) is an [open protocol](https://a2ui.org/specification/v1.0-a2ui/) that lets the AI answer with the **right interface** instead: a recipe card with a servings slider and a *Cook this* button. The agent **describes** the UI as data ("a Card with a heading, a slider and a button"), and your app **draws** it with its own native Flutter widgets.

```
 ┌──────────┐   A2UI messages    ┌──────────────────┐   Flutter widgets   ┌──────────┐
 │  Gemini  │ ─────────────────▶ │ MessageProcessor │ ──────────────────▶ │  Screen  │
 │ (agent)  │ ◀───────────────── │  (a2ui_flutter)  │ ◀────────────────── │  (user)  │
 └──────────┘      actions       └──────────────────┘     taps, typing    └──────────┘
```

A2UI makes three promises, and this workshop puts each one to the test:

* **Delightful:** the answer takes the shape it needs. A list one time, a form the next, a step-by-step guide after that.
* **Reliable:** the agent never sends code. It can only use the components in your **catalog**, and anything else is rejected before it's drawn.
* **Fast:** surfaces stream in while the AI is still writing them, and **A2UI Express**, a compact way of writing them, makes replies shorter.

## What you will learn

* **Part 1, Set up:** a Flutter app with the A2UI packages, chatting with Gemini in plain text.
* **Part 2, Speak A2UI:** write a surface by hand, so you know exactly what the AI will write later.
* **Part 3, Hand the AI the pen:** let Gemini write the UI, show it a photo, and send button presses back to it.
* **Part 4, Reliable and fast:** add a component of your own, then stream the UI and switch to Express.
* **Part 5, Make it yours:** turn Fridge Chef into your own idea: your persona, your look, your component.
* **Side quests:** functions your code controls, AI-painted pictures, and a 3D companion built with [Flutter Scene](https://pub.dev/packages/flutter_scene).

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

Work through them in order, and restart the app after every step. Each one ends with a working app and a small **Try this** experiment, and in Step 7 the app becomes yours.

* [Step 0: Pick Your Idea](steps/00-pick-your-idea.md)

**Part 1: Set Up**

* [Step 1: Set Up Your App](steps/01-set-up-your-app.md)

**Part 2: Speak A2UI**

* [Step 2: A Recipe Card, by Hand](steps/02-a-recipe-card-by-hand.md)

**Part 3: Hand the AI the Pen**

* [Step 3: Gemini Writes the UI](steps/03-gemini-writes-the-ui.md)
* [Step 4: Snap and Cook](steps/04-snap-and-cook.md)

**Part 4: Reliable and Fast**

* [Step 5: Your Own Component](steps/05-your-own-component.md)
* [Step 6: Fast](steps/06-fast.md)

**Part 5: Make It Yours**

* [Step 7: Make It Yours](steps/07-make-it-yours.md)

**Side Quests**

* [Side Quest A: Kitchen Tools](steps/side-quest-a-kitchen-tools.md)
* [Side Quest B: AI-Painted Dishes](steps/side-quest-b-ai-painted-dishes.md)
* [Side Quest C: A 3D Chef Companion](steps/side-quest-c-a-3d-chef-companion.md)

**Ready? [Start with Step 0: Pick Your Idea →](steps/00-pick-your-idea.md)**

---

## Show and Tell

You now have an app that nobody else has: your idea, your persona and your own component, with an AI that builds the right UI for every answer. Show it off!

## Going Further

* [a2ui.org](https://a2ui.org/): the A2UI protocol, with the [v1.0 specification](https://a2ui.org/specification/v1.0-a2ui/), the [basic catalog guide](https://a2ui.org/specification/v1.0-basic-catalog-implementation-guide/) and [actions](https://a2ui.org/concepts/actions/)
* [`a2ui_flutter`](https://pub.dev/packages/a2ui_flutter): Markdown in texts, interactive custom components, and the v0.9 protocol
* [`a2ui_agent`](https://pub.dev/packages/a2ui_agent): more on Express, trimming a catalog, and running the agent on a Dart server
* [The official A2UI example](https://github.com/a2ui-project/a2ui/tree/main/dart/a2ui_flutter/example): a full chat that also sends rendering errors back to the model, so it can fix its own UI
* [Flutter Scene docs](https://fscene.dev): 3D models, materials, lighting, physics and more
* [`dartantic_ai`](https://pub.dev/packages/dartantic_ai): other AI providers, typed outputs and more

> **Before you ship:** your API key is built into the app. That's fine for a workshop and for apps that only run on your own machine, but anyone who downloads a published app could dig the key out and use your quota. For a real app, call Gemini from your own server, or use [Firebase AI Logic](https://firebase.google.com/docs/ai-logic) with App Check, which proves requests come from your app.

> **Security note:** treat any agent outside your control as untrusted. A malicious agent could imitate a real interface to trick users. In this workshop the agent is your own app talking to Gemini, but keep it in mind before you render UI from someone else's agent.
