# Troubleshooting

Each entry gives the step, what you see, why it happens and how to fix it.

* **Problems you may hit** were prepared ahead of time, so you're ready before anyone runs into them.
* **Found while testing** logs real problems from test runs. Found a new one? Add it there.

---

# Problems You May Hit

## 1. The app only says "Paste your Gemini API key into lib/api_key.dart"

**Step:** 3, The App Shell

**Why:** `geminiApiKey` in `lib/api_key.dart` is still the placeholder, or is empty.

**Fix:** paste your key from [Google AI Studio](https://aistudio.google.com/apikey) between the quotes, then **restart** the app. A hot reload isn't enough, because the key is a constant that's read when the app starts.

## 2. `Error: ApiException(400): API key not valid. Please pass a valid API key.`

**Step:** 3, The App Shell (the first message to Gemini)

**Why:** the key in `lib/api_key.dart` isn't a working key. Usually part of it is missing, there's a space inside the quotes, or it was deleted in AI Studio.

**Fix:** copy the key again from [AI Studio](https://aistudio.google.com/apikey) and paste it over the old one, with nothing else between the quotes. Then restart the app. A brand new key can take a minute to start working.

## 3. AI Studio won't open, or says it isn't available for your account

**Step:** 1, Get Your Gemini API Key

**Why:** school and work Google accounts sometimes have AI Studio switched off by their admin.

**Fix:** sign in with a personal Google account instead.

## 4. `Error: ApiException(429)`, or a message about quota or `RESOURCE_EXHAUSTED`

**Step:** any step that calls Gemini, most often Bonus A (pictures)

**Why:** the free tier limits how many requests you can send per minute and per day. Pictures use it up faster than text.

**Fix:** wait a minute and try again. If the daily limit is used up, try again tomorrow, or switch to a model with more free requests by changing `chatModelName` in `agent_service.dart`.

## 5. `Error: ApiException(404)`, with a message that the model is not found

**Step:** any step that calls Gemini

**Why:** the model named in `chatModelName` (or `mediaModelName`, in Bonus A) isn't available to your key. Google retires older models from time to time.

**Fix:** pick a current model from the list in [AI Studio](https://aistudio.google.com/), and put its name in `chatModelName` in `agent_service.dart`.

---

# Found While Testing

Nothing yet with the API key setup. The first test run used Firebase, and every problem it hit was in the Firebase setup, which the workshop no longer uses. Those notes are still in the Git history.
