# Troubleshooting

Problems found while testing the workshop, in the order we hit them. Each one also has a short note in the step where it happens.

Found a new one? Add it to the end, with the step, what you saw, why it happens and how to fix it.

---

## 1. `flutterfire` is not found after installing it

**Step:** 1, Install the Command Line Tools

**What you see:** right after `dart pub global activate flutterfire_cli`, running `flutterfire` fails with `command not found: flutterfire` (macOS and Linux), or `'flutterfire' is not recognized` (Windows). The install itself also prints a warning that the folder isn't on your path.

**Why:** `dart pub global activate` puts the command in Dart's global package folder, and your terminal doesn't look there unless that folder is on your `PATH`.

**Fix:** add the folder to your `PATH`, then open a **new** terminal window.

* **macOS (zsh, the default):**
    ```sh
    echo 'export PATH="$PATH:$HOME/.pub-cache/bin"' >> ~/.zshrc
    ```
* **Linux (bash):**
    ```sh
    echo 'export PATH="$PATH:$HOME/.pub-cache/bin"' >> ~/.bashrc
    ```
* **Windows:** add `%LOCALAPPDATA%\Pub\Cache\bin` to your `Path` in *Edit the system environment variables* → *Environment Variables*.

**Quick workaround** if you'd rather not touch your `PATH` now. This runs the same command:
```sh
dart pub global run flutterfire_cli:flutterfire configure
```

---

## 2. `flutterfire configure` stops with `cannot load such file -- xcodeproj`

**Step:** 2, Create Your Project

**What you see:** on a Mac, `flutterfire configure` creates the Firebase project and registers the apps, then stops with:
```
Exception: .../rubygems/core_ext/kernel_require.rb:54:in `require': cannot load such file -- xcodeproj (LoadError)
```

**Why:** to add the iOS config file to your Xcode project, FlutterFire uses the `xcodeproj` Ruby gem, and the Ruby that comes with macOS doesn't have it.

**Fix:** your Firebase apps were already created, so nothing is lost.

1. Install the gem:
    ```sh
    sudo gem install xcodeproj
    ```
2. Run `flutterfire configure` again and pick your **existing** project. Don't create a new one.
3. Check that `lib/firebase_options.dart` exists. It may not have been written the first time.

**Or skip iOS for now:** run `flutterfire configure` again and select only **android** and **web**. Neither needs the gem, and Chrome needs no extra setup.

**Watch out:** if you created the project from the CLI (`<create a new project>`), Gemini isn't enabled on it yet. In the [Firebase console](https://console.firebase.google.com/), open your project, go to **AI Logic**, click **Get started** and choose the **Gemini Developer API**. Otherwise your first Gemini call in Step 6 fails.

---

## 3. `flutterfire configure` fails with `Failed to get WEB app configuration`

**Step:** 2, Create Your Project

**What you see:** `flutterfire configure` registers the apps, then stops with:
```
FirebaseCommandException: An error occured on the Firebase CLI when attempting to run a command.
COMMAND: firebase apps:sdkconfig web 1:...:web:... --json
ERROR: Failed to get WEB app configuration. See firebase-debug.log for more info.
```
No files are written.

**Why (likely, still to confirm):** the web app was registered only moments before, and Firebase isn't ready to hand out its settings yet. It happens most with a project created a few minutes earlier.

**Fix:** try these in order.

1. Wait a minute or two, then run `flutterfire configure` again with the same choices.
2. Still failing? Ask for the config directly, using the app ID from the error, to see a clearer message:
    ```sh
    firebase apps:sdkconfig web <app-id-from-the-error>
    ```
3. Update the Firebase CLI with `npm install -g firebase-tools@latest`, then `firebase logout` and `firebase login`, and try again.

The full reason is in `firebase-debug.log`, which the CLI writes in your project folder.
