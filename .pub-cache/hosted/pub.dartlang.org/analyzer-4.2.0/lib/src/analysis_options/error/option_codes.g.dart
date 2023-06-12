// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/analyzer/messages.yaml' and run
// 'dart run pkg/analyzer/tool/messages/generate.dart' to update.

import "package:analyzer/error/error.dart";

class AnalysisOptionsErrorCode extends ErrorCode {
  ///  An error code indicating that there is a syntactic error in the included
  ///  file.
  ///
  ///  Parameters:
  ///  0: the path of the file containing the error
  ///  1: the starting offset of the text in the file that contains the error
  ///  2: the ending offset of the text in the file that contains the error
  ///  3: the error message
  static const AnalysisOptionsErrorCode INCLUDED_FILE_PARSE_ERROR =
      AnalysisOptionsErrorCode(
    'INCLUDED_FILE_PARSE_ERROR',
    "{3} in {0}({1}..{2})",
  );

  ///  An error code indicating that there is a syntactic error in the file.
  ///
  ///  Parameters:
  ///  0: the error message from the parse error
  static const AnalysisOptionsErrorCode PARSE_ERROR = AnalysisOptionsErrorCode(
    'PARSE_ERROR',
    "{0}",
  );

  /// Initialize a newly created error code to have the given [name].
  const AnalysisOptionsErrorCode(
    String name,
    String problemMessage, {
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    String? uniqueName,
  }) : super(
          name: name,
          problemMessage: problemMessage,
          uniqueName: 'AnalysisOptionsErrorCode.${uniqueName ?? name}',
        );

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.ERROR;

  @override
  ErrorType get type => ErrorType.COMPILE_TIME_ERROR;
}

class AnalysisOptionsHintCode extends ErrorCode {
  ///  An error code indicating that the enablePreviewDart2 setting is
  ///  deprecated.
  static const AnalysisOptionsHintCode PREVIEW_DART_2_SETTING_DEPRECATED =
      AnalysisOptionsHintCode(
    'PREVIEW_DART_2_SETTING_DEPRECATED',
    "The 'enablePreviewDart2' setting is deprecated.",
    correctionMessage: "It is no longer necessary to explicitly enable Dart 2.",
  );

  ///  An error code indicating that strong-mode: true is deprecated.
  static const AnalysisOptionsHintCode STRONG_MODE_SETTING_DEPRECATED =
      AnalysisOptionsHintCode(
    'STRONG_MODE_SETTING_DEPRECATED',
    "The 'strong-mode: true' setting is deprecated.",
    correctionMessage:
        "It is no longer necessary to explicitly enable strong mode.",
  );

  ///  An error code indicating that the enablePreviewDart2 setting is
  ///  deprecated.
  static const AnalysisOptionsHintCode SUPER_MIXINS_SETTING_DEPRECATED =
      AnalysisOptionsHintCode(
    'SUPER_MIXINS_SETTING_DEPRECATED',
    "The 'enableSuperMixins' setting is deprecated.",
    correctionMessage:
        "Support has been added to the language for 'mixin' based mixins.",
  );

  /// Initialize a newly created error code to have the given [name].
  const AnalysisOptionsHintCode(
    String name,
    String problemMessage, {
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    String? uniqueName,
  }) : super(
          name: name,
          problemMessage: problemMessage,
          uniqueName: 'AnalysisOptionsHintCode.${uniqueName ?? name}',
        );

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.INFO;

  @override
  ErrorType get type => ErrorType.HINT;
}

class AnalysisOptionsWarningCode extends ErrorCode {
  ///  An error code indicating that the given option is deprecated.
  static const AnalysisOptionsWarningCode ANALYSIS_OPTION_DEPRECATED =
      AnalysisOptionsWarningCode(
    'ANALYSIS_OPTION_DEPRECATED',
    "The option '{0}' is no longer supported.",
  );

  ///  An error code indicating a specified include file has a warning.
  ///
  ///  Parameters:
  ///  0: the path of the file containing the warnings
  ///  1: the starting offset of the text in the file that contains the warning
  ///  2: the ending offset of the text in the file that contains the warning
  ///  3: the warning message
  static const AnalysisOptionsWarningCode INCLUDED_FILE_WARNING =
      AnalysisOptionsWarningCode(
    'INCLUDED_FILE_WARNING',
    "Warning in the included options file {0}({1}..{2}): {3}",
  );

  ///  An error code indicating a specified include file could not be found.
  ///
  ///  Parameters:
  ///  0: the uri of the file to be included
  ///  1: the path of the file containing the include directive
  ///  2: the path of the context being analyzed
  static const AnalysisOptionsWarningCode INCLUDE_FILE_NOT_FOUND =
      AnalysisOptionsWarningCode(
    'INCLUDE_FILE_NOT_FOUND',
    "The include file '{0}' in '{1}' can't be found when analyzing '{2}'.",
  );

  ///  An error code indicating that a plugin is being configured with an invalid
  ///  value for an option and a detail message is provided.
  static const AnalysisOptionsWarningCode INVALID_OPTION =
      AnalysisOptionsWarningCode(
    'INVALID_OPTION',
    "Invalid option specified for '{0}': {1}",
  );

  ///  An error code indicating an invalid format for an options file section.
  ///
  ///  Parameters:
  ///  0: the section name
  static const AnalysisOptionsWarningCode INVALID_SECTION_FORMAT =
      AnalysisOptionsWarningCode(
    'INVALID_SECTION_FORMAT',
    "Invalid format for the '{0}' section.",
  );

  ///  An error code indicating that strong-mode: false is has been removed.
  static const AnalysisOptionsWarningCode SPEC_MODE_REMOVED =
      AnalysisOptionsWarningCode(
    'SPEC_MODE_REMOVED',
    "The option 'strong-mode: false' is no longer supported.",
    correctionMessage:
        "It's recommended to remove the 'strong-mode:' setting (and make your "
        "code Dart 2 compliant).",
  );

  ///  An error code indicating that an unrecognized error code is being used to
  ///  specify an error filter.
  ///
  ///  Parameters:
  ///  0: the unrecognized error code
  static const AnalysisOptionsWarningCode UNRECOGNIZED_ERROR_CODE =
      AnalysisOptionsWarningCode(
    'UNRECOGNIZED_ERROR_CODE',
    "'{0}' isn't a recognized error code.",
  );

  ///  An error code indicating that a plugin is being configured with an
  ///  unsupported option and legal options are provided.
  ///
  ///  Parameters:
  ///  0: the plugin name
  ///  1: the unsupported option key
  static const AnalysisOptionsWarningCode UNSUPPORTED_OPTION_WITHOUT_VALUES =
      AnalysisOptionsWarningCode(
    'UNSUPPORTED_OPTION_WITHOUT_VALUES',
    "The option '{1}' isn't supported by '{0}'.",
  );

  ///  An error code indicating that a plugin is being configured with an
  ///  unsupported option where there is just one legal value.
  ///
  ///  Parameters:
  ///  0: the plugin name
  ///  1: the unsupported option key
  ///  2: the legal value
  static const AnalysisOptionsWarningCode UNSUPPORTED_OPTION_WITH_LEGAL_VALUE =
      AnalysisOptionsWarningCode(
    'UNSUPPORTED_OPTION_WITH_LEGAL_VALUE',
    "The option '{1}' isn't supported by '{0}'. Try using the only supported "
        "option: '{2}'.",
  );

  ///  An error code indicating that a plugin is being configured with an
  ///  unsupported option and legal options are provided.
  ///
  ///  Parameters:
  ///  0: the plugin name
  ///  1: the unsupported option key
  ///  2: legal values
  static const AnalysisOptionsWarningCode UNSUPPORTED_OPTION_WITH_LEGAL_VALUES =
      AnalysisOptionsWarningCode(
    'UNSUPPORTED_OPTION_WITH_LEGAL_VALUES',
    "The option '{1}' isn't supported by '{0}'.",
    correctionMessage: "Try using one of the supported options: {2}.",
  );

  ///  An error code indicating that an option entry is being configured with an
  ///  unsupported value.
  ///
  ///  Parameters:
  ///  0: the option name
  ///  1: the unsupported value
  ///  2: legal values
  static const AnalysisOptionsWarningCode UNSUPPORTED_VALUE =
      AnalysisOptionsWarningCode(
    'UNSUPPORTED_VALUE',
    "The value '{1}' isn't supported by '{0}'.",
    correctionMessage: "Try using one of the supported options: {2}.",
  );

  /// Initialize a newly created error code to have the given [name].
  const AnalysisOptionsWarningCode(
    String name,
    String problemMessage, {
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    String? uniqueName,
  }) : super(
          name: name,
          problemMessage: problemMessage,
          uniqueName: 'AnalysisOptionsWarningCode.${uniqueName ?? name}',
        );

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.WARNING;

  @override
  ErrorType get type => ErrorType.STATIC_WARNING;
}
