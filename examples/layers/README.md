# Examples of Flutter's layered architecture

This directory contains several self-contained examples that illustrate
Flutter's layered architecture.

 * [*raw/*](raw/) These examples show how to program against the lowest layer of
   the system. They manually receive input packets and construct composited
   scenes.

 * [*rendering/*](rendering/) These examples use Flutter's render tree to
   structure your app using a retained tree of visual objects. These objects
   coordinate to determine their size and position on screen and to handle
   events.

 * [*widgets/*](widgets/) These examples use Flutter's widgets to build more
   elaborate apps using a reactive framework.

 * [*services/*](services/) These examples use services available in Flutter to
   interact with the host platform.

To run each example, specify the demo file on the `flutter run`
command line, for example:

```
flutter run raw/spinning_square.dart
flutter run rendering/spinning_square.dart
flutter run widgets/spinning_square.dart
```
