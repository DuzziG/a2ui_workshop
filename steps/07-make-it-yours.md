[← Step 6: Fast](06-fast.md) &nbsp;·&nbsp; [Overview](../README.md) &nbsp;·&nbsp; [Side Quest A: Kitchen Tools →](side-quest-a-kitchen-tools.md)

*Part 5: Make It Yours · Step 7 of 7*

# Step 7: Make It Yours

> 🎯 **Goal:** turn Fridge Chef into an app of your own idea.

Everything an A2UI app needs is in place: the renderer, the loop, streaming, your own catalog. What makes Fridge Chef *Fridge Chef* is just three things: its **look**, its **persona** and its **component**. Pick your idea, swap those three, and you have a new app.

> **Using Git?** Commit Fridge Chef first, so you can always look back at a version that works.

### 1. Pick your idea

Decide what your app is, and write it down in one sentence: *"My app is a ___ that ___."*

Pick an idea where the answer is **more than words**: something to pick, tick, slide or press, and that changes as you use it. That's where A2UI shines. Need ideas?

| Idea | What the AI shows you |
| ---- | --------------------- |
| **Dungeon Master** | Rooms, monsters and choices for a text adventure, with your health and inventory |
| **Pet Simulator** | A virtual pet that gets hungry, bored and sleepy, with buttons to feed and play |
| **Quiz Show Host** | Quiz cards on any topic, with a score and a dramatic host |
| **Outfit Judge** | Show it a photo of your outfit, get a scorecard and a tip |
| **Plant Doctor** | Show it a sad plant, get a diagnosis and a care plan with checkboxes |
| **Travel Planner** | A day plan for any city, as a timeline you can reorder |
| **Workout Coach** | A workout that fits your time and mood, with sets to tick off |
| **Band Generator** | A band name, logo idea, setlist and tour poster |

> 🎨 **Tip:** a mix of two ideas is often the most fun. A quiz show hosted by a pirate? A plant doctor that is also a dungeon?

### 2. The look

* In `lib/main.dart`, change the app's name (it appears twice) and pick a `seedColor` that fits your idea.
* In `lib/home_page.dart`, change the prompt box's `hintText` and the *"Nothing here yet"* text.

### 3. The persona

The persona in `lib/agent_service.dart` is a design brief. Rewrite it from your sentence in section 1. Here's a template, with Fridge Chef's choices in brackets. Fill in the blanks, and delete what your app doesn't need:

```text
You are ___ [Chef Pip], a ___ [cheerful little chef] who ___ [hates wasting food].
The user ___ [tells you what is in their fridge]. You ___ [suggest one dish they can cook with it].
When you get a photo, ___ [use only what you can see in it].

Always answer with one short sentence in character, and exactly one new A2UI surface, a ___ [recipe] card:
- a Card whose first child is the ___ [dish's name] as a "## " heading
- ___ [one line on why this dish works]
- ___ [the ingredients as a List of Text]
- ___ [a Slider labeled "Servings", from 1 to 8, bound to /servings, which starts at 2]
- a "___" [Cook this] Button with an event action named "___" [cook], whose context holds ___ [the dish's name, and the servings]
Give every new surface a new surfaceId. Never answer with text only.

When the user presses a button, the next user turn is JSON: {"messages": [...]} with an action,
its name, the surfaceId of its surface, and its context.
Answer a "___" [cook] action with one sentence in character, and update the SAME surface, using its surfaceId again:
___ [replace what is inside the Card with the steps]. Do not create a new surface for it.
Put a ___ [CookingTimer] ___ [right after every step that needs waiting].
```

Some tips:

* **Describe the layout as a list**, component by component. The more specific you are, the more consistent your app looks.
* **Keep the two lines about actions as they are**: the one that explains the JSON, and *"update the SAME surface"*. They make the loop from Step 4 work.
* **Change the photo's meaning** in `sendPhoto` too: its text is the question that goes with every photo, such as *"Here is my outfit. Judge it."*

### 4. The component

Make the one widget that makes your app *yours*. Change the `CookingTimer` in `lib/my_catalog.dart` into it, or add a new component next to it in `components`. Some ideas:

* a **health bar** or **mood meter** that fills and changes color
* a **dice** face, a **card** from a deck, a **map** with a marker
* a **pet** drawn from circles that looks happy or sad
* a **trophy**, a **progress** path, a **rating** of stars

For each property, write a description that tells Gemini what it means and what values make sense: Gemini only sees your schema. Then ask for it in the persona (the line with `CookingTimer` in it). To level up, bind a property to the data model, or let your component emit an action: read about `props.writable` and `props.action` in the [a2ui_flutter docs](https://pub.dev/packages/a2ui_flutter#defining-custom-components).

### 5. Test it, and tune it

Restart the app, try your idea, and keep the X-ray open. When Gemini doesn't do what you meant, the fix is almost always in the persona:

| What you see | What to try |
| ------------ | ----------- |
| Your component never shows up | Name it exactly, in the persona's list, and say when to use it |
| Pressing a button makes a new card instead of updating the old one | Repeat "update the SAME surface, using its surfaceId again" |
| Gemini answers with text only | Keep "Never answer with text only." in the persona |
| *"Gemini wrote UI I could not draw"* | Read the message: it names the component and property that broke the rules. Make that property's description clearer. |

> 🧠 **What just happened:** you changed a few lines of text and one widget, and got a whole new app. The protocol, the renderer and the loop stayed the same. That's the point of A2UI: the agent decides what to show, and your app decides how it looks.

> 💾 **Using Git?** `git diff` shows everything this step changed. Save it with `git add -A && git commit -m "Step 7: Make It Yours"`.

---

[← Step 6: Fast](06-fast.md) &nbsp;·&nbsp; [Overview](../README.md) &nbsp;·&nbsp; [Side Quest A: Kitchen Tools →](side-quest-a-kitchen-tools.md)
