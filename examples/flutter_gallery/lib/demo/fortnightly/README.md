# Fortnightly

A Flutter sample app based on the Material study Fortnightly (a hypothetical, online newspaper.) It
showcases print-quality, custom typography, Material Theming, and text-heavy UI design and layout.

For info on the Fortnightly Material Study, see: https://material.io/design/material-studies/fortnightly.html

## Goals for this sample

* Help you understand how to customize and layout text.
* Provide you with example code for
  * Text
  * A short app bar (the menu button top left.)
  * Avatar images

## Widgets / APIs

* BeveledRectangleBorder
* BoxConstraints on Container
* CircleAvatar
* ExactAssetImage
* Fonts
* SafeArea
* Stack
* SingleChildScrollView
* Text
* TextStyle
* TextTheme

## Notice

* Theming is passed as a parameter in the constructor of `MaterialApp` (`theme:`).
* `SafeArea` adds padding around notches and virtual home buttons on screens that have them (like
    iPhone X+). Here, it protects the `ShortAppBar` from overlapping with the status bar (time)
    and makes sure the bottom of the newspaper article has padding beneath it if necessary.
* The entire newspaper article is wrapped in a `SingleChildScrollView` widget which ensures that the
    entire article can be viewed no matter what the screen's size or orientation is.
* The `Text` widget with text ' ¬ ' has a `TextStyle` that changes one parameter of an inherited
    `TextStyle` using `.apply()``.
* The `Text` widget with text 'Connor Eghan' has a `TextStyle` created explicitly instead of
    inheriting from theming.
* You can break up long strings in your source files by putting them on multiple lines.
* Fonts are imported with multiple files expressing their weights (Bold, Light, Medium, Regular)
    but are accessed with a `FontWeight` value like `FontWeight.w800` for Merriweather-Bold.ttf.

## Questions/issues

If you have a general question about developing in Flutter, the best places to go are:

* [The FlutterDev Google Group](https://groups.google.com/forum/#!forum/flutter-dev)
* [The Flutter Gitter channel](https://gitter.im/flutter/flutter)
* [StackOverflow](https://stackoverflow.com/questions/tagged/flutter)
