// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/analyzer/messages.yaml' and run
// 'dart pkg/analyzer/tool/messages/generate.dart' to update.

import "package:analyzer/error/error.dart";

// It is hard to visually separate each code's _doc comment_ from its published
// _documentation comment_ when each is written as an end-of-line comment.
// ignore_for_file: slash_for_doc_comments

class PubspecWarningCode extends ErrorCode {
  /**
   * Parameters:
   * 0: the path to the asset directory as given in the file.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an asset list contains a value
  // referencing a directory that doesn't exist.
  //
  // #### Example
  //
  // Assuming that the directory `assets` doesn't exist, the following code
  // produces this diagnostic because it's listed as a directory containing
  // assets:
  //
  // ```yaml
  // %uri="pubspec.yaml"
  // name: example
  // flutter:
  //   assets:
  //     - assets/
  // ```
  //
  // #### Common fixes
  //
  // If the path is correct, then create a directory at that path.
  //
  // If the path isn't correct, then change the path to match the path of the
  // directory containing the assets.
  static const PubspecWarningCode ASSET_DIRECTORY_DOES_NOT_EXIST =
      PubspecWarningCode(
    'ASSET_DIRECTORY_DOES_NOT_EXIST',
    "The asset directory '{0}' doesn't exist.",
    correctionMessage:
        "Try creating the directory or fixing the path to the directory.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the path to the asset as given in the file.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an asset list contains a value
  // referencing a file that doesn't exist.
  //
  // #### Example
  //
  // Assuming that the file `doesNotExist.gif` doesn't exist, the following code
  // produces this diagnostic because it's listed as an asset:
  //
  // ```yaml
  // %uri="pubspec.yaml"
  // name: example
  // flutter:
  //   assets:
  //     - doesNotExist.gif
  // ```
  //
  // #### Common fixes
  //
  // If the path is correct, then create a file at that path.
  //
  // If the path isn't correct, then change the path to match the path of the
  // file containing the asset.
  static const PubspecWarningCode ASSET_DOES_NOT_EXIST = PubspecWarningCode(
    'ASSET_DOES_NOT_EXIST',
    "The asset file '{0}' doesn't exist.",
    correctionMessage: "Try creating the file or fixing the path to the file.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the value of the `asset` key
  // isn't a list.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the value of the assets
  // key is a string when a list is expected:
  //
  // ```yaml
  // %uri="pubspec.yaml"
  // name: example
  // flutter:
  //   assets: assets/
  // ```
  //
  // #### Common fixes
  //
  // Change the value of the asset list so that it's a list:
  //
  // ```yaml
  // %uri="pubspec.yaml"
  // name: example
  // flutter:
  //   assets:
  //     - assets/
  // ```
  static const PubspecWarningCode ASSET_FIELD_NOT_LIST = PubspecWarningCode(
    'ASSET_FIELD_NOT_LIST',
    "The value of the 'asset' field is expected to be a list of relative file paths.",
    correctionMessage:
        "Try converting the value to be a list of relative file paths.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an asset list contains a value
  // that isn't a string.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the asset list contains
  // a map:
  //
  // ```yaml
  // %uri="pubspec.yaml"
  // name: example
  // flutter:
  //   assets:
  //     - image.gif: true
  // ```
  //
  // #### Common fixes
  //
  // Change the asset list so that it only contains valid POSIX-style file
  // paths:
  //
  // ```yaml
  // %uri="pubspec.yaml"
  // name: example
  // flutter:
  //   assets:
  //     - image.gif
  // ```
  static const PubspecWarningCode ASSET_NOT_STRING = PubspecWarningCode(
    'ASSET_NOT_STRING',
    "Assets are required to be file paths (strings).",
    correctionMessage: "Try converting the value to be a string.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the value of either the
  // `dependencies` or `dev_dependencies` key isn't a map.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the value of the
  // top-level `dependencies` key is a list:
  //
  // ```yaml
  // %uri="pubspec.yaml"
  // name: example
  // dependencies:
  //   - meta
  // ```
  //
  // #### Common fixes
  //
  // Use a map as the value of the `dependencies` key:
  //
  // ```yaml
  // %uri="pubspec.yaml"
  // name: example
  // dependencies:
  //   meta: ^1.0.2
  // ```
  static const PubspecWarningCode DEPENDENCIES_FIELD_NOT_MAP =
      PubspecWarningCode(
    'DEPENDENCIES_FIELD_NOT_MAP',
    "The value of the '{0}' field is expected to be a map.",
    correctionMessage: "Try converting the value to be a map.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a key is used in a
  // `pubspec.yaml` file that was deprecated. Unused keys take up space and
  // might imply semantics that are no longer valid.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the `author` key is no
  // longer being used:
  //
  // ```dart
  // %uri="pubspec.yaml"
  // name: example
  // author: 'Dash'
  // ```
  //
  // #### Common fixes
  //
  // Remove the deprecated key:
  //
  // ```dart
  // %uri="pubspec.yaml"
  // name: example
  // ```
  static const PubspecWarningCode DEPRECATED_FIELD = PubspecWarningCode(
    'DEPRECATED_FIELD',
    "The '{0}' field is no longer used and can be removed.",
    correctionMessage: "Try removing the field.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the value of the `flutter` key
  // isn't a map.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the value of the
  // top-level `flutter` key is a string:
  //
  // ```yaml
  // %uri="pubspec.yaml"
  // name: example
  // flutter: true
  // ```
  //
  // #### Common fixes
  //
  // If you need to specify Flutter-specific options, then change the value to
  // be a map:
  //
  // ```yaml
  // %uri="pubspec.yaml"
  // name: example
  // flutter:
  //   uses-material-design: true
  // ```
  //
  // If you don't need to specify Flutter-specific options, then remove the
  // `flutter` key:
  //
  // ```yaml
  // %uri="pubspec.yaml"
  // name: example
  // ```
  static const PubspecWarningCode FLUTTER_FIELD_NOT_MAP = PubspecWarningCode(
    'FLUTTER_FIELD_NOT_MAP',
    "The value of the 'flutter' field is expected to be a map.",
    correctionMessage: "Try converting the value to be a map.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the kind of dependency.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a package under either
  // `dependencies` or `dev_dependencies` isn't a pub, `git`, or `path` based
  // dependency.
  //
  // See [Package dependencies](https://dart.dev/tools/pub/dependencies) for
  // more information about the kind of dependencies that are supported.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the dependency on the
  // package `transmogrify` isn't a pub, `git`, or `path` based dependency:
  //
  // ```yaml
  // %uri="pubspec.yaml"
  // name: example
  // dependencies:
  //   transmogrify:
  //     hosted:
  //       name: transmogrify
  //       url: http://your-package-server.com
  //     version: ^1.4.0
  // ```
  //
  // #### Common fixes
  //
  // If you want to publish your package to `pub.dev`, then change the
  // dependencies to ones that are supported by `pub`.
  //
  // If you don't want to publish your package to `pub.dev`, then add a
  // `publish_to: none` entry to mark the package as one that isn't intended to
  // be published:
  //
  // ```yaml
  // %uri="pubspec.yaml"
  // name: example
  // publish_to: none
  // dependencies:
  //   transmogrify:
  //     hosted:
  //       name: transmogrify
  //       url: http://your-package-server.com
  //     version: ^1.4.0
  // ```
  static const PubspecWarningCode INVALID_DEPENDENCY = PubspecWarningCode(
    'INVALID_DEPENDENCY',
    "Publishable packages can't have '{0}' dependencies.",
    correctionMessage:
        "Try adding a 'publish_to: none' entry to mark the package as not for publishing or remove the {0} dependency.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when there's no top-level `name` key.
  // The `name` key provides the name of the package, which is required.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the package doesn't
  // have a name:
  //
  // ```yaml
  // %uri="pubspec.yaml"
  // dependencies:
  //   meta: ^1.0.2
  // ```
  //
  // #### Common fixes
  //
  // Add the top-level key `name` with a value that's the name of the package:
  //
  // ```yaml
  // %uri="pubspec.yaml"
  // name: example
  // dependencies:
  //   meta: ^1.0.2
  // ```
  static const PubspecWarningCode MISSING_NAME = PubspecWarningCode(
    'MISSING_NAME',
    "The 'name' field is required but missing.",
    correctionMessage: "Try adding a field named 'name'.",
    hasPublishedDocs: true,
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the top-level `name` key has a
  // value that isn't a string.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the value following the
  // `name` key is a list:
  //
  // ```yaml
  // %uri="pubspec.yaml"
  // name:
  //   - example
  // ```
  //
  // #### Common fixes
  //
  // Replace the value with a string:
  //
  // ```yaml
  // %uri="pubspec.yaml"
  // name: example
  // ```
  static const PubspecWarningCode NAME_NOT_STRING = PubspecWarningCode(
    'NAME_NOT_STRING',
    "The value of the 'name' field is required to be a string.",
    correctionMessage: "Try converting the value to be a string.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the path to the dependency as given in the file.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a dependency has a `path` key
  // referencing a directory that doesn't exist.
  //
  // #### Example
  //
  // Assuming that the directory `doesNotExist` doesn't exist, the following
  // code produces this diagnostic because it's listed as the path of a package:
  //
  // ```yaml
  // %uri="pubspec.yaml"
  // name: example
  // dependencies:
  //   local_package:
  //     path: doesNotExist
  // ```
  //
  // #### Common fixes
  //
  // If the path is correct, then create a directory at that path.
  //
  // If the path isn't correct, then change the path to match the path to the
  // root of the package.
  static const PubspecWarningCode PATH_DOES_NOT_EXIST = PubspecWarningCode(
    'PATH_DOES_NOT_EXIST',
    "The path '{0}' doesn't exist.",
    correctionMessage:
        "Try creating the referenced path or using a path that exists.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the path as given in the file.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a dependency has a `path` key
  // whose value is a string, but isn't a POSIX-style path.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the path following the
  // `path` key is a Windows path:
  //
  // ```yaml
  // %uri="pubspec.yaml"
  // name: example
  // dependencies:
  //   local_package:
  //     path: E:\local_package
  // ```
  //
  // #### Common fixes
  //
  // Convert the path to a POSIX path.
  static const PubspecWarningCode PATH_NOT_POSIX = PubspecWarningCode(
    'PATH_NOT_POSIX',
    "The path '{0}' isn't a POSIX-style path.",
    correctionMessage: "Try converting the value to a POSIX-style path.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the path to the dependency as given in the file.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a dependency has a `path` key
  // that references a directory that doesn't contain a `pubspec.yaml` file.
  //
  // #### Example
  //
  // Assuming that the directory `local_package` doesn't contain a file named
  // `pubspec.yaml`, the following code produces this diagnostic because it's
  // listed as the path of a package:
  //
  // ```yaml
  // %uri="pubspec.yaml"
  // name: example
  // dependencies:
  //   local_package:
  //     path: local_package
  // ```
  //
  // #### Common fixes
  //
  // If the path is intended to be the root of a package, then add a
  // `pubspec.yaml` file in the directory:
  //
  // ```yaml
  // %uri="pubspec.yaml"
  // name: local_package
  // ```
  //
  // If the path is wrong, then replace it with a the correct path.
  static const PubspecWarningCode PATH_PUBSPEC_DOES_NOT_EXIST =
      PubspecWarningCode(
    'PATH_PUBSPEC_DOES_NOT_EXIST',
    "The directory '{0}' doesn't contain a pubspec.",
    correctionMessage:
        "Try creating a pubspec in the referenced directory or using a path that has a pubspec.",
    hasPublishedDocs: true,
  );

  /**
   * Parameters:
   * 0: the name of the package in the dev_dependency list.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when there's an entry under
  // `dev_dependencies` for a package that is also listed under `dependencies`.
  // The packages under `dependencies` are available to all of the code in the
  // package, so there's no need to also list them under `dev_dependencies`.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the package `meta` is
  // listed under both `dependencies` and `dev_dependencies`:
  //
  // ```yaml
  // %uri="pubspec.yaml"
  // name: example
  // dependencies:
  //   meta: ^1.0.2
  // dev_dependencies:
  //   meta: ^1.0.2
  // ```
  //
  // #### Common fixes
  //
  // Remove the entry under `dev_dependencies` (and the `dev_dependencies` key
  // if that's the only package listed there):
  //
  // ```yaml
  // %uri="pubspec.yaml"
  // name: example
  // dependencies:
  //   meta: ^1.0.2
  // ```
  static const PubspecWarningCode UNNECESSARY_DEV_DEPENDENCY =
      PubspecWarningCode(
    'UNNECESSARY_DEV_DEPENDENCY',
    "The dev dependency on {0} is unnecessary because there is also a normal dependency on that package.",
    correctionMessage: "Try removing the dev dependency.",
    hasPublishedDocs: true,
  );

  /// Initialize a newly created error code to have the given [name].
  const PubspecWarningCode(
    String name,
    String problemMessage, {
    String? correctionMessage,
    bool hasPublishedDocs = false,
    bool isUnresolvedIdentifier = false,
    String? uniqueName,
  }) : super(
          correctionMessage: correctionMessage,
          hasPublishedDocs: hasPublishedDocs,
          isUnresolvedIdentifier: isUnresolvedIdentifier,
          name: name,
          problemMessage: problemMessage,
          uniqueName: 'PubspecWarningCode.${uniqueName ?? name}',
        );

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.WARNING;

  @override
  ErrorType get type => ErrorType.STATIC_WARNING;
}
