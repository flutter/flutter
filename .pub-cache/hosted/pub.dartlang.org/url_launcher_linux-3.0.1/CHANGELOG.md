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
* Fix minor memory leak in Linux url_launcher tests.
* Fixes canLaunch detection for URIs addressing on local or network file systems

## 2.0.2

* Replaced reference to `shared_preferences` plugin with the `url_launcher` in the README.

## 2.0.1

* Updated installation instructions in README.

## 2.0.0

* Migrate to null safety.
* Update the example app: remove the deprecated `RaisedButton` and `FlatButton` widgets.
* Fix outdated links across a number of markdown files ([#3276](https://github.com/flutter/plugins/pull/3276))
* Set `implementation` in pubspec.yaml

## 0.0.2+1

* Update Flutter SDK constraint.

## 0.0.2

* Update integration test examples to use `testWidgets` instead of `test`.

## 0.0.1+4

* Update Dart SDK constraint in example.

## 0.0.1+3

* Add a missing include.

## 0.0.1+2

* Check in linux/ directory for example/

# 0.0.1+1
* README update for endorsement by url_launcher.

# 0.0.1
* The initial implementation of url_launcher for Linux
