# font_assets

This app tests fonts that are provided by Dart build hooks through
`package:font_asset`, instead of the `fonts:` section of a pubspec:

- the app's own `hook/build.dart` registers the `RobotoFromHook` family
  (regular and bold);
- the dependency `font_asset_package` provides the `HookIcons` icon font from
  its hook and exposes `HookIcons.add` for it, like an icon font package would.

Both hooks generate their font files into the hook output directory from
base64 data in `lib/src/font_data.dart` (tiny subsets of Roboto and the
Material icons font), because this repository does not contain binary files.
The widget test checks that both families end up in `FontManifest.json` and
that the generated files are bundled unchanged.

Font assets are part of the `enable-dart-data-assets` experiment, which the
pubspec enables for this project. Run with `flutter test`.
