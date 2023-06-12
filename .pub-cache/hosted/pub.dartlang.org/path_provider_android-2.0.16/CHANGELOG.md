## 2.0.16

* Fixes bug with `getExternalStoragePaths(null)`.

## 2.0.15

* Switches the medium from MethodChannels to Pigeon.

## 2.0.14

* Fixes library_private_types_in_public_api, sort_child_properties_last and use_key_in_widget_constructors
  lint warnings.

## 2.0.13

* Fixes typing build warning.

## 2.0.12

* Returns to using a different platform channel name, undoing the revert in
  2.0.11, but updates the minimum Flutter version to 2.8 to avoid the issue
  that caused the revert.

## 2.0.11

* Temporarily reverts the platform channel name change from 2.0.10 in order to
  restore compatibility with Flutter versions earlier than 2.8.

## 2.0.10

* Switches to a package-internal implementation of the platform interface.

## 2.0.9

* Updates Android compileSdkVersion to 31.

## 2.0.8

* Updates example app Android compileSdkVersion to 31.
* Fixes typing build warning.

## 2.0.7

* Fixes link in README.

## 2.0.6

* Split from `path_provider` as a federated implementation.
