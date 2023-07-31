// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/analyzer/messages.yaml' and run
// 'dart run pkg/analyzer/tool/messages/generate.dart' to update.

// We allow some snake_case and SCREAMING_SNAKE_CASE identifiers in generated
// code, as they match names declared in the source configuration files.
// ignore_for_file: constant_identifier_names

import "package:analyzer/error/error.dart";

class PubspecWarningCode extends ErrorCode {
  ///  Parameters:
  ///  0: the path to the asset directory as given in the file.
  static const PubspecWarningCode ASSET_DIRECTORY_DOES_NOT_EXIST =
      PubspecWarningCode(
    'ASSET_DIRECTORY_DOES_NOT_EXIST',
    "The asset directory '{0}' doesn't exist.",
    correctionMessage:
        "Try creating the directory or fixing the path to the directory.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the path to the asset as given in the file.
  static const PubspecWarningCode ASSET_DOES_NOT_EXIST = PubspecWarningCode(
    'ASSET_DOES_NOT_EXIST',
    "The asset file '{0}' doesn't exist.",
    correctionMessage: "Try creating the file or fixing the path to the file.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const PubspecWarningCode ASSET_FIELD_NOT_LIST = PubspecWarningCode(
    'ASSET_FIELD_NOT_LIST',
    "The value of the 'asset' field is expected to be a list of relative file "
        "paths.",
    correctionMessage:
        "Try converting the value to be a list of relative file paths.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const PubspecWarningCode ASSET_NOT_STRING = PubspecWarningCode(
    'ASSET_NOT_STRING',
    "Assets are required to be file paths (strings).",
    correctionMessage: "Try converting the value to be a string.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the field
  static const PubspecWarningCode DEPENDENCIES_FIELD_NOT_MAP =
      PubspecWarningCode(
    'DEPENDENCIES_FIELD_NOT_MAP',
    "The value of the '{0}' field is expected to be a map.",
    correctionMessage: "Try converting the value to be a map.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the field
  static const PubspecWarningCode DEPRECATED_FIELD = PubspecWarningCode(
    'DEPRECATED_FIELD',
    "The '{0}' field is no longer used and can be removed.",
    correctionMessage: "Try removing the field.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const PubspecWarningCode FLUTTER_FIELD_NOT_MAP = PubspecWarningCode(
    'FLUTTER_FIELD_NOT_MAP',
    "The value of the 'flutter' field is expected to be a map.",
    correctionMessage: "Try converting the value to be a map.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the kind of dependency.
  static const PubspecWarningCode INVALID_DEPENDENCY = PubspecWarningCode(
    'INVALID_DEPENDENCY',
    "Publishable packages can't have '{0}' dependencies.",
    correctionMessage:
        "Try adding a 'publish_to: none' entry to mark the package as not for "
        "publishing or remove the {0} dependency.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const PubspecWarningCode MISSING_NAME = PubspecWarningCode(
    'MISSING_NAME',
    "The 'name' field is required but missing.",
    correctionMessage: "Try adding a field named 'name'.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const PubspecWarningCode NAME_NOT_STRING = PubspecWarningCode(
    'NAME_NOT_STRING',
    "The value of the 'name' field is required to be a string.",
    correctionMessage: "Try converting the value to be a string.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the path to the dependency as given in the file.
  static const PubspecWarningCode PATH_DOES_NOT_EXIST = PubspecWarningCode(
    'PATH_DOES_NOT_EXIST',
    "The path '{0}' doesn't exist.",
    correctionMessage:
        "Try creating the referenced path or using a path that exists.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the path as given in the file.
  static const PubspecWarningCode PATH_NOT_POSIX = PubspecWarningCode(
    'PATH_NOT_POSIX',
    "The path '{0}' isn't a POSIX-style path.",
    correctionMessage: "Try converting the value to a POSIX-style path.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the path to the dependency as given in the file.
  static const PubspecWarningCode PATH_PUBSPEC_DOES_NOT_EXIST =
      PubspecWarningCode(
    'PATH_PUBSPEC_DOES_NOT_EXIST',
    "The directory '{0}' doesn't contain a pubspec.",
    correctionMessage:
        "Try creating a pubspec in the referenced directory or using a path "
        "that has a pubspec.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the package in the dev_dependency list.
  static const PubspecWarningCode UNNECESSARY_DEV_DEPENDENCY =
      PubspecWarningCode(
    'UNNECESSARY_DEV_DEPENDENCY',
    "The dev dependency on {0} is unnecessary because there is also a normal "
        "dependency on that package.",
    correctionMessage: "Try removing the dev dependency.",
    hasPublishedDocs: true,
  );

  /// Initialize a newly created error code to have the given [name].
  const PubspecWarningCode(
    String name,
    String problemMessage, {
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    String? uniqueName,
  }) : super(
          name: name,
          problemMessage: problemMessage,
          uniqueName: 'PubspecWarningCode.${uniqueName ?? name}',
        );

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.WARNING;

  @override
  ErrorType get type => ErrorType.STATIC_WARNING;
}
