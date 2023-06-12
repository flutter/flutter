// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:analyzer_utilities/package_root.dart' as pkg_root;
import 'package:path/path.dart';
import 'package:yaml/yaml.dart' show loadYaml;

/// Information about all the classes derived from `ErrorCode` that are code
/// generated based on the contents of the analyzer and front end
/// `messages.yaml` files.
const List<ErrorClassInfo> errorClasses = [
  ErrorClassInfo(
      filePath: 'lib/src/analysis_options/error/option_codes.g.dart',
      name: 'AnalysisOptionsErrorCode',
      type: 'COMPILE_TIME_ERROR',
      severity: 'ERROR'),
  ErrorClassInfo(
      filePath: 'lib/src/analysis_options/error/option_codes.g.dart',
      name: 'AnalysisOptionsHintCode',
      type: 'HINT',
      severity: 'INFO'),
  ErrorClassInfo(
      filePath: 'lib/src/analysis_options/error/option_codes.g.dart',
      name: 'AnalysisOptionsWarningCode',
      type: 'STATIC_WARNING',
      severity: 'WARNING'),
  ErrorClassInfo(
      filePath: 'lib/src/error/codes.g.dart',
      name: 'CompileTimeErrorCode',
      superclass: 'AnalyzerErrorCode',
      type: 'COMPILE_TIME_ERROR',
      extraImports: ['package:analyzer/src/error/analyzer_error_code.dart']),
  ErrorClassInfo(
      filePath: 'lib/src/error/codes.g.dart',
      name: 'LanguageCode',
      type: 'COMPILE_TIME_ERROR'),
  ErrorClassInfo(
      filePath: 'lib/src/error/codes.g.dart',
      name: 'StaticWarningCode',
      superclass: 'AnalyzerErrorCode',
      type: 'STATIC_WARNING',
      severity: 'WARNING',
      extraImports: ['package:analyzer/src/error/analyzer_error_code.dart']),
  ErrorClassInfo(
      filePath: 'lib/src/dart/error/ffi_code.g.dart',
      name: 'FfiCode',
      superclass: 'AnalyzerErrorCode',
      type: 'COMPILE_TIME_ERROR',
      extraImports: ['package:analyzer/src/error/analyzer_error_code.dart']),
  ErrorClassInfo(
      filePath: 'lib/src/dart/error/hint_codes.g.dart',
      name: 'HintCode',
      superclass: 'AnalyzerErrorCode',
      type: 'HINT',
      extraImports: ['package:analyzer/src/error/analyzer_error_code.dart']),
  ErrorClassInfo(
      filePath: 'lib/src/dart/error/syntactic_errors.g.dart',
      name: 'ParserErrorCode',
      type: 'SYNTACTIC_ERROR',
      severity: 'ERROR',
      includeCfeMessages: true),
  ErrorClassInfo(
      filePath: 'lib/src/manifest/manifest_warning_code.g.dart',
      name: 'ManifestWarningCode',
      type: 'STATIC_WARNING',
      severity: 'WARNING'),
  ErrorClassInfo(
      filePath: 'lib/src/pubspec/pubspec_warning_code.g.dart',
      name: 'PubspecWarningCode',
      type: 'STATIC_WARNING',
      severity: 'WARNING'),
];

/// Decoded messages from the analyzer's `messages.yaml` file.
final Map<String, Map<String, AnalyzerErrorCodeInfo>> analyzerMessages =
    _loadAnalyzerMessages();

/// The path to the `analyzer` package.
final String analyzerPkgPath =
    normalize(join(pkg_root.packageRoot, 'analyzer'));

/// A set of tables mapping between front end and analyzer error codes.
final CfeToAnalyzerErrorCodeTables cfeToAnalyzerErrorCodeTables =
    CfeToAnalyzerErrorCodeTables._(frontEndMessages);

/// Decoded messages from the front end's `messages.yaml` file.
final Map<String, FrontEndErrorCodeInfo> frontEndMessages =
    _loadFrontEndMessages();

/// The path to the `front_end` package.
final String frontEndPkgPath =
    normalize(join(pkg_root.packageRoot, 'front_end'));

/// Pattern used by the front end to identify placeholders in error message
/// strings.  TODO(paulberry): share this regexp (and the code for interpreting
/// it) between the CFE and analyzer.
final RegExp _placeholderPattern =
    RegExp("#([-a-zA-Z0-9_]+)(?:%([0-9]*).([0-9]+))?");

/// Convert a CFE template string (which uses placeholders like `#string`) to
/// an analyzer template string (which uses placeholders like `{0}`).
String convertTemplate(Map<String, int> placeholderToIndexMap, String entry) {
  return entry.replaceAllMapped(_placeholderPattern,
      (match) => '{${placeholderToIndexMap[match.group(0)!]}}');
}

/// Decodes a YAML object (obtained from `pkg/analyzer/messages.yaml`) into a
/// two-level map of [ErrorCodeInfo], indexed first by class name and then by
/// error name.
Map<String, Map<String, AnalyzerErrorCodeInfo>> decodeAnalyzerMessagesYaml(
    Object? yaml) {
  Never problem(String message) {
    throw 'Problem in pkg/analyzer/messages.yaml: $message';
  }

  var result = <String, Map<String, AnalyzerErrorCodeInfo>>{};
  if (yaml is! Map<Object?, Object?>) {
    problem('root node is not a map');
  }
  for (var classEntry in yaml.entries) {
    var className = classEntry.key;
    if (className is! String) {
      problem('non-string class key ${json.encode(className)}');
    }
    var classValue = classEntry.value;
    if (classValue is! Map<Object?, Object?>) {
      problem('value associated with class key $className is not a map');
    }
    for (var errorEntry in classValue.entries) {
      var errorName = errorEntry.key;
      if (errorName is! String) {
        problem('in class $className, non-string error key '
            '${json.encode(errorName)}');
      }
      var errorValue = errorEntry.value;
      if (errorValue is! Map<Object?, Object?>) {
        problem('value associated with error $className.$errorName is not a '
            'map');
      }
      try {
        (result[className] ??= {})[errorName] =
            AnalyzerErrorCodeInfo.fromYaml(errorValue);
      } catch (e) {
        problem('while processing '
            '$className.$errorName, $e');
      }
    }
  }
  return result;
}

/// Decodes a YAML object (obtained from `pkg/front_end/messages.yaml`) into a
/// map from error name to [ErrorCodeInfo].
Map<String, FrontEndErrorCodeInfo> decodeCfeMessagesYaml(Object? yaml) {
  Never problem(String message) {
    throw 'Problem in pkg/front_end/messages.yaml: $message';
  }

  var result = <String, FrontEndErrorCodeInfo>{};
  if (yaml is! Map<Object?, Object?>) {
    problem('root node is not a map');
  }
  for (var entry in yaml.entries) {
    var errorName = entry.key;
    if (errorName is! String) {
      problem('non-string error key ${json.encode(errorName)}');
    }
    var errorValue = entry.value;
    if (errorValue is! Map<Object?, Object?>) {
      problem('value associated with error $errorName is not a map');
    }
    result[errorName] = FrontEndErrorCodeInfo.fromYaml(errorValue);
  }
  return result;
}

/// Loads analyzer messages from the analyzer's `messages.yaml` file.
Map<String, Map<String, AnalyzerErrorCodeInfo>> _loadAnalyzerMessages() {
  Object? messagesYaml =
      loadYaml(File(join(analyzerPkgPath, 'messages.yaml')).readAsStringSync());
  return decodeAnalyzerMessagesYaml(messagesYaml);
}

/// Loads front end messages from the front end's `messages.yaml` file.
Map<String, FrontEndErrorCodeInfo> _loadFrontEndMessages() {
  Object? messagesYaml =
      loadYaml(File(join(frontEndPkgPath, 'messages.yaml')).readAsStringSync());
  return decodeCfeMessagesYaml(messagesYaml);
}

/// Splits [text] on spaces using the given [maxWidth] (and [firstLineWidth] if
/// given).
List<String> _splitText(
  String text, {
  required int maxWidth,
  int? firstLineWidth,
}) {
  firstLineWidth ??= maxWidth;
  var lines = <String>[];
  // The character width to use as a maximum width. This starts as
  // [firstLineWidth] but becomes [maxWidth] on every iteration after the first.
  var width = firstLineWidth;
  var lineMaxEndIndex = width;
  var lineStartIndex = 0;

  while (true) {
    if (lineMaxEndIndex >= text.length) {
      lines.add(text.substring(lineStartIndex, text.length));
      break;
    } else {
      var lastSpaceIndex = text.lastIndexOf(' ', lineMaxEndIndex);
      if (lastSpaceIndex == -1 || lastSpaceIndex <= lineStartIndex) {
        // No space between [lineStartIndex] and [lineMaxEndIndex]. Get the
        // _next_ space.
        lastSpaceIndex = text.indexOf(' ', lineMaxEndIndex);
        if (lastSpaceIndex == -1) {
          // No space at all after [lineStartIndex].
          lines.add(text.substring(lineStartIndex));
          break;
        }
      }
      lines.add(text.substring(lineStartIndex, lastSpaceIndex + 1));
      lineStartIndex = lastSpaceIndex + 1;
      width = maxWidth;
    }
    lineMaxEndIndex = lineStartIndex + maxWidth;
  }
  return lines;
}

/// In-memory representation of error code information obtained from the
/// analyzer's `messages.yaml` file.
class AnalyzerErrorCodeInfo extends ErrorCodeInfo {
  AnalyzerErrorCodeInfo(
      {super.comment,
      super.correctionMessage,
      super.documentation,
      super.hasPublishedDocs,
      super.isUnresolvedIdentifier,
      required super.problemMessage,
      super.sharedName});

  AnalyzerErrorCodeInfo.fromYaml(super.yaml) : super.fromYaml();
}

/// Data tables mapping between CFE errors and their corresponding automatically
/// generated analyzer errors.
class CfeToAnalyzerErrorCodeTables {
  /// List of CFE errors for which analyzer errors should be automatically
  /// generated, organized by their `index` property.
  final List<ErrorCodeInfo?> indexToInfo = [];

  /// Map whose values are the CFE errors for which analyzer errors should be
  /// automatically generated, and whose keys are the corresponding analyzer
  /// error name.  (Names are simple identifiers; they are not prefixed by the
  /// class name `ParserErrorCode`)
  final Map<String, ErrorCodeInfo> analyzerCodeToInfo = {};

  /// Map whose values are the CFE errors for which analyzer errors should be
  /// automatically generated, and whose keys are the front end error name.
  final Map<String, ErrorCodeInfo> frontEndCodeToInfo = {};

  /// Map whose keys are the CFE errors for which analyzer errors should be
  /// automatically generated, and whose values are the corresponding analyzer
  /// error name.  (Names are simple identifiers; they are not prefixed by the
  /// class name `ParserErrorCode`)
  final Map<ErrorCodeInfo, String> infoToAnalyzerCode = {};

  /// Map whose keys are the CFE errors for which analyzer errors should be
  /// automatically generated, and whose values are the front end error name.
  final Map<ErrorCodeInfo, String> infoToFrontEndCode = {};

  CfeToAnalyzerErrorCodeTables._(Map<String, FrontEndErrorCodeInfo> messages) {
    for (var entry in messages.entries) {
      var errorCodeInfo = entry.value;
      var index = errorCodeInfo.index;
      if (index == null || errorCodeInfo.analyzerCode.length != 1) {
        continue;
      }
      var frontEndCode = entry.key;
      if (index < 1) {
        throw '''
$frontEndCode specifies index $index but indices must be 1 or greater.
For more information run:
pkg/front_end/tool/fasta generate-messages
''';
      }
      if (indexToInfo.length <= index) {
        indexToInfo.length = index + 1;
      }
      var previousEntryForIndex = indexToInfo[index];
      if (previousEntryForIndex != null) {
        throw 'Index $index used by both '
            '${infoToFrontEndCode[previousEntryForIndex]} and $frontEndCode';
      }
      indexToInfo[index] = errorCodeInfo;
      frontEndCodeToInfo[frontEndCode] = errorCodeInfo;
      infoToFrontEndCode[errorCodeInfo] = frontEndCode;
      var analyzerCodeLong = errorCodeInfo.analyzerCode.single;
      var expectedPrefix = 'ParserErrorCode.';
      if (!analyzerCodeLong.startsWith(expectedPrefix)) {
        throw 'Expected all analyzer error codes to be prefixed with '
            '${json.encode(expectedPrefix)}.  Found '
            '${json.encode(analyzerCodeLong)}.';
      }
      var analyzerCode = analyzerCodeLong.substring(expectedPrefix.length);
      infoToAnalyzerCode[errorCodeInfo] = analyzerCode;
      var previousEntryForAnalyzerCode = analyzerCodeToInfo[analyzerCode];
      if (previousEntryForAnalyzerCode != null) {
        throw 'Analyzer code $analyzerCode used by both '
            '${infoToFrontEndCode[previousEntryForAnalyzerCode]} and '
            '$frontEndCode';
      }
      analyzerCodeToInfo[analyzerCode] = errorCodeInfo;
    }
    for (int i = 1; i < indexToInfo.length; i++) {
      if (indexToInfo[i] == null) {
        throw 'Indices are not consecutive; no error code has index $i.';
      }
    }
  }
}

/// Information about a code generated class derived from `ErrorCode`.
class ErrorClassInfo {
  /// A list of additional import URIs that are needed by the code generated
  /// for this class.
  final List<String> extraImports;

  /// The file path (relative to the root of `pkg/analyzer`) of the generated
  /// file containing this class.
  final String filePath;

  /// True if this class should contain error messages extracted from the front
  /// end's `messages.yaml` file.
  ///
  /// Note: at the moment we only support extracting front end error messages to
  /// a single error class.
  final bool includeCfeMessages;

  /// The name of this class.
  final String name;

  /// The severity of errors in this class, or `null` if the severity should be
  /// based on the [type] of the error.
  final String? severity;

  /// The superclass of this class.
  final String superclass;

  /// The type of errors in this class.
  final String type;

  const ErrorClassInfo(
      {this.extraImports = const [],
      required this.filePath,
      this.includeCfeMessages = false,
      required this.name,
      this.severity,
      this.superclass = 'ErrorCode',
      required this.type});

  /// Generates the code to compute the severity of errors of this class.
  String get severityCode {
    var severity = this.severity;
    if (severity == null) {
      return '$typeCode.severity';
    } else {
      return 'ErrorSeverity.$severity';
    }
  }

  /// Generates the code to compute the type of errors of this class.
  String get typeCode => 'ErrorType.$type';
}

/// In-memory representation of error code information obtained from either the
/// analyzer or the front end's `messages.yaml` file.  This class contains the
/// common functionality supported by both formats.
abstract class ErrorCodeInfo {
  /// If present, a documentation comment that should be associated with the
  /// error in code generated output.
  final String? comment;

  /// If the error code has an associated correctionMessage, the template for
  /// it.
  final String? correctionMessage;

  /// If present, user-facing documentation for the error.
  final String? documentation;

  /// `true` if diagnostics with this code have documentation for them that has
  /// been published.
  final bool hasPublishedDocs;

  /// Indicates whether this error is caused by an unresolved identifier.
  final bool isUnresolvedIdentifier;

  /// The problemMessage for the error code.
  final String problemMessage;

  /// If present, indicates that this error code has a special name for
  /// presentation to the user, that is potentially shared with other error
  /// codes.
  final String? sharedName;

  /// If present, indicates that this error code has been renamed from
  /// [previousName] to its current name (or [sharedName]).
  final String? previousName;

  ErrorCodeInfo(
      {this.comment,
      this.documentation,
      this.hasPublishedDocs = false,
      this.isUnresolvedIdentifier = false,
      this.sharedName,
      required this.problemMessage,
      this.correctionMessage,
      this.previousName});

  /// Decodes an [ErrorCodeInfo] object from its YAML representation.
  ErrorCodeInfo.fromYaml(Map<Object?, Object?> yaml)
      : this(
            comment: yaml['comment'] as String?,
            correctionMessage: yaml['correctionMessage'] as String?,
            documentation: yaml['documentation'] as String?,
            hasPublishedDocs: yaml['hasPublishedDocs'] as bool? ?? false,
            isUnresolvedIdentifier:
                yaml['isUnresolvedIdentifier'] as bool? ?? false,
            problemMessage: yaml['problemMessage'] as String,
            sharedName: yaml['sharedName'] as String?,
            previousName: yaml['previousName'] as String?);

  /// Given a messages.yaml entry, come up with a mapping from placeholder
  /// patterns in its message strings to their corresponding indices.
  Map<String, int> computePlaceholderToIndexMap() {
    var mapping = <String, int>{};
    for (var value in [problemMessage, correctionMessage]) {
      if (value is! String) continue;
      for (Match match in _placeholderPattern.allMatches(value)) {
        // CFE supports a bunch of formatting options that analyzer doesn't;
        // make sure none of those are used.
        if (match.group(0) != '#${match.group(1)}') {
          throw 'Template string ${json.encode(value)} contains unsupported '
              'placeholder pattern ${json.encode(match.group(0))}';
        }

        mapping[match.group(0)!] ??= mapping.length;
      }
    }
    return mapping;
  }

  /// Generates a dart declaration for this error code, suitable for inclusion
  /// in the error class [className].  [errorCode] is the name of the error code
  /// to be generated.
  String toAnalyzerCode(String className, String errorCode) {
    var out = StringBuffer();
    out.writeln('$className(');
    out.writeln("'${sharedName ?? errorCode}',");
    var maxWidth = 80 - 8 /* indentation */ - 2 /* quotes */ - 1 /* comma */;
    final placeholderToIndexMap = computePlaceholderToIndexMap();
    var messageAsCode = convertTemplate(placeholderToIndexMap, problemMessage);
    var messageLines = _splitText(messageAsCode,
        maxWidth: maxWidth, firstLineWidth: maxWidth + 4);
    out.writeln('${messageLines.map(json.encode).join('\n')},');
    final correctionMessage = this.correctionMessage;
    if (correctionMessage is String) {
      out.write('correctionMessage: ');
      var code = convertTemplate(placeholderToIndexMap, correctionMessage);
      var codeLines = _splitText(code, maxWidth: maxWidth);
      out.writeln('${codeLines.map(json.encode).join('\n')},');
    }
    if (hasPublishedDocs) {
      out.writeln('hasPublishedDocs:true,');
    }
    if (isUnresolvedIdentifier) {
      out.writeln('isUnresolvedIdentifier:true,');
    }
    if (sharedName != null) {
      out.writeln("uniqueName: '$errorCode',");
    }
    out.write(');');
    return out.toString();
  }

  /// Generates dart comments for this error code.
  String toAnalyzerComments({String indent = ''}) {
    var out = StringBuffer();
    var comment = this.comment;
    if (comment != null) {
      for (var line in comment.split('\n')) {
        out.writeln('$indent/// ${line.isEmpty ? '' : ' '}$line');
      }
    }
    return out.toString();
  }

  /// Encodes this object into a YAML representation.
  Map<Object?, Object?> toYaml() => {
        if (sharedName != null) 'sharedName': sharedName,
        'problemMessage': problemMessage,
        if (correctionMessage != null) 'correctionMessage': correctionMessage,
        if (isUnresolvedIdentifier) 'isUnresolvedIdentifier': true,
        if (hasPublishedDocs) 'hasPublishedDocs': true,
        if (comment != null) 'comment': comment,
        if (documentation != null) 'documentation': documentation,
      };
}

/// In-memory representation of error code information obtained from the front
/// end's `messages.yaml` file.
class FrontEndErrorCodeInfo extends ErrorCodeInfo {
  /// The set of analyzer error codes that corresponds to this error code, if
  /// any.
  final List<String> analyzerCode;

  /// The index of the error in the analyzer's `fastaAnalyzerErrorCodes` table.
  final int? index;

  FrontEndErrorCodeInfo.fromYaml(super.yaml)
      : analyzerCode = _decodeAnalyzerCode(yaml['analyzerCode']),
        index = yaml['index'] as int?,
        super.fromYaml();

  @override
  Map<Object?, Object?> toYaml() => {
        if (analyzerCode.isNotEmpty)
          'analyzerCode': _encodeAnalyzerCode(analyzerCode),
        if (index != null) 'index': index,
        ...super.toYaml(),
      };

  static List<String> _decodeAnalyzerCode(Object? value) {
    if (value == null) {
      return const [];
    } else if (value is String) {
      return [value];
    } else if (value is List) {
      return [for (var s in value) s as String];
    } else {
      throw 'Unrecognized analyzer code: $value';
    }
  }

  static Object _encodeAnalyzerCode(List<String> analyzerCode) {
    if (analyzerCode.length == 1) {
      return analyzerCode.single;
    } else {
      return analyzerCode;
    }
  }
}
