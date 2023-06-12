## 2.1.12

* Clarifies explanation of endorsement in README.
* Aligns Dart and Flutter SDK constraints.

## 2.1.11

* Updates links for the merge of flutter/plugins into flutter/packages.
* Updates minimum Flutter version to 3.0.

## 2.1.10

* Updates code for `no_leading_underscores_for_local_identifiers` lint.

## 2.1.9

* Updates imports for `prefer_relative_imports`.
* Updates minimum Flutter version to 2.10.
* Fixes violations of new analysis option use_named_constants.

## 2.1.8

* Minor fixes for new analysis options.

## 2.1.7

* Fixes library_private_types_in_public_api, sort_child_properties_last and use_key_in_widget_constructors
  lint warnings.

## 2.1.6

* Internal code cleanup for stricter analysis options.

## 2.1.5

* Removes dependency on `meta`.

## 2.1.4

* Implemented `maxWidth`, `maxHeight` and `imageQuality` when selecting images
  (except for gifs).

## 2.1.3

* Add `implements` to pubspec.

## 2.1.2

* Updated installation instructions in README.

# 2.1.1

* Implemented `getMultiImage`.
* Initialized the following `XFile` attributes for picked files:
  * `name`, `length`, `mimeType` and `lastModified`.

# 2.1.0

* Implemented `getImage`, `getVideo` and `getFile` methods that return `XFile` instances.
* Move tests to `example` directory, so they run as integration_tests with `flutter drive`.

# 2.0.0

* Migrate to null safety.
* Add doc comments to point out that some arguments aren't supported on the web.

# 0.1.0+3

* Update Flutter SDK constraint.

# 0.1.0+2

* Adds Video MIME Types for the safari browser for acception

# 0.1.0+1

* Remove `android` directory.

# 0.1.0

* Initial open-source release.
