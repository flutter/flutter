# Material Library Localizations

The `.arb` files in this directory contain localized values (primarily
strings) used by the material library.  The `localizations.dart` file
combines all of the localizations into a single Map that is
linked with the rest of flutter_localizations package.

If you're looking for information about internationalizing Flutter
apps in general, see the
[Internationalizing Flutter Apps](https://flutter.io/tutorials/internationalization/) tutorial.


### Translations for one locale: .arb files

The Material library uses
[Application Resource Bundle](https://code.google.com/p/arb/wiki/ApplicationResourceBundleSpecification)
files, which have a `.arb` extension, to store localized translations
of messages, format strings, and other values. This format is also
used by the Dart [intl](https://pub.dartlang.org/packages/intl)
package and it is supported by the
[Google Translators Toolkit](https://translate.google.com/toolkit).

The material library only depends on a small subset of the ARB format.
Each .arb file contains a single JSON table that maps from resource
IDs to localized values.

Filenames contain the locale that the values have been translated
for. For example `material_de.arb` contains German translations, and
`material_ar.arb` contains Arabic translations. Files that contain
regional translations have names that include the locale's regional
suffix. For example `material_en_GB.arb` contains additional English
translations that are specific to Great Britain.

There is one language-specifc .arb file for each supported locale. If
an additional file with a regional suffix is present, the regional
localizations are automatically merged with the language-specific ones.

The JSON table's keys, called resource IDs, are valid Dart variable
names. They correspond to methods from the `MaterialLocalizations`
class. For example:

```dart
Widget build(BuildContext context) {
  return new FlatButton(
    child: new Text(
      MaterialLocalizations.of(context).cancelButtonLabel,
    ),
  );
}
```

This widget build method creates a button whose label is the local
translation of "CANCEL" which is defined for the `cancelButtonLabel`
resource ID.

Each of the language-specific .arb files contains an entry for
`cancelButtonLabel`. They're all represented by the `Map` in the
generated `localizations.dart` file. The Map is used by the
MaterialLocalizations class.


### material_en.arb Defines all of the resource IDs

All of the `.arb` files whose names do not include a regional suffix
contain translations for the same set of resource IDs as
`material_en.arb`.

For each resource ID defined for English in material_en.arb, there is
an additional resource with an '@' prefix. These '@' resources are not
used by the material library at run time, they just exist to inform
translators about how the value will be used.

```dart
"cancelButtonLabel": "CANCEL",
"@cancelButtonLabel": {
  "description": "The label for cancel buttons and menu items.",
  "type": "text"
},
```


### Values with Parameters, Plurals

A few of material translations contain `$variable` tokens. The
material library replaces these tokens with values at run-time. For
example:

```dart
"aboutListTileTitle": "About $applicationName",
```

The value for this resource ID is retrieved with a parameterized
method instead of a simple getter:

```dart
MaterialLocalizations.of(context).aboutListTileTitle(yourAppTitle)
```

The names of the `$variable` tokens match the names of the
`MaterialLocalizations` method parameters.


Plurals are handled similarly, with a lookup method that includes a
quantity parameter. For example `selectedRowCountTitle` returns a
string like "1 item selected" or "no items selected".

```dart
MaterialLocalizations.of(context).selectedRowCountTitle(yourRowCount)
```

Plural translations can be provided for several quantities: 0, 1, 2,
"few", "many", "other". The variations are identified by a resource ID
suffix which must be one of "Zero", "One", "Two", "Few", "Many",
"Other". The "Other" variation is used when none of the other
quantities apply. All plural resources must include a resource with
the "Other" suffix. For example the English translations
('material_en.arb') for `selectedRowCountTitle` are:

```dart
"selectedRowCountTitleZero": "No items selected",
"selectedRowCountTitleOne": "1 item selected",
"selectedRowCountTitleOther": "$selectedRowCount items selected",
```


### Generated file localizations.dart: all of the localizations as a Map

If you look at the comment at the top of `localizations.dart` you'll
see that it was manually generated using a `dev/tools` app called
`gen_localizations` roughly like this:

```dart
dart dev/tools/gen_localizations.dart packages/flutter_localizations/lib/src/l10n material
```

The gen_localizations app just combines the contents of all of the
.arb files into a single `Map` that has entries for each .arb
file's locale. The `MaterialLocalizations` class implementation uses
this Map to implement the methods that lookup localized resource
values.

The gen_localizations app must be run by hand after .arb files have
been updated. The app's first parameter is the path to this directory,
the second is the file name prefix (the file name less the locale
suffix) for the .arb files in this directory.


### Translations Status, Reporting Errors

The transltations (the `.arb` files) in this directory are based on
the english translations in `material_en.arb`. As noted earlier,
material_en.arb, contains a small amount of descriptive information
for each resource ID, under the companion resources whose IDs begin
with '@'.

Not all of the translations represented here have been vetted by
native speakers. The following translations have been reviewed by
native speakers on the Flutter team:

*  material_de.arb
*  material_en.arb, material_en_GB.arb, material_en_IE.arb, material_en_ZA.arb
*  material_fr.arb, material_fr_CA.arb
*  material_ja.arb
*  material_ru.arb

The others were automatically generated using the Google Translators
Toolkit. We are actively seeking review (by native speakers) for them.

If you have feedback about the translations please
[file an issue on the Flutter github repo](https://github.com/flutter/flutter/issues/new).


### See Also

The [Internationalizing Flutter Apps](https://flutter.io/tutorials/internationalization/)
tutorial describes how to use the internationlization APIs in an
ordinary Flutter app.

[Application Resource Bundle](https://code.google.com/p/arb/wiki/ApplicationResourceBundleSpecification)
covers the `.arb` file format used to store localized translations
of messages, format strings, and other values.

The Dart [intl](https://pub.dartlang.org/packages/intl)
package supports internationalization.
