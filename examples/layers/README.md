# Examples of Flutter's layered architecture

This directory contains a number of self-contained examples that illustrate
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

To run each example, use the `-t` argument to the `flutter` tool:

```
flutter run -t widgets/spinning_square.dart
```
