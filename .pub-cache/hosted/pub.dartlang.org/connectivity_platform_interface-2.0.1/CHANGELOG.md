## 2.0.1

* Update platform_plugin_interface version requirement.

## 2.0.0

* Migrate to null safety.

## 1.0.7

* Update Flutter SDK constraint.

## 1.0.6

* Update lower bound of dart dependency to 2.1.0.

## 1.0.5

* Remove dart:io Platform checks from the MethodChannel implementation. This is
tripping the analysis of other versions of the plugin.

## 1.0.4

* Bump the minimum Flutter version to 1.12.13+hotfix.5.

## 1.0.3

* Make the pedantic dev_dependency explicit.

## 1.0.2

* Bring ConnectivityResult and LocationAuthorizationStatus enums from the core package.
* Use the above Enums as return values for ConnectivityPlatformInterface methods.
* Modify the MethodChannel implementation so it returns the right types.
* Bring all utility methods, asserts and other logic that is only needed on the MethodChannel implementation from the core package.
* Bring MethodChannel unit tests from core package.

## 1.0.1

* Fix README.md link.

## 1.0.0

* Initial release.
