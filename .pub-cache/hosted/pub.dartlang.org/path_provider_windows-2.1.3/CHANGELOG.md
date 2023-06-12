## 2.1.3

* Updates minimum Flutter version to 2.10.
* Adds compatibility with `package:win32` 3.x.

## 2.1.2

* Fixes avoid_redundant_argument_values lint warnings and minor typos.

## 2.1.1

* Updates dependency version of `package:win32` to 2.1.0.

## 2.1.0

* Upgrades `package:ffi` dependency to 2.0.0.
* Added support for unicode encoded VERSIONINFO.
* Minor fixes for new analysis options.

## 2.0.6

* Fixes library_private_types_in_public_api, sort_child_properties_last and use_key_in_widget_constructors
  lint warnings.

## 2.0.5

* Removes dependency on `meta`.

## 2.0.4

* Removed obsolete `pluginClass: none` from pubpsec.

## 2.0.3

* Updated installation instructions in README.

## 2.0.2

* Add `implements` to pubspec.yaml.
* Add `registerWith()` to the Dart main class.

## 2.0.1

* Fix a crash when a known folder can't be located.

## 2.0.0

* Migrate to null safety

## 0.0.4+4

* Update Flutter SDK constraint.

## 0.0.4+3

* Remove unused `test` dependency.
* Update Dart SDK constraint in example.

## 0.0.4+2

* Check in windows/ directory for example/

## 0.0.4+1

* Add getPath to the stub, so that the analyzer won't complain about
  fakes that override it.
* export 'folders.dart' rather than importing it, since it's intended to be
  public.

## 0.0.4

* Move the actual implementation behind a conditional import, exporting
  a stub for platforms that don't support FFI. Fixes web builds in
  projects with transitive dependencies on path_provider.

## 0.0.3

* Add missing `pluginClass: none` for compatibilty with stable channel.

## 0.0.2

* README update for endorsement.
* Changed getApplicationSupportPath location.
* Removed getLibraryPath.

## 0.0.1+2

* The initial implementation of path_provider for Windows
  * Implements getTemporaryPath, getApplicationSupportPath, getLibraryPath,
    getApplicationDocumentsPath and getDownloadsPath.
