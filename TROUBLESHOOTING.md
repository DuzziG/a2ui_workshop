# Troubleshooting

Each entry gives the step, what you see, why it happens and how to fix it.

* **Problems you may hit** were prepared ahead of time, so you're ready before anyone runs into them.
* **Found while testing** logs real problems from test runs. Found a new one? Add it there.

---

# Problems You May Hit

## 1. The app only says "Paste your Gemini API key into lib/api_key.dart"

**Step:** [1, Set Up Your App](steps/01-set-up-your-app.md)

**Why:** `geminiApiKey` in `lib/api_key.dart` is still the placeholder, or is empty.

**Fix:** paste your key from [Google AI Studio](https://aistudio.google.com/apikey) between the quotes, then **restart** the app. A hot reload isn't enough, because the key is a constant that's read when the app starts.

## 2. `Error: ApiException(400): API key not valid. Please pass a valid API key.`

**Step:** [1, Set Up Your App](steps/01-set-up-your-app.md) (the first message to Gemini)

**Why:** the key in `lib/api_key.dart` isn't a working key. Usually part of it is missing, there's a space inside the quotes, or it was deleted in AI Studio.

**Fix:** copy the key again from [AI Studio](https://aistudio.google.com/apikey) and paste it over the old one, with nothing else between the quotes. Then restart the app. A brand new key can take a minute to start working.

## 3. AI Studio won't open, or says it isn't available for your account

**Step:** [1, Set Up Your App](steps/01-set-up-your-app.md)

**Why:** school and work Google accounts sometimes have AI Studio switched off by their admin.

**Fix:** sign in with a personal Google account instead.

## 4. `Error: ApiException(429)`, or a message about quota or `RESOURCE_EXHAUSTED`

**Step:** any step that calls Gemini, most often [Side Quest B](steps/side-quest-b-ai-painted-dishes.md) (pictures)

**Why:** the free tier limits how many requests you can send per minute and per day. Pictures use it up faster than text.

**Fix:** wait a minute and try again. If the daily limit is used up, try again tomorrow, or switch to a model with more free requests by changing `chatModelName` in `agent_service.dart`.

## 5. `Error: ApiException(404)`, with a message that the model is not found

**Step:** any step that calls Gemini

**Why:** the model named in `chatModelName` (or `mediaModelName`, in Side Quest B) isn't available to your key. Google retires older models from time to time.

**Fix:** pick a current model from the list in [AI Studio](https://aistudio.google.com/), and put its name in `chatModelName` in `agent_service.dart`.

## 6. A red error screen after you change the code

**Step:** any step, first seen in [3, Gemini Writes the UI](steps/03-gemini-writes-the-ui.md)

**Why:** often, the app was **hot reloaded** (`r`, or saving the file) instead of restarted. A hot reload keeps the objects that already exist, such as the page's state and the `AgentService`. When a step adds fields to them, or changes how they're set up (Step 3 adds `_showXray`, `lastRawReply` and a new system message), those old objects can be left in a state the new code doesn't expect.

**Fix:** **hot restart**: press `R` in the terminal where `flutter run` runs, or the restart button in your editor. After every step, restart. Still red after a restart? Read the first line of the error: it names the widget or the value that broke. Then compare your files with the step's checkpoint.

## 7. `Gemini wrote UI I could not draw: Surface … already exists.`

**Step:** [4, Snap and Cook](steps/04-snap-and-cook.md) and later, after pressing a button such as **Cook this**

**Why:** Gemini sent `createSurface` again for a card that's already on screen, instead of only sending its new components. In A2UI, a surface is created once and then only updated: creating it again is an error, so the whole update is rejected and the card stays as it was.

**Fix:** make sure your persona says *"update the SAME surface. It already exists, so never create it again: only send its new components, with its surfaceId."* Then restart the app. From [Step 6](steps/06-fast.md) on, Express handles this by itself: it knows which surfaces exist, and only updates them.

---

# Found While Testing

## `Surface … already exists` after pressing Cook this

**Step:** [4, Snap and Cook](steps/04-snap-and-cook.md), during the first dry run

**What happened:** after **Cook this**, the reply said `Gemini wrote UI I could not draw: Surface surface-spinach-feta-omelette already exists.`, and the card didn't change into the steps.

**Cause and fix:** the persona said *"update the SAME surface, using its surfaceId again"*, and Gemini read that as "create it again with the same id". The persona now says it already exists and must not be created again. See [7](#7-gemini-wrote-ui-i-could-not-draw-surface--already-exists) above.

## A red error screen at Step 3

**Step:** [3, Gemini Writes the UI](steps/03-gemini-writes-the-ui.md), during the first dry run

**What happened:** the app showed a red error screen after a message was sent.

**Cause and fix:** see [6](#6-a-red-error-screen-after-you-change-the-code) above. **Not confirmed yet.** The likely cause is a hot reload after Step 3 added new fields, so the guide now says to restart after every step. Gemini's layouts were ruled out: dozens of likely ones (Sliders, Lists and TextFields inside Rows, Markdown texts, bad Slider values) render without a crash in the chat. If it happens again after a restart, note the first line of the error here.

Before this, the first test run used Firebase, and every problem it hit was in the Firebase setup, which the workshop no longer uses. Those notes are still in the Git history.
