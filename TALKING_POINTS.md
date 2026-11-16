# Talking Points: Dream It, Render It

Presenter notes for the workshop. Each step has a **key message**, the points to **say**, what to **show**, the problems to **watch for**, and a line to **move on** to the next step.

Students follow the step pages themselves. Your job is to give each step a reason, show it working once, and keep the room together. Don't read the code aloud: the pages do that.

**Timings** add up to about 3 hours with a break. If you're short on time, cut Step 8 and the bonus steps first.

| Part | Steps | Time |
| ---- | ----- | ---- |
| Intro | | 10 min |
| Part 1: Set Up | 0 to 3 | 30 min |
| Part 2: Speak A2UI | 4 and 5 | 30 min |
| Break | | 10 min |
| Part 3: Hand the AI the Pen | 6 to 10 | 60 min |
| Part 4: Make It Truly Yours | 11 and 12 | 30 min |
| Bonus, Show and Tell, wrap-up | | 20 min |

---

## Before the Room Fills

* Run the finished app (`checkpoints/step_12` or `bonus_b`) on the projector, X-ray view ready.
* Test your own Gemini key on the venue Wi-Fi. If Step 3 works, everything works.
* Have the [Troubleshooting](TROUBLESHOOTING.md) page open in a tab. Most problems in the first half hour are entries 1 to 3.
* Write the repo link somewhere everyone can see it.

---

## Intro (10 min)

**Key message:** today the AI doesn't answer with text. It answers with real, native UI, and you decide what it's allowed to build.

**Open with the demo, not slides.** Type a feeling into Potion Lab ("I have an exam tomorrow"). A potion card appears, with a bottle. Press **Brew it!**: the dice roll, the card changes, the bottle drains. Then say:

> "No one wrote that card. Gemini described it, and Flutter drew it. By the end of today you'll have built this, except it'll be your idea, not mine."

**Say:**

* Chatbots answer with paragraphs. But a lot of answers are better as UI: a form, a checklist, a slider, a scorecard. That's **generative UI**.
* **A2UI** (Agent-to-UI) is an open protocol for it. The agent sends JSON that *describes* a UI: "a Card, with a heading, a slider and a button". Your app draws it with its own widgets.
* Point at the diagram in the README: Gemini → JSON → `MessageProcessor` → widgets → user taps → actions back to Gemini. That loop is the whole workshop.
* **Two reasons it's safe:**
  1. The agent never sends code. Only JSON, checked against a list.
  2. That list is your **catalog**. Gemini can only use components you put in it. Later today you'll add your own.
* Compare with the alternative: letting a model write and run Flutter code. A2UI is the opposite. The model fills in a form; your app keeps the pen.

**How today works:**

* Every step ends with a working app. If you fall behind, copy the step's checkpoint over your `lib/` folder. Your API key isn't in it, so it's safe.
* Every step ends with a **Make it yours** challenge. Do them: that's how 30 people end up with 30 different apps.
* We write A2UI **by hand first** (Steps 4 and 5), then let the AI write it. When Gemini starts writing JSON, you'll already read it fluently.

**Move on:** "Before any code: what's your app going to be?"

---

## Part 1: Set Up

### Step 0: Pick Your Idea (5 min)

**Key message:** one sentence now saves you an hour later.

**Say:**

* Fill in *"My app is a ___ that ___."* This sentence becomes your agent's personality in Step 7.
* The guide builds **Potion Lab** so you always have a working example. You don't have to build it.
* Good ideas have three things: a **character** (a voice), a **thing to show** (a card, a board, a scorecard) and a **thing to press** (feed, roll, answer, brew).
* Mixing two ideas from the table is often best: a quiz show hosted by a pirate.

**Show:** read two or three ideas from the room out loud. It gets everyone thinking.

**Move on:** "Keep your sentence. Now let's get a key."

### Step 1: Get Your Gemini API Key (5 min)

**Key message:** a free key from AI Studio, kept private.

**Say:**

* Open AI Studio, click **Create API key**, and leave the tab open. You paste it at the end of Step 2.
* The key is like a password for your quota. Don't post it, don't push it.

**Watch for:** school and work accounts with AI Studio turned off. Switch to a personal account ([Troubleshooting 3](TROUBLESHOOTING.md)).

**Move on:** "Leave that tab open. Let's make the app."

### Step 2: Create Your Project (10 min)

**Key message:** one `flutter create`, one `pub add`, one key file. No installs later.

**Say:**

* Walk through the package table. Three of them are A2UI, and each has one job:
  * `a2ui_core` reads the messages and holds the state of every surface.
  * `a2ui_flutter` draws surfaces as widgets.
  * `a2ui_agent` teaches Gemini A2UI and checks what it writes.
* `dartantic_ai` talks to Gemini. `image_picker` and `json_schema_builder` wait for Steps 8 and 11.
* The key goes in `lib/api_key.dart`, and that file goes in `.gitignore` right away.

**Watch for:** people who renamed the app in one line but not the other, and `flutter pub add` failing on an old Flutter. They need 3.38 or newer.

**Move on:** "Now we write the app itself, and get it talking to Gemini."

### Step 3: The App Shell (10 min)

**Key message:** a text chat with Gemini, split into a service and a page. We keep that split all day.

**Say:**

* `AgentService` holds **everything** about AI and A2UI. `HomePage` only shows things and passes on what the user does. Almost every later step only changes the service.
* `_history` is the conversation. Its first entry, the **system message**, tells Gemini how to behave. Keep an eye on it: it grows into your persona and the A2UI rules.
* The `MessageProcessor` is already here, and `HomePage` already listens to it for new surfaces. It just has nothing to draw yet.
* The blue *deprecated* hint on the Material import is fine. Don't switch to `material_ui`: A2UI's text fields crash under it.

**Show:** say hello, then change the system message to something silly ("answer only in haiku") and hot restart.

**Watch for:** the "Paste your Gemini API key" screen (restart, don't hot reload) and `API key not valid` ([Troubleshooting 1 and 2](TROUBLESHOOTING.md)). **Don't move on until every Step 3 works.** If Gemini answers here, it answers all day.

**Move on:** "Gemini can talk. Before we let it build UI, let's learn the language it'll build in."

---

## Part 2: Speak A2UI

### Step 4: Your First Surface, by Hand (15 min)

**Key message:** UI is just data. You describe it; `a2ui_flutter` draws it.

**Say:**

* A **surface** is one self-contained piece of UI, like one card in a chat. Each has its own id.
* Two messages build it:
  * `createSurface` makes an empty surface and names its **catalog**.
  * `updateComponents` fills it.
* Components come as a **flat list**, not a tree. The one with id `root` is the top, and parents point at children by id. Draw the tree from the page on the board.
* Why flat? Because an AI writes it one piece at a time. A flat list can be updated piece by piece, and later streamed (Step 12). A deeply nested tree can't.
* Texts take a little Markdown: `## ` makes a heading.

**Show:** the card appears under Gemini's text answer. Then break it live: point a child at an id that doesn't exist, or rename `root`. Let the room see what happens.

**Move on:** "That card can't do anything yet. Let's wire it up."

### Step 5: Data and Actions, by Hand (15 min)

**Key message:** components don't talk to each other. They share a **data model**, and buttons emit **actions** instead of running code.

**Say:**

* Every surface has a JSON **data model**. `updateDataModel` fills it.
* `{'@path': '/potion/name'}` is a **binding**. An input writes to that path; a text reads from it. `formatString` mixes several paths into one sentence.
* The text field and the preview have never heard of each other. They both point at `/potion/name`, and A2UI keeps them in sync.
* A Button has an **action**: a name and a `context` read from the data model. It doesn't run anything. It just says "brew was pressed, with these values".
* That's the safety story again. The agent can say *what* happened, never *what code to run*. Your app decides.
* Right now the action lands in a snack bar. In Step 9 it goes to Gemini.

**Show:** type in the name, drag the slider, watch the preview follow. Press **Brew it!** and read the snack bar.

**Move on:** "You can now write everything Gemini will write. Time to hand it the pen."

**Break here.**

---

## Part 3: Hand the AI the Pen

### Step 6: Gemini Writes the UI (15 min)

**Key message:** the same messages you just wrote by hand, now written by Gemini, and checked before they're drawn.

**Say:**

* How does Gemini know A2UI? `A2uiGenerator` writes a **prompt snippet**: the rules, plus every component in your catalog with its properties as JSON schema. It goes in the system message.
* Gemini answers with text, and A2UI messages inside `<a2ui-json>` tags.
* `StreamedAnswer` splits the reply: text goes to the page, each JSON block is **checked against your catalog** and only then handed to the processor. Bad UI is rejected, not drawn.
* The hand-written `_draw` is gone. `HomePage` barely changed: it already knew how to show surfaces.
* The **X-ray view** shows Gemini's raw reply. Leave it on for the rest of the day. It's the best way to understand what's happening.

**Show:** ask for "a sign-up form for a newsletter", then open X-ray side by side. Point out `createSurface`, `updateComponents` and `@path`: the same things the room wrote by hand an hour ago.

**Then ask the room:** "Ask it for a chess board. How does it get by with only the basic catalog?" It'll fake it with rows and texts. Plant the seed: "In Step 11 you'll give it a real one."

**Move on:** "It builds UI, but it's a generic assistant. Let's make it *your* app."

### Step 7: Give It a Personality (10 min)

**Key message:** with A2UI, the system message is a **design brief** as well as a voice.

**Say:**

* The persona goes *before* the A2UI rules in the system message.
* A normal persona sets tone. Here it also says exactly which surface to show, component by component: a Card, a heading, a List, a caption, a Button with action `brew`.
* That's why the app looks the same every time, even though there's no layout code. Consistency comes from being specific.
* Write the layout as a list. Vague briefs give random UI.
* Include **one button with an action name**. We need it in Step 9.

**Show:** three prompts in a row ("I have an exam tomorrow", "I'm hungry", "my cat ignores me"). Same layout, different content.

**Give this step extra time.** It's where students' ideas come alive. Walk the room and read personas.

**Move on:** "Your app can read. Now let's let it see."

### Step 8: Show It the World (10 min)

**Key message:** Gemini is multimodal. A photo is just another part of the same message.

**Say:**

* Text and photos now go through one `_generate` method. A photo is a `DataPart`: the bytes and their type, attached to a short instruction.
* The persona decides what a photo *means*. In Potion Lab it becomes the main ingredient. In a Fridge Chef it's the ingredients; in a Dungeon Master it's the next room.
* `maxWidth: 1024` keeps uploads small and fast.

**Show:** photo of something on the stage (a shoe, a coffee cup). Ask the room what potion they expect first.

**Watch for:** iOS and macOS need a permission entry. Chrome and Android need nothing.

**Cut first if short on time.** Nothing later depends on it.

**Move on:** "So far, UI only goes one way. Let's close the loop."

### Step 9: Close the Loop (15 min)

**Key message:** the action from Step 5 now goes back to Gemini, and Gemini **updates the surface it already made**. This turns a chat into an app.

**Say:**

* Remember the snack bar? `onAction` now calls `sendAction`, which sends the action to Gemini as the next user turn, in JSON.
* Next to the action goes the surface's **data model**, so Gemini knows what the user typed or picked. Gemini only gets it for surfaces with `"sendDataModel": true`, which the persona now asks for.
* The persona tells Gemini what the JSON means and how to answer: update the **same** surface with `updateComponents`, don't make a new one.
* Walk through the example message on the page: action name, `surfaceId`, `context`, and the data model under `metadata`.
* This is the complete A2UI loop from the README diagram: describe, act, send back, update.

**Show:** get a potion, press **Brew it!**, watch the card change in place. Then show the update in X-ray: same `surfaceId`, new component.

**Watch for:** Gemini making a new card instead of updating the old one. The fix is in the persona: say "the SAME surface" more firmly.

**Move on:** "One problem: Gemini decides everything, including things it shouldn't."

### Step 10: Rules the AI Can't Bend (15 min)

**Key message:** for the things that matter, your code decides and the AI tells the story around it.

**Say:**

* Ask a model to roll a die and it picks whatever number makes a good story. Ask it what's in stock and it invents things.
* **Function calling** fixes that. Each `Tool` has a name, a description, an input schema and `onCall`, your Dart code.
* Gemini *asks* for a function, `dartantic_ai` runs it, hands back the result, and Gemini carries on, all inside one `send`.
* Potion Lab has two:
  * `checkShelf` returns the real ingredients, so potions only use what's in stock.
  * `rollDice` rolls a real d20 when you brew. 1 is a disaster, 20 is a legend.
* The persona says *when* to call each one. The description says *what* it does.
* Every call is logged in X-ray, so you can prove the AI used it.

**Show:** brew a few times. In X-ray, point at `[function] rollDice(sides: 20) -> 17`, then at the card that says 17.

**Ask the room:** "What in your app should never be up to the AI?" Scores, health, the date and time, your own quiz questions, a timer.

**Move on:** "You control the rules. Now control the look: your own component."

---

## Part 4: Make It Truly Yours

### Step 11: Your Own Component (20 min)

**Key message:** add a widget to the catalog, and Gemini learns to use it from its schema alone.

**Say:**

* The basic catalog only goes so far. Remember the fake chess board in Step 6? This is the fix.
* A custom component is three things:
  1. A **schema**: its name and properties, each with a **description**. This is all Gemini ever sees.
  2. A **builder**: turns the properties into a Flutter widget. Any Flutter you like: `CustomPainter`, animations, anything.
  3. A **catalog** with its own id, registered next to the basic catalog.
* Potion Lab's `PotionBottle` is painted with a `CustomPainter`. Gemini picks its color, and `fill` is bound to the data model. When a brew sets `/fill` to 0, the liquid drains with an animation.
* Gemini never saw your Dart code. Good descriptions are the whole interface, so write them like you're explaining the widget to a new teammate.
* This is the catalog's safety story paying off: you widened what the AI can do, on your terms.

**Show:** a potion arrives in a bottle of its own color. Brew it and the bottle empties. Open X-ray to show Gemini setting the bottle's properties.

**Call this the most important challenge of the day.** Give it the most time in Part 4. Suggest starting from the bottle and changing the painter: a health bar, a mood meter, a dice face, a pet made of circles.

**Watch for:** the component not showing up. Usually it's missing from the catalog list, or the schema name and the persona name don't match.

**Move on:** "Last step, and the most fun to watch."

### Step 12: Stream the UI (10 min)

**Key message:** the UI builds itself on screen while Gemini is still writing it.

**Say:**

* Until now we waited for the full reply, then drew it. Now `sendStream` gives us chunks, and `StreamedAnswer` reads them one by one.
* Three changes:
  * `ValidationConfig.relaxed` lets a half-written surface show.
  * `progressiveKeys` fills `text` and `label` word by word.
  * `_generate` feeds each chunk as it arrives.
* This is why the component list is flat (Step 4): each component can be applied the moment it's complete.
* Function calls from Step 10 still work. They run between chunks.
* `HomePage` didn't change. The split from Step 3 pays off one last time.

**Show:** ask for a potion and watch the card grow top to bottom.

**Ask the room:** "What does your user see first?" The first component written appears first, so put the exciting part at the top of the persona's layout.

**Move on:** "That's the core workshop. If you have time, the bonus steps go further."

---

## Bonus Steps

### Bonus A: AI-Painted Illustrations

**Key message:** a builder can do anything a widget can, including calling another AI.

**Say:**

* `Illustration` takes a `prompt` that Gemini writes, and an image model paints it.
* A cache stops it repainting the same picture every time the surface rebuilds.
* One AI designs the UI and writes the brief for another AI that paints it.
* Pick an art style that fits your app and put it in the persona: pixel art, watercolor, movie poster.

**Watch for:** pictures use free quota fast. A broken image or a 429 usually means "wait a minute" ([Troubleshooting 4](TROUBLESHOOTING.md)).

### Bonus B: A 3D Companion with Flutter Scene

**Key message:** give the agent a body. A 3D creature is just another catalog component.

**Say:**

* Flutter Scene is a 3D engine for Flutter. The creature is built from spheres, so there are no 3D files.
* It's one parent `Node` with a body and eyes as children: move the parent, everything moves.
* `onTick` runs every frame and picks a bounce, spin and squash for the current `mood`.
* The companion lives in its own surface, pinned to the top. Gemini updates its mood through the data model on every answer.
* Chrome needs no setup. Other platforms need `--enable-flutter-gpu`, and the first build is slow while shaders compile.

**Show:** make the agent happy, then grumpy, then sleepy.

---

## Show and Tell (10 min)

* Ask three or four volunteers to show their app on the projector. Ask each one: "What's your idea, and what's the one component that makes it yours?"
* Point out how different the apps are, from the same 12 steps.

## Wrap-up (5 min)

**Recap the loop in one breath:** the agent describes UI as JSON, your catalog limits what it can use, the user acts, the action goes back, the agent updates the UI, and your code makes the rules that matter.

**Two things to remember before shipping:**

* **The API key is built into the app.** Fine for today. For a real app, call Gemini from your own server, or use Firebase AI Logic with App Check.
* **Treat other people's agents as untrusted.** A malicious agent could draw UI that imitates a real login screen. Today the agent is your own app; keep that in mind before rendering UI from an agent you don't control.

**Where to go next:** point at **Going Further** in the README: [a2ui.org](https://a2ui.org/), the `a2ui_flutter` and `a2ui_agent` docs, the official example that sends rendering errors back to the model, and the Flutter Scene docs.

**Last line:** "Delete your API key when you're done with it, and go build something nobody's seen before."
