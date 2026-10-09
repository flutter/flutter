# font_assets

This app tests fonts that are provided by Dart build hooks through
`package:font_asset`, instead of the `fonts:` section of a pubspec:

- the app's own `hook/build.dart` registers the `RobotoFromHook` family
  (regular and bold);
- the dependency `font_asset_package` provides the `HookIcons` icon font from
  its hook and exposes `HookIcons.add` for it, like an icon font package would.

The font files are taken from the Flutter SDK cache so that no binaries are
checked in. The widget test checks that both families end up in
`FontManifest.json` and that the font files are part of the asset bundle.

Font assets are part of the `enable-dart-data-assets` experiment, which the
pubspec enables for this project. Run with `flutter test`.
