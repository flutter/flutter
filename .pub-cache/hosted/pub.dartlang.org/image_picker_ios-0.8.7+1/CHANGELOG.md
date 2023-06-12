## 0.8.7+1

* Clarifies explanation of endorsement in README.
* Aligns Dart and Flutter SDK constraints.

## 0.8.7

* Updates minimum Flutter version to 3.3 and iOS 11.

## 0.8.6+9

* Updates links for the merge of flutter/plugins into flutter/packages.

## 0.8.6+8

* Fixes issue with images sometimes changing to incorrect orientation.

## 0.8.6+7

* Fixes issue where GIF file would not animate without `Photo Library Usage` permissions. Fixes issue where PNG and GIF files were converted to JPG, but only when they are do not have `Photo Library Usage` permissions.
* Updates minimum Flutter version to 3.0.

## 0.8.6+6

* Updates code for stricter lint checks.

## 0.8.6+5

* Fixes crash when `imageQuality` is set.

## 0.8.6+4

* Fixes authorization status check for iOS14+ so it includes `PHAuthorizationStatusLimited`.

## 0.8.6+3

* Returns error on image load failure.

## 0.8.6+2

* Fixes issue where selectable images of certain types (such as ProRAW images) could not be loaded.

## 0.8.6+1

* Fixes issue with crashing the app when picking images with PHPicker without providing `Photo Library Usage` permission.

## 0.8.6

* Adds `requestFullMetadata` option to `pickImage`, so images on iOS can be picked without `Photo Library Usage` permission.
* Updates minimum Flutter version to 2.10.

## 0.8.5+6

* Updates description.
* Ignores unnecessary import warnings in preparation for [upcoming Flutter changes](https://github.com/flutter/flutter/pull/106316).

## 0.8.5+5

* Adds non-deprecated codepaths for iOS 13+.

## 0.8.5+4

* Suppresses warnings for pre-iOS-11 codepaths.

## 0.8.5+3

* Fixes 'messages.g.h' file not found.

## 0.8.5+2

* Minor fixes for new analysis options.

## 0.8.5+1

* Removes unnecessary imports.
* Fixes library_private_types_in_public_api, sort_child_properties_last and use_key_in_widget_constructors
  lint warnings.

## 0.8.5

* Switches to an in-package method channel based on Pigeon.
* Fixes invalid casts when selecting multiple images on versions of iOS before
  14.0.

## 0.8.4+11

* Splits from `image_picker` as a federated implementation.
