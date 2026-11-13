# Checkpoints

Each folder holds the complete `lib/` folder of the app at the **end** of that step of the [workshop](../README.md).

Fell behind? Copy a checkpoint's `lib/` over your own, but **keep your own `lib/firebase_options.dart`**, which `flutterfire configure` made for your Firebase project. Also run the `flutter pub add` commands of every step up to that one.

The checkpoints build the example app, Potion Lab. Once you've caught up, put your own idea back in: your persona, your functions and your components.

| Folder | The app after this step | Packages added in this step |
| ------ | ----------------------- | --------------------------- |
| `step_03` | App shell with a placeholder agent | `firebase_core a2ui_flutter a2ui_core` (Step 2) |
| `step_04` | A hand-written surface | |
| `step_05` | Hand-written data binding and actions | |
| `step_06` | Gemini writes the UI, with the X-ray view | `firebase_ai a2ui_agent` |
| `step_07` | A persona | |
| `step_08` | Photos | `image_picker` |
| `step_09` | Actions go back to Gemini | |
| `step_10` | Functions Gemini calls | |
| `step_11` | Your own component | `json_schema_builder` |
| `step_12` | Streaming | |
| `bonus_a` | AI-painted illustrations | |
| `bonus_b` | A 3D companion | `flutter_scene vector_math` |
