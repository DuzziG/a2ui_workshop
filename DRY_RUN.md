# Dry Run Checklist

For instructors: run the whole workshop once, the way a student would, before you teach it. It takes about two hours. Tick every box. When something doesn't match, note it in the [results](#results) and keep going: copy the checkpoint for that step over your `lib/` to catch up.

**When something differs, keep three things:**

1. the text reply under the cards
2. the X-ray contents (the copy button at the top right of the X-ray)
3. the first line of any red error screen, or of the error in the terminal where `flutter run` runs

---

## Before you start

- [ ] Start from a **fresh** project, made in [Step 1](steps/01-set-up-your-app.md), not one from an earlier run.
- [ ] Run in **Chrome**: `flutter run -d chrome`.
- [ ] Turn on **Git** in Step 1 (the optional part), and commit after every step. `git diff` then shows exactly what each step changed, which makes any difference easy to point at.
- [ ] After every step, **restart** with `R` in the terminal, not a hot reload.
- [ ] From Step 3 on, keep the **X-ray** open (the `</>` button). With a wide window, the chat and the X-ray sit side by side.

---

## Step 1: Set Up Your App

[Step page](steps/01-set-up-your-app.md)

- [ ] Before you paste the key, the app shows *"Paste your Gemini API key into lib/api_key.dart…"*.
- [ ] After you paste the key and restart, the prompt box shows.
- [ ] `git status` doesn't list `lib/api_key.dart`.
- [ ] Ask *"What can I cook with eggs, spinach and feta?"*. A text answer appears in the grey box at the bottom, and you can scroll it if it's long.
- [ ] No `Error:` in the reply. If there is one, check [Troubleshooting](TROUBLESHOOTING.md) entries 2, 4 and 5.

## Step 2: A Recipe Card, by Hand

[Step page](steps/02-a-recipe-card-by-hand.md)

- [ ] Send anything. Gemini's text appears, and a card titled **Tonight's dinner**, with a star icon.
- [ ] The card shows *"You asked: …"* with your message.
- [ ] Type a new dish into **Dish**: *"Cooking … for 2."* follows as you type.
- [ ] Drag **Servings**: the number in the sentence follows.
- [ ] Press **Cook this**: a snack bar shows `Action "cook" with {recipe: …, servings: …}`.
- [ ] Each message adds a new card.

## Step 3: Gemini Writes the UI

[Step page](steps/03-gemini-writes-the-ui.md)

- [ ] Ask *"What can I cook with eggs, spinach and feta?"* again. You get **one recipe card**, with:
  - [ ] the dish's name as a heading
  - [ ] a line on why it works
  - [ ] time and difficulty, in small text
  - [ ] the ingredients, for 2 servings
  - [ ] a **Servings** slider, starting at 2
  - [ ] a **Cook this** button
- [ ] A short, friendly sentence from Chef Pip in the grey box.
- [ ] The X-ray shows the reply, with an indented `<a2ui-json>` block.
- [ ] The copy button copies it.
- [ ] Narrow the window below 800 px wide: the X-ray takes the whole screen until you press `</>` again.
- [ ] Try *"Something sweet with bananas"* and *"Dinner for a rainy day"*. Each gives a new card in the same layout.
- [ ] Press **Cook this**: still only the snack bar, as in Step 2.
- [ ] No *"Gemini wrote UI I could not draw"* in any reply.

## Step 4: Snap and Cook

[Step page](steps/04-snap-and-cook.md)

- [ ] The camera button opens a file picker.
- [ ] Pick a photo of a fridge: the card uses what's in the photo.
- [ ] Pick a photo that isn't food (shoes, a cat): note what Chef Pip does.
- [ ] Set **Servings** to 4 and press **Cook this**:
  - [ ] the **same card** changes into the steps (no new card appears)
  - [ ] the amounts are scaled to 4
  - [ ] the steps are numbered
  - [ ] the X-ray shows new components for the same `surfaceId`, and no `createSurface`
- [ ] Do it again with Servings on 1 and on 8.
- [ ] No *"Surface … already exists"* ([Troubleshooting 7](TROUBLESHOOTING.md#7-gemini-wrote-ui-i-could-not-draw-surface--already-exists)). If it happens, how often? Note it, for example *2 of 5*.

## Step 5: Your Own Component

[Step page](steps/05-your-own-component.md)

- [ ] Ask for a dish that needs waiting, such as pasta or a cake, and press **Cook this**. A **timer** appears after the steps that need waiting, with a label and a sensible number of minutes.
- [ ] Press play: it counts down. Pause and reset work.
- [ ] Set a short timer to see the end (or ask for *"a 1 minute egg timer"*): the ring turns green and shows **Done!**.
- [ ] The X-ray shows a `CookingTimer` component with `minutes` and `label`.
- [ ] Ask *"Show the recipe as a chess board"*. Either Gemini makes do with basic components, or the reply says *"Gemini wrote UI I could not draw"*. Note which one, and the app must not crash.

## Step 6: Fast

[Step page](steps/06-fast.md)

1. After sub-step 2 (streaming, still JSON):
   - [ ] Ask *"What can I cook with eggs, spinach and feta?"*: the card grows on screen while Gemini writes it.
   - [ ] The X-ray starts with `[N characters in S s]`. Note N and S in the [results](#results).
   - [ ] **Cook this** still updates the same card.
2. After sub-step 3 (Express) and a restart:
   - [ ] Ask the same question: the card still grows while it streams, and texts fill in word by word.
   - [ ] The X-ray shows `<a2ui>` with lines like `root = Card(...)`, not JSON.
   - [ ] Note N and S again. N should be clearly smaller.
   - [ ] **Cook this** updates the same card, and the timers still appear.

## Step 7: Make It Yours

[Step page](steps/07-make-it-yours.md)

- [ ] Pick an idea from the table, and change the look, the persona (from the template) and the component, as the page says.
- [ ] Note how long it took, and which instructions were unclear.
- [ ] Your component shows up, and its button updates the same surface.
- [ ] Try one row of the "Test it, and tune it" table on purpose: does the fix work?

---

## Side Quests

Each side quest starts from Step 6. To test them the way the checkpoints are built, copy `checkpoints/step_06/lib` over your `lib/` first, then follow the side quest.

### Side Quest A: Kitchen Tools

[Step page](steps/side-quest-a-kitchen-tools.md)

- [ ] Ask for a dish. The X-ray starts with `[function] checkPantry() -> [salt, pepper, …]`.
- [ ] The dish may use pantry staples that you didn't mention.
- [ ] Press **Cook this**: an **Add to shopping list** button appears below the steps.
- [ ] Press it. The X-ray shows `[function] addToShoppingList(items: […]) -> […]`, and the card shows the list as checkboxes.
- [ ] Ask for a second dish, and add to the list again: the list keeps the first items too.

### Side Quest B: AI-Painted Dishes

[Step page](steps/side-quest-b-ai-painted-dishes.md)

- [ ] Ask for a dish: a picture of it appears under the heading. A spinner shows while it paints, and a broken-image icon if painting fails.
- [ ] Press **Cook this**, or drag the slider: the picture doesn't paint again (it's cached).
- [ ] Note how long a picture takes, and whether you hit a quota error ([Troubleshooting 4](TROUBLESHOOTING.md#4-error-apiexception429-or-a-message-about-quota-or-resource_exhausted)).

### Side Quest C: A 3D Chef Companion

[Step page](steps/side-quest-c-a-3d-chef-companion.md)

- [ ] `flutter pub add flutter_scene vector_math` works. The first build takes longer, because the shaders compile.
- [ ] After the first answer, the companion is **pinned at the top**, and isn't repeated in the feed.
- [ ] It changes mood: ask for something delicious (*excited*), then something awful (*grumpy*).
- [ ] The X-ray shows the `companion` surface getting a new `/mood` on every answer (in Express: `surface("companion")`, then `$/mood = "…"`).

---

## Results

| Step | ✅ / ❌ | Notes |
| ---- | ------ | ----- |
| 1. Set Up Your App | | |
| 2. A Recipe Card, by Hand | | |
| 3. Gemini Writes the UI | | |
| 4. Snap and Cook | | |
| 5. Your Own Component | | |
| 6. Fast | | |
| 7. Make It Yours | | |
| Side Quest A | | |
| Side Quest B | | |
| Side Quest C | | |

**Step 6 numbers** (same question, after a restart):

| Format | Characters | Seconds |
| ------ | ---------- | ------- |
| JSON | | |
| Express | | |

Found something new? Add it to [Troubleshooting](TROUBLESHOOTING.md), under **Found While Testing**.
