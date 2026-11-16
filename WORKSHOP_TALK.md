# The Workshop Talk: Dream It, Render It

The full talk for the workshop, written for people who are new to coding. You can read it word for word or put it in your own words.

**How to read this page**

* Text in a quote block is **what you say**.
* **Do:** is what you do on screen.
* **In plain words:** explains one idea simply, often with an everyday comparison.
* **Check the room:** is a question to make sure nobody is lost.
* **If someone is stuck:** lists the usual problems and fixes.
* **Move on:** is the line that leads into the next part.

Students follow the step pages and copy the code from them. You don't need to read code aloud. Your job is to explain **why**, show it working once, and keep everyone together.

**Timing:** about 3.5 hours with a break. If time runs short, shorten Step 6 and skip the side quests.

| Part | Time |
| ---- | ---- |
| Opening | 20 min |
| Step 0 and Step 1: idea and set-up | 30 min |
| Step 2: a card by hand | 25 min |
| Break | 10 min |
| Step 3 and Step 4: the AI takes over | 40 min |
| Step 5 and Step 6: reliable and fast | 35 min |
| Step 7: make it yours | 25 min |
| Show and tell, and closing | 25 min |

---

## Before You Start

### Get Ready

* Have the finished Fridge Chef (`checkpoints/step_06`) running in Chrome, with the X-ray view ready.
* Test your Gemini key on the venue Wi-Fi.
* Keep a photo of a fridge on your laptop for the demo.
* Write the repository link where everyone can see it.
* Open [Troubleshooting](TROUBLESHOOTING.md) in a tab. Most early problems are entries 1 to 3.

---

## Opening

### Welcome (2 min)

> Welcome! Today you're going to build an app with AI inside it. You don't need to be a programmer. You'll copy code from the guide, and I'll explain what every piece does in plain words. By the end, you'll have an app that's yours, and you'll understand how it works.

> If you get lost at any point, that's normal. Raise your hand, or copy the "checkpoint" for that step. We'll show you how. Nobody gets left behind.

### The Problem: a Wall of Text (3 min)

**Do:** open any AI chat and ask *"What can I cook with eggs, spinach and feta?"*

> Here's what AI chat usually looks like. I asked for a recipe, and I got a wall of text. It's correct, but look at it. The amounts are for two people. If I'm cooking for four, I have to ask again and read everything again. There's nothing to tap and nothing to tick.

> Now look at the apps on your phone. They don't answer with paragraphs. They have buttons, sliders, checklists and cards. So why does AI still talk to us like a letter?

### The Idea: the AI Answers with an App (5 min)

**Do:** in Fridge Chef, ask the same question. A recipe card appears with a servings slider and a **Cook this** button. Move the slider. Press the button. The card turns into steps with timers.

> Same question, same AI. But this time, the answer is a little piece of an app. There's a slider for the servings. There's a button. When I press it, the card turns into step-by-step instructions, with timers.

> Nobody designed this card in advance. The AI decided what this answer needed, and the app drew it. That's called **generative UI**. "UI" means user interface: everything you see and touch on a screen.

> Today you'll build this app, step by step. Then you'll turn it into your own idea.

### What Is A2UI? (5 min)

> To make this work, the AI and the app need a shared language. That language is called **A2UI**, short for "Agent to UI". It's free and open, so anyone can use it.

**In plain words:** A2UI is like **ordering from a menu at a restaurant**.

* The AI is the **customer**. It reads the menu and orders: "one card, with a heading, a slider and a button."
* The app is the **kitchen**. It only cooks what's on its menu, and it cooks it its own way.
* The **menu** is called the **catalog**. You decide what's on it.

> The AI never goes into the kitchen. It can't cook anything itself. It can only order from your menu. That's why this is safe: the AI never sends code that runs on your phone, only an order.

**Do:** show the diagram from the README.

```
 Gemini ── "draw this card" ──▶ your app ──▶ the screen
 Gemini ◀── "user pressed Cook" ── your app ◀── the user's tap
```

> It's a loop. The AI describes the screen, your app draws it, the user taps something, and the tap goes back to the AI. The AI then changes the screen. That loop is the whole workshop.

### How Is This Different from Regular App Development? (3 min)

> In a normal app, a developer designs every screen ahead of time. If the app needs a new screen, someone has to build it, test it and release an update.

> In an A2UI app, you build the **pieces**, like the building blocks of a Lego set. The AI decides how to put them together for each person and each question, while the app is running.

| | Regular app | A2UI app |
| -- | -- | -- |
| Who decides the screen? | The developer, in advance | The AI, for each answer |
| A new kind of answer needs... | A new screen and an app update | Usually nothing: the AI combines the pieces you have |
| What the developer builds | Every screen | The pieces (the catalog) and the rules |
| How it looks | Your design | Still your design: the AI uses your pieces |

### Why It's Worth It (2 min)

> The people who made A2UI promise three things, and we'll test each one today.

* **Delightful:** the answer takes the shape it needs. A list one time, a form the next, a timer after that.
* **Reliable:** the AI can only use the pieces you allow. Anything else is rejected before it reaches the screen.
* **Fast:** the screen builds itself while the AI is still writing, and a short way of writing it makes replies quicker.

> And one more benefit for you: it's a quick way to build something useful. Change a few lines of text, and you have a different app.

### Today's Plan (1 min)

> Here's how today goes. First, set-up: we create the app and connect it to the AI. Then we write one card by hand, so you learn the language. Then the AI takes over the writing. Then we make it reliable and fast. And at the end, you turn it into your own app.

> Every step ends with an app that works. If you fall behind, each step has a **checkpoint**: a copy of the finished code you can paste over yours.

---

## Part 1: Set Up

### Step 0: Pick Your Idea (5 min)

> Before any code, think about what your app could be. Write one sentence: "My app is a ___ that ___." For example: "My app is a plant doctor that tells me what's wrong with my plant."

> We'll all build the same example first: **Fridge Chef**. You tell it, or show it, what's in your fridge, and Chef Pip suggests a dish. Building the same app means you can always compare your work with the guide. In Step 7, you swap in your own idea.

> A good idea is one where the answer is **more than words**: something to tap, tick, slide or press. Look at the table on the page for ideas. Mixing two is often the most fun: a quiz show hosted by a pirate?

**Check the room:** ask two or three people to read their sentence out loud.

**Move on:** "Keep your sentence somewhere. Now let's build."

### Step 1: Set Up Your App (25 min)

**Key message:** an app with a text box that chats with the AI, in plain text for now.

#### Part A: The API Key

> First, our app needs permission to talk to Gemini, Google's AI. That permission is an **API key**.

**In plain words:** an **API key** is like a **library card**. It proves who you are, and it's linked to your free allowance of AI requests. Anyone with your card can use your allowance, so keep it private.

> Go to Google AI Studio, click Create API key, and leave that tab open. We'll copy the key in a minute.

#### Part B: Create the Project

> Now we create the app. We're using **Flutter**, a free tool from Google for making apps for phones, computers and the web from one set of code.

**In plain words:**

* `flutter create` makes a new, empty app: like getting a new notebook.
* `flutter pub add` downloads **packages**: ready-made code other people wrote, so we don't start from zero. Like adding apps to your phone.
* We add them all now, so we don't stop for installs later.

> Then paste your key into a new file called `api_key.dart`. The next command tells Git to ignore that file, so your key never ends up online by accident.

**If someone is stuck:** school or work accounts sometimes block AI Studio, so use a personal Google account. If `flutter pub add` fails, Flutter may be too old: run `flutter upgrade`.

#### Part C: The App Shell

> Now we write our first three files. Don't worry about every line. Here's what each one does.

* `agent_service.dart` is the **brain**. It talks to the AI.
* `home_page.dart` is the **face**. It shows things on screen and passes on what you type.
* `main.dart` is the **front door**. It starts the app.

> We keep the brain and the face apart all day. That way, most later steps only change the brain.

**In plain words:**

* A **prompt** is what you type to the AI.
* The **system message** is a hidden note to the AI, before the conversation starts, telling it how to behave. Like a briefing for a new employee. Ours says "You are a friendly, helpful assistant." Later it becomes your app's personality.
* The **history** is the conversation so far. The AI has no memory of its own, so we send it the whole conversation every time.

**Do:** run `flutter run -d chrome`, then ask *"What can I cook with eggs, spinach and feta?"*

> We got a wall of text, just like a normal chatbot. **Remember this question.** In Step 3 you'll ask it again and see the difference.

**In plain words:** **hot restart**. While the app runs, pressing `R` in the terminal restarts it with your new code. Do this after every step. If something looks strange, restart first.

**Check the room:** "Hands up if Gemini answered you." **Don't move on until everyone's app answers.** If it works now, it'll work all day.

**If someone is stuck:** "Paste your Gemini API key" on screen means the key wasn't saved, or the app needs a full restart. "API key not valid" means the key was copied wrong: copy it again. See Troubleshooting 1 and 2.

**Move on:** "The AI can talk. Before it builds screens, let's learn the language it builds them in, by writing one ourselves."

---

## Part 2: Speak A2UI

### Step 2: A Recipe Card, by Hand (25 min)

**Key message:** a screen can be described as a list of pieces. You write the description, and the app draws it.

> In this step, we play the AI. We write the order ourselves, by hand. Then, when the AI does it in Step 3, you'll recognize every line.

#### Surfaces and Components

**In plain words:**

* A **surface** is one card in the chat: one self-contained piece of screen. Each has its own name, its **id**.
* A **component** is one piece inside it: a text, a slider, a button. These are the dishes on the menu.
* We describe all of this in **JSON**: a simple way to write data with labels, like a filled-in form. `"name": "omelette"` means "the name is omelette".

> We build a card with three **messages**, like three instructions:
> 1. **"Create a new card."** That's `createSurface`.
> 2. **"Here's some information for it."** That's `updateDataModel`.
> 3. **"Here are its pieces."** That's `updateComponents`.

**Do:** show the tree drawing on the page.

> The pieces come as a **flat list**, not nested inside each other. The piece called `root` is the top. Every piece says which pieces are inside it, by name. It's like a seating plan: "the Card holds the Column, the Column holds the title, the slider and the button".

> Why a flat list? Because it's easy for an AI to write one piece at a time, and to change just one piece later. You'll see that pay off.

#### Data and Bindings

**In plain words:** the **data model** is the card's **notepad**. It's where the card keeps its information: the dish's name, the number of servings.

> A **binding** connects a piece to a line on the notepad. The slider is bound to "servings". When you move the slider, it writes the new number on the notepad. The text underneath reads from the same line, so it changes too.

> The slider and the text don't know about each other. They just share the notepad.

#### Actions

**In plain words:** an **action** is a **doorbell**. Pressing the button doesn't run any code by itself. It rings the bell and says "someone pressed Cook, with these values." Whoever is listening decides what happens.

> Right now, our app just shows a little message at the bottom when the bell rings. In Step 4, the bell will ring at the AI's door.

**Do:** restart. Send anything. The card appears. Type a dish name and move the slider: the text follows. Press **Cook this**: the message shows the values.

> Notice: we didn't design a single button. We **described** a card, and the A2UI package drew it with real Flutter parts.

**Check the room:** "Move your slider. Does the text below it change? Press Cook. Do you see the message?"

**Try this together:** rename `root` to something else, restart, and see what happens. Then put it back. Breaking things on purpose is a great way to learn.

**Move on:** "You can now write everything the AI will write. Let's take a break, and then hand the AI the pen."

---

## Break (10 min)

---

## Part 3: Hand the AI the Pen

### Step 3: Gemini Writes the UI (20 min)

**Key message:** the AI now writes the same messages you wrote by hand, and a personality tells it what to build.

> In Step 2, we wrote the card ourselves. Now we delete that and let Gemini write it. But how does Gemini know the A2UI language?

**In plain words:** the A2UI package gives Gemini two things.

1. **A rulebook.** Before the chat starts, it adds the A2UI rules and the whole menu (the catalog) to the system message. Now Gemini knows the language and what it's allowed to order.
2. **An inspector.** When Gemini replies, the package checks every order against the menu before anything reaches the screen. Anything not on the menu is rejected.

#### The Persona

> We also give the AI a **persona**: a character and a job description.

**In plain words:** the **persona** is a **design brief**, like what you'd give a designer. Ours says: you're Chef Pip, a cheerful chef who hates wasting food. Always answer with a recipe card. The card has a heading, a line about why the dish works, the ingredients, a servings slider and a Cook button.

> Because the brief is so specific, every card looks the same, even though nobody designed it in advance. The more specific you are, the more consistent your app looks.

#### The X-ray View

> We also add an **X-ray** button. It shows exactly what Gemini wrote behind the scenes. Keep it open all day. It's the best way to understand what's going on.

**Do:** restart, and ask the question from Step 1 again. A recipe card appears. Open the X-ray side by side.

> Same question, same AI, as in Step 1. But this time we got a card with a slider and a button, instead of a wall of text.

> Look at the X-ray. Do you recognize it? `createSurface`, `updateComponents`, a slider bound to servings. It's the same thing you wrote by hand. Gemini learned it from the rulebook.

**Check the room:** "Ask for something different: 'Something sweet with bananas'. Do you get a card every time?"

**Try this together:** change one line of the persona, for example give Chef Pip a strong opinion about pineapple. Restart and ask again. The AI follows your brief.

**Move on:** "Right now, it's still a one-way street. Let's make the button talk back."

### Step 4: Snap and Cook (20 min)

**Key message:** the AI can see photos, and the buttons on its cards now talk back to it. That turns a chat into an app.

#### Photos

**In plain words:** Gemini is **multimodal**: it understands pictures as well as words. A photo can travel in the same message as a question, like a text message with a picture attached.

> Instead of typing what's in your fridge, you can just show it.

#### Closing the Loop

> Remember the doorbell from Step 2? Until now, it only showed a little message. Now it rings at Gemini's door.

> When you press **Cook this**, the app sends Gemini a short note: "the Cook button was pressed, on this card, with 4 servings." Gemini answers by **changing the card it already made**: it turns it into step-by-step instructions, with the amounts for 4 people.

**In plain words:** this is the full A2UI loop.

1. The AI describes a screen.
2. You tap something.
3. The tap goes back to the AI.
4. The AI updates the screen.

> And notice: Gemini never had to ask "how many people are eating?" The slider already wrote it on the card's notepad, and the button took it along.

**Do:** send a photo of a fridge. Move the slider to 4. Press **Cook this**. The card changes in place. Show the update in the X-ray.

**Check the room:** "Press Cook with the slider on 1, then ask again and press it on 8. Do the amounts change?"

**If someone is stuck:** Gemini makes a new card instead of changing the old one: the persona must say "update the SAME surface". On iPhone or Mac, photos need a permission setting: Chrome is easiest.

**Try this together:** send a photo that isn't food, like your shoes. What does Chef Pip do?

**Move on:** "It works, and it's fun. But can we trust it? And can it be faster?"

---

## Part 4: Reliable and Fast

### Step 5: Your Own Component (20 min)

**Key message:** you can add your own piece to the menu, and the AI learns to use it from a short description.

> The basic menu has text, sliders, buttons and lists. But it has no cooking timer. So let's add one: a piece that only exists in our app.

**In plain words:** a new menu item needs three things.

1. **A description** for the AI, called a **schema**. It says what the piece is called and what the AI can set: "CookingTimer: minutes, and a label." This is the only part the AI ever sees.
2. **The recipe** for the app, called a **builder**. It's the Flutter code that draws the timer: the ring, the countdown, the start and pause buttons.
3. **Your own menu**, called a **catalog**, which sits next to the basic one.

> Gemini only decides two things: how many minutes, and the label. Everything else, like the ticking, the buttons and the colors, is our code. The AI decides **what** to show; we decide **how it looks and behaves**.

**Do:** restart, ask for a dish, press **Cook this**. Timers appear after every step that needs waiting. Start one.

#### Let's Try to Break It

**Do:** ask *"Show the recipe as a chess board"* or *"Add a video of it"*.

> There's no chess board or video on our menu. So Gemini either makes do with what it has, or it orders something that doesn't exist, and the app says it couldn't draw it. Either way, nothing outside our menu reaches the screen.

> That's the **reliable** promise. You stay in control of what can appear in your app.

**Try this together:** change the description of `minutes` to "always 1". Restart. Gemini follows your description, even though it's silly. That shows how much the description matters. Put it back afterwards.

**Move on:** "It's reliable. Now let's make it fast."

### Step 6: Fast (15 min)

**Key message:** the card builds itself while the AI is still writing, and a shorter way of writing makes it quicker.

> Right now we wait for Gemini to finish its whole answer, and then everything appears at once. Two changes fix that.

**In plain words:**

* **Streaming:** instead of waiting for the whole answer, we show each piece as it arrives. Like watching someone type, instead of waiting for the full letter. This is why the flat list from Step 2 matters: each piece can be drawn as soon as it's complete.
* **A2UI Express:** a shorter way for the AI to write the same card. Like writing in shorthand. The package translates it back, so the rest of the app doesn't change at all.

> Fewer words to write means a faster answer, and a cheaper one: AI services charge by how much the AI reads and writes.

**Do:** after the streaming change, ask for a dish and watch the card grow. Note the numbers at the top of the X-ray, like "2154 characters in 6.3 s". Then switch to Express, restart, ask again, and compare.

> Same card, far fewer characters. The rulebook gets smaller too: about 25,000 characters instead of 45,000, and the AI reads it on every turn.

**Try this together:** the first piece written appears first. Move the heading to the end of the persona's list, and watch the card build in a different order.

**Move on:** "You now have a complete A2UI app. Time to make it yours."

---

## Part 5: Make It Yours

### Step 7: Make It Yours (25 min)

**Key message:** change three things, the look, the persona and the component, and you have a brand-new app.

> Everything an A2UI app needs is already working: the loop, the photos, the menu, the streaming. What makes Fridge Chef *Fridge Chef* is only three things.

1. **The look:** the name and the colors.
2. **The persona:** the character and the design brief.
3. **The component:** your one special piece.

> Swap those, and it's a different app. Get out your sentence from Step 0.

**Do:** walk through the persona template on the page. Fill in the blanks for a quick example idea, live.

**Tips to share:**

* **Describe the card as a list**, piece by piece. Vague briefs give random screens.
* **Keep the two lines about button presses.** They make the loop work.
* **Change what a photo means**: in an outfit judge, the photo is the outfit.
* **Your component:** start from the timer and change it. A health bar, a mood meter, a dice face, a star rating.
* **Write good descriptions.** The AI only knows what your description tells it.

> When the AI doesn't do what you meant, the fix is almost always in the persona. Keep the X-ray open, and read the table on the page.

**Do:** walk around the room. Read personas. Help people make them more specific.

> Notice what you changed: a few lines of text and one piece. Everything else stayed the same. That's the point of A2UI: the AI decides what to show, and your app decides how it looks.

---

## Side Quests

For people who finish early. They don't depend on each other, so pick any.

### Side Quest A: Kitchen Tools

> Ask an AI what's in your cupboard and it'll guess. Ask it to keep a shopping list and it'll forget it. **Function calling** fixes that.

**In plain words:** you give the AI **tools**: little functions in your code it can call when it needs a real answer. Like a chef who can't see your cupboard, so they **ask you** to check, and must use your answer.

* `checkPantry` tells Gemini the basics you always have.
* `addToShoppingList` adds to a list that your app keeps, so it never forgets.

> The truth lives in your code. The AI builds the screen around it. Use this for anything that must be right: scores, dates, prices, a dice roll.

### Side Quest B: AI-Painted Dishes

> A piece on your menu can do anything, even ask **another** AI for help. The `Illustration` piece takes a description that Gemini writes, and an image AI paints it.

> Pictures use your free allowance faster, so if one doesn't appear, wait a minute.

### Side Quest C: A 3D Chef Companion

> Give your AI a body: a little 3D creature made of spheres that sits at the top of the screen. Gemini sets its **mood**, and the creature acts it out: bouncing when it's happy, drooping when it's sad.

> It's just another piece on the menu. Same idea as the timer, with a 3D engine called Flutter Scene doing the drawing.

---

## Making It Useful

### Where This Is Useful in Real Life (5 min)

> You built a fun app today. But this same idea is useful in many real products. Anywhere the right screen depends on the person and the question.

* **Customer support:** instead of a long reply, show a form to fill in, or a button to rebook.
* **Shopping:** compare products in a table, with buttons to pick one.
* **Learning:** a quiz card for any topic, with a score.
* **Health and fitness:** a workout plan with sets to tick off, or a medicine schedule with reminders.
* **Travel:** a day plan as a timeline, with a map.
* **Work tools:** ask "show me this week's sales" and get a chart, not a paragraph.
* **Accessibility:** the same answer, in bigger pieces or simpler layouts for people who need them.

### How to Grow It from Here (5 min)

> If you want to keep going after today, here's the path.

1. **Add more pieces to your menu.** Each new component makes your app able to show more. That's where most of the value is.
2. **Connect real information with tools** (Side Quest A). Weather, your calendar, a product list, a database. The AI is only as good as the facts you give it.
3. **Remember things between visits.** Save the shopping list, the score, the user's favorites.
4. **Make pieces interactive.** Let your component ring its own doorbell: a rating that sends the stars back to the AI.
5. **Read the A2UI docs** at a2ui.org. The links are at the bottom of the README.

### Before You Share Your App (3 min)

> Two important things before you publish anything.

* **Your key is inside your app.** That's fine today, on your own computer. But if you publish the app, someone could dig the key out and use your allowance. For a real app, the AI calls should go through your own server, or through a service like Firebase AI Logic.
* **Only trust AIs you control.** A2UI can draw anything on the menu. A bad AI could draw something that looks like a real login screen to trick people. Today the AI is yours, so it's fine. Be careful before you draw screens from someone else's AI.

> And remember: the AI can still be wrong. It might get an amount wrong or misread a photo. The menu keeps the screen safe, and tools keep the important facts right, but always test your app with real people.

---

## Closing

### Show and Tell (15 min)

> Who wants to show their app? Tell us your sentence from Step 0, and show us your special piece.

**Do:** invite three or four people to the projector. Point out how different the apps are, from the same steps.

### Wrap-up (5 min)

> Let's recap the whole day in one breath. The AI describes a screen. Your app draws it with pieces from your menu. The user taps. The tap goes back to the AI. The AI updates the screen. And your code makes the rules that matter.

> You started with a chatbot that answered with a wall of text. You're leaving with an app that answers with the right screen for every question. And you only had to change a few lines of text to make it yours.

> One last thing: delete your API key when you're done, or keep it private. Thank you, and go build something nobody has seen before!

---

## Questions You Might Get

**"Is the AI writing code?"**
> No. It only writes a description, like an order from a menu. Your app does all the drawing, with code you wrote.

**"Why not just use ChatGPT or Gemini directly?"**
> Those answer with text. Here, the answer is a working piece of an app, with sliders and buttons, in your design.

**"Do I need to know how to code to do this?"**
> Not for today. To build your own pieces from scratch you'll learn some Flutter, but you can get very far by changing the persona and adjusting the examples.

**"Does this cost money?"**
> The Gemini key has a free allowance, which is plenty for today. A real app with many users would pay per use.

**"What if the AI makes a mistake?"**
> It can. If it orders something that isn't on the menu, it's rejected before reaching the screen. For facts that must be right, use tools (Side Quest A), so your code decides.

**"Does it work on phones?"**
> Yes. Flutter apps run on Android, iPhone, the web and computers. We used Chrome today because it needs no extra set-up.

**"Can I use another AI instead of Gemini?"**
> Yes. A2UI is an open standard, and the package we use for talking to Gemini supports other AI providers too.
