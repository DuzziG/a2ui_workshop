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

**Or skip iOS for now:** run `flutterfire configure` again and select only **android** and **web**. Neither needs the gem, and Chrome is the easiest way to run the workshop anyway.

**Watch out:** if you created the project from the CLI (`<create a new project>`), Gemini isn't enabled on it yet. In the [Firebase console](https://console.firebase.google.com/), open your project, go to **AI Logic**, click **Get started** and choose the **Gemini Developer API**. Otherwise your first Gemini call in Step 6 fails.
