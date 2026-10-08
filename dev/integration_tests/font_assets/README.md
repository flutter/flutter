# font_assets

This app tests fonts that are provided by a Dart build hook (`hook/build.dart`)
through `package:font_asset`, instead of the `fonts:` section of the pubspec.

The hook registers the `RobotoFromHook` family (regular and bold); the fonts are
taken from the Flutter SDK cache so that no binaries are checked in. The widget
test checks that the family ends up in `FontManifest.json` and that the font
files are part of the asset bundle.

Font assets are part of the `enable-dart-data-assets` experiment, which the
pubspec enables for this project. Run with `flutter test`.
