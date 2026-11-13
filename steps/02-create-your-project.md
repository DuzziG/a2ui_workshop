[← Step 1: Get Your Gemini API Key](01-get-your-gemini-api-key.md) &nbsp;·&nbsp; [Overview](../README.md) &nbsp;·&nbsp; [Step 3: The App Shell →](03-the-app-shell.md)

*Part 1: Set Up · Step 2 of 12*

# Step 2: Create Your Project

1.  **Create the app** and go into its folder:
    ```sh
    flutter create my_a2ui_app
    cd my_a2ui_app
    ```
    Want your own app name, such as `potion_lab`? Go for it, but change it in **both** lines. Use lowercase letters, numbers and underscores only.

    Run every command from this folder from now on.

2.  **Add the packages.** All of them at once, so you won't stop for installs later:
    ```sh
    flutter pub add a2ui_flutter a2ui_core a2ui_agent dartantic_ai image_picker json_schema_builder
    ```

    | Package | What it does |
    | ------- | ------------ |
    | `a2ui_core` | Reads A2UI messages and keeps the state of every surface |
    | `a2ui_flutter` | Draws those surfaces as Flutter widgets |
    | `a2ui_agent` | Teaches Gemini A2UI, and checks what it writes |
    | `dartantic_ai` | Talks to Gemini |
    | `image_picker` | Picks photos to show Gemini (Step 8) |
    | `json_schema_builder` | Describes your own components to Gemini (Step 11) |

3.  **Save your API key.** Go back to the AI Studio tab, copy your key, and paste it into a new file, `lib/api_key.dart`:
    ```dart
    // lib/api_key.dart
    // Your Gemini API key, from https://aistudio.google.com/apikey
    // Keep it private: never commit it or share it.
    const geminiApiKey = 'PASTE-YOUR-API-KEY-HERE';
    ```
    Then tell Git to ignore that file, so your key never ends up on GitHub:
    ```sh
    echo "lib/api_key.dart" >> .gitignore
    ```

---

[← Step 1: Get Your Gemini API Key](01-get-your-gemini-api-key.md) &nbsp;·&nbsp; [Overview](../README.md) &nbsp;·&nbsp; [Step 3: The App Shell →](03-the-app-shell.md)
