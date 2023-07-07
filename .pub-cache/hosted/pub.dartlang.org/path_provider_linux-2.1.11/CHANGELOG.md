## 2.1.11

* Removes obsolete null checks on non-nullable values.
* Updates minimum supported SDK version to Flutter 3.3/Dart 2.18.

## 2.1.10

* Clarifies explanation of endorsement in README.
* Aligns Dart and Flutter SDK constraints.

## 2.1.9

* Updates links for the merge of flutter/plugins into flutter/packages.

## 2.1.8

* Adds compatibility with `xdg_directories` 1.0.
* Updates minimum Flutter version to 3.0.

## 2.1.7

* Bumps ffi dependency to match path_provider_windows.

## 2.1.6

* Fixes library_private_types_in_public_api, sort_child_properties_last and use_key_in_widget_constructors
  lint warnings.

## 2.1.5

* Removes dependency on `meta`.

## 2.1.4

* Fixes `getApplicationSupportPath` handling of applications where the
  application ID is not set.

## 2.1.3

* Change getApplicationSupportPath from using executable name to application ID (if provided).
  * If the executable name based directory exists, continue to use that so existing applications continue with the same behaviour.

## 2.1.2

* Fixes link in README.

## 2.1.1

* Removed obsolete `pluginClass: none` from pubpsec.

## 2.1.0

* Now `getTemporaryPath` returns the value of the `TMPDIR` environment variable primarily. If `TMPDIR` is not set, `/tmp` is returned.

## 2.0.2

* Updated installation instructions in README.

## 2.0.1

* Add `implements` to pubspec.yaml.
* Add `registerWith` method to the main Dart class.

## 2.0.0

* Migrate to null safety.

## 0.1.1+3

* Update Flutter SDK constraint.

## 0.1.1+2

* Log errors in the example when calls to the `path_provider` fail.

## 0.1.1+1

* Check in linux/ directory for example/

## 0.1.1 - NOT PUBLISHED

* Reverts changes on 0.1.0, which broke the tree.

## 0.1.0 - NOT PUBLISHED

* This release updates getApplicationSupportPath to use the application ID instead of the executable name.
  * No migration is provided, so any older apps that were using this path will now have a different directory.

## 0.0.1+2

* This release updates the example to depend on the endorsed plugin rather than relative path

## 0.0.1+1

* This updates the readme and pubspec and example to reflect the endorsement of this implementation of `path_provider`

## 0.0.1

* The initial implementation of path\_provider for Linux
  * Implements getApplicationSupportPath, getApplicationDocumentsPath, getDownloadsPath, and getTemporaryPath
