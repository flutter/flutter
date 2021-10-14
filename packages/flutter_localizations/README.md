# Flutter Framework localizations

This package contains the localizations used by the Flutter framework
itself.

See the [localization README](./lib/src/l10n/README.md) for more detailed
information about the localizations themselves.

## Adding a new string to localizations

If you (someone contributing to the Flutter framework) want to add a new
string to the `MaterialLocalizations`, `WidgetsLocalizations` or the
`CupertinoLocalizations` objects (e.g. because you've added a new widget
and it has a tooltip), follow these steps (these instructions are for
`MaterialLocalizations`, but apply equally to `CupertinoLocalizations`
and `WidgetsLocalizations`, with appropriate name substitutions):

1. Add the new getter to the localizations class `MaterialLocalizations`,
   in `flutter_localizations/lib/src/material_localizations.dart`.

2. Implement a default value in `DefaultMaterialLocalizations` in
   `flutter_localizations/lib/src/material_localizations.dart`

3. Add a test to `test/material/localizations_test.dart` that verifies that
   this new value is implemented.

4. Update the `flutter_localizations` package. To add a new string to the
   `flutter_localizations` package, you must first add it to the English
   translations (`lib/src/l10n/material_en.arb`), including a description.

   Then you need to add new entries for the string to all of the other
   language locale files by running:
   ```
   dart dev/tools/localization/bin/gen_missing_localizations.dart
   ```
   Which will copy the English strings into the other locales as placeholders
   until they can be translated.

   Finally you need to re-generate lib/src/l10n/localizations.dart by running:
   ```
   dart dev/tools/localization/bin/gen_localizations.dart --overwrite
   ```

   There is a [localization README](./lib/src/l10n/README.md) file with further
   information in the `lib/src/l10n/` directory.

5. If you are a Google employee, you should then also follow the instructions
   at `go/flutter-l10n`. If you're not, don't worry about it.

## Updating an existing string

If you or someone contributing to the Flutter framework wants to modify an
existing string in the MaterialLocalizations objects, follow these steps:

1. Modify the default value of the relevant getter(s) in
   `DefaultMaterialLocalizations` below.

2. Update the `flutter_localizations` package. Modify the out-of-date English
   strings in `lib/src/l10n/material_en.arb`.

   You also need to re-generate `lib/src/l10n/localizations.dart` by running:
   ```
   dart dev/tools/localization/bin/gen_localizations.dart --overwrite
   ```

   This script may result in your updated getters being created in newer
   locales and set to the old value of the strings. This is to be expected.
   Leave them as they were generated, and they will be picked up for
   translation.

   There is a [localization README](./lib/src/l10n/README.md) file with further
   information in the `lib/src/l10n/` directory.

3. If you are a Google employee, you should then also follow the instructions
   at `go/flutter-l10n`. If you're not, don't worry about it.
