## 3.0.1

* Fixes library_private_types_in_public_api, sort_child_properties_last and use_key_in_widget_constructors
  lint warnings.

## 3.0.0

* Changes the major version since, due to a typo in `default_package` in
  existing versions of `url_launcher`, requiring Dart registration in this
  package is in practice a breaking change.
  * Does not include any API changes; clients can allow both 2.x or 3.x.

## 2.0.4

* **\[Retracted\]** Switches to an in-package method channel implementation.

## 2.0.3

* Updates code for new analysis options.
* Updates unit tests.

## 2.0.2

* Replaced reference to `shared_preferences` plugin with the `url_launcher` in the README.

## 2.0.1

* Add native unit tests.
* Updated installation instructions in README.

## 2.0.0

* Migrate to null safety.
* Update the example app: remove the deprecated `RaisedButton` and `FlatButton` widgets.
* Set `implementation` in pubspec.yaml

## 0.0.2+1

* Update Flutter SDK constraint.

## 0.0.2

* Update integration test examples to use `testWidgets` instead of `test`.

# 0.0.1+9

* Update Dart SDK constraint in example.

# 0.0.1+8

* Remove no-op android folder in the example app.

# 0.0.1+7

* Remove Android folder from url_launcher_web and url_launcher_macos.

# 0.0.1+6

* Declare API stability and compatibility with `1.0.0` (more details at: https://github.com/flutter/flutter/wiki/Package-migration-to-1.0.0).

# 0.0.1+5

* Fixed the launchUniversalLinkIos method.
* Fix CocoaPods podspec lint warnings.

# 0.0.1+4

* Make the pedantic dev_dependency explicit.

# 0.0.1+3

* Update Gradle version.

# 0.0.1+2

* Update README.

# 0.0.1+1

* Add an android/ folder with no-op implementation to workaround https://

# 0.0.1

* Initial open source release.
