// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../../src/base/process.dart';
import '../../src/convert.dart' show json;
import '../../src/macos/xcode.dart';
import '../base/version.dart';
import '../convert.dart';

/// The generator of xcresults.
///
/// Call [generate] after an iOS/MacOS build will generate a [XCResult].
/// This only works when the `-resultBundleVersion` is set to 3.
/// * See also: [XCResult].
class XCResultGenerator {
  /// Construct the [XCResultGenerator].
  XCResultGenerator({required this.resultPath, required this.xcode, required this.processUtils});

  /// The file path that used to store the xcrun result.
  ///
  /// There's usually a `resultPath.xcresult` file in the same folder.
  final String resultPath;

  /// The [ProcessUtils] to run commands.
  final ProcessUtils processUtils;

  /// [Xcode] object used to run xcode command.
  final Xcode xcode;

  /// Generates the XCResult.
  ///
  /// Calls `xcrun xcresulttool get --legacy --path <resultPath> --format json`,
  /// then stores the useful information the json into an [XCResult] object.
  ///
  /// A`issueDiscarders` can be passed to discard any issues that matches the description of any [XCResultIssueDiscarder] in the list.
  Future<XCResult> generate({
    List<XCResultIssueDiscarder> issueDiscarders = const <XCResultIssueDiscarder>[],
  }) async {
    final Version? xcodeVersion = xcode.currentVersion;
    final bool useNewCommand = xcodeVersion != null && xcodeVersion >= Version(16, 0, 0);

    final baseCommand = <String>[...xcode.xcrunCommand(), 'xcresulttool'];

    if (useNewCommand) {
      baseCommand.addAll(<String>[
        'get',
        'build-results',
        '--path',
        resultPath,
        '--format',
        'json',
      ]);
    } else {
      baseCommand.addAll(<String>['get', '--path', resultPath, '--format', 'json']);
    }

    final RunResult result = await processUtils.run(baseCommand);

    if (result.exitCode != 0) {
      return XCResult.failed(errorMessage: result.stderr);
    }
    if (result.stdout.isEmpty) {
      return XCResult.failed(errorMessage: 'xcresult parser: Unrecognized top level json format.');
    }
    final Object? resultJson = json.decode(result.stdout);
    if (resultJson == null || resultJson is! Map<String, Object?>) {
      return XCResult.failed(errorMessage: 'xcresult parser: Unrecognized top level json format.');
    }
    return XCResult(resultJson: resultJson, issueDiscarders: issueDiscarders);
  }
}

/// The xcresult of an `xcodebuild` command.
///
/// This is the result from an `xcrun xcresulttool get --legacy --path <resultPath> --format json` run.
/// The result contains useful information such as build errors and warnings.
class XCResult {
  /// Parse the `resultJson` and stores useful information in the returned `XCResult`.
  factory XCResult({
    required Map<String, Object?> resultJson,
    List<XCResultIssueDiscarder> issueDiscarders = const <XCResultIssueDiscarder>[],
  }) {
    final issues = <XCResultIssue>[];

    // Detect which xcresult JSON format is being used to ensure backwards compatibility.
    //
    // Xcode 16 introduced a new `get build-results` command with a flatter JSON structure.
    // Older versions use the original `get` command with a deeply nested structure.
    // We differentiate them by checking for the presence of top-level 'errors' or 'warnings'
    // keys, which are unique to the modern format.

    if (resultJson.containsKey('errors') || resultJson.containsKey('warnings')) {
      issues.addAll(
        _parseIssuesFromXcode16Format(
          type: XCResultIssueType.error,
          jsonList: resultJson['errors'],
          issueDiscarders: issueDiscarders,
        ),
      );
      issues.addAll(
        _parseIssuesFromXcode16Format(
          type: XCResultIssueType.warning,
          jsonList: resultJson['warnings'],
          issueDiscarders: issueDiscarders,
        ),
      );
    } else {
      final Object? issuesMap = resultJson['issues'];

      if (issuesMap is! Map<String, Object?>) {
        return XCResult.failed(errorMessage: 'xcresult parser: Failed to parse the issues map.');
      }

      final Object? errorSummaries = issuesMap['errorSummaries'];
      if (errorSummaries is Map<String, Object?>) {
        issues.addAll(
          _parseIssuesFromXcode15Format(
            type: XCResultIssueType.error,
            issueSummariesJson: errorSummaries,
            issueDiscarder: issueDiscarders,
          ),
        );
      }
      final Object? warningSummaries = issuesMap['warningSummaries'];
      if (warningSummaries is Map<String, Object?>) {
        issues.addAll(
          _parseIssuesFromXcode15Format(
            type: XCResultIssueType.warning,
            issueSummariesJson: warningSummaries,
            issueDiscarder: issueDiscarders,
          ),
        );
      }
      final Object? actionsMap = resultJson['actions'];
      if (actionsMap is Map<String, Object?>) {
        final List<XCResultIssue> actionIssues = _parseActionIssues(
          actionsMap,
          issueDiscarders: issueDiscarders,
        );
        issues.addAll(actionIssues);
      }
    }

    if (issues.isEmpty &&
        resultJson['issues'] == null &&
        resultJson['actions'] == null &&
        resultJson['errors'] == null &&
        resultJson['warnings'] == null) {
      return XCResult.failed(errorMessage: 'xcresult parser: Failed to parse the issues map.');
    }

    return XCResult._(issues: issues);
  }

  factory XCResult.failed({required String errorMessage}) {
    return XCResult._(parseSuccess: false, parsingErrorMessage: errorMessage);
  }

  /// Create a [XCResult] with constructed [XCResultIssue]s for testing.
  @visibleForTesting
  factory XCResult.test({
    List<XCResultIssue>? issues,
    bool? parseSuccess,
    String? parsingErrorMessage,
  }) {
    return XCResult._(
      issues: issues ?? const <XCResultIssue>[],
      parseSuccess: parseSuccess ?? true,
      parsingErrorMessage: parsingErrorMessage,
    );
  }

  XCResult._({
    this.issues = const <XCResultIssue>[],
    this.parseSuccess = true,
    this.parsingErrorMessage,
  });

  final List<XCResultIssue> issues;

  /// Indicate if the xcresult was successfully parsed.
  ///
  /// See also: [parsingErrorMessage] for the error message if the parsing was unsuccessful.
  final bool parseSuccess;

  /// The error message describes why the parse if unsuccessful.
  ///
  /// This is `null` if [parseSuccess] is `true`.
  final String? parsingErrorMessage;
}

class XCResultIssue {
  /// Construct an `XCResultIssue` object from `issueJson`.
  ///
  /// `issueJson` is the object at xcresultJson[['actions']['_values'][0]['buildResult']['issues']['errorSummaries'/'warningSummaries']['_values'].
  factory XCResultIssue.fromOldFormat({
    required XCResultIssueType type,
    required Map<String, Object?> issueJson,
  }) {
    final Object? issueSubTypeMap = issueJson['issueType'];
    String? subType;
    if (issueSubTypeMap is Map<String, Object?>) {
      subType = issueSubTypeMap['_value'] as String?;
    }

    String? message;
    final Object? messageMap = issueJson['message'];
    if (messageMap is Map<String, Object?>) {
      message = messageMap['_value'] as String?;
    }

    final warnings = <String>[];
    // Parse url and convert it to a location String.
    String? location;
    final Object? documentLocationInCreatingWorkspaceMap =
        issueJson['documentLocationInCreatingWorkspace'];
    if (documentLocationInCreatingWorkspaceMap is Map<String, Object?>) {
      final Object? urlMap = documentLocationInCreatingWorkspaceMap['url'];
      if (urlMap is Map<String, Object?>) {
        final Object? urlValue = urlMap['_value'];
        if (urlValue is String) {
          location = _convertUrlToLocationString(urlValue);
          if (location == null) {
            warnings.add(
              '(XCResult) The `url` exists but it was failed to be parsed. url: $urlValue',
            );
          }
        }
      }
    }

    return XCResultIssue._(
      type: type,
      subType: subType,
      message: message,
      location: location,
      warnings: warnings,
    );
  }

  /// Construct an `XCResultIssue` object from the (Xcode 16+) format `issueJson`.
  factory XCResultIssue.fromNewFormat({
    required XCResultIssueType type,
    required Map<String, Object?> issueJson,
  }) {
    final message = issueJson['message'] as String?;

    final subType = issueJson['issueType'] as String?;

    String? location;
    final warnings = <String>[];

    final sourceUrl = issueJson['sourceURL'] as String?;
    if (sourceUrl != null) {
      location = _convertUrlToLocationString(sourceUrl);
      if (location == null) {
        warnings.add(
          '(XCResult) The `sourceURL` exists but it failed to be parsed. url: $sourceUrl',
        );
      }
    }

    return XCResultIssue._(
      type: type,
      subType: subType,
      message: message,
      location: location,
      warnings: warnings,
    );
  }

  @visibleForTesting
  factory XCResultIssue.test({
    XCResultIssueType type = XCResultIssueType.error,
    String? subType,
    String? message,
    String? location,
    List<String> warnings = const <String>[],
  }) {
    return XCResultIssue._(
      type: type,
      subType: subType,
      message: message,
      location: location,
      warnings: warnings,
    );
  }

  XCResultIssue._({
    required this.type,
    this.subType,
    this.message,
    this.location,
    this.warnings = const <String>[],
  });

  /// The type of the issue.
  final XCResultIssueType type;

  /// The sub type of the issue.
  ///
  /// This is a more detailed category about the issue.
  /// The possible values are `Warning`, `Semantic Issue'` etc.
  final String? subType;

  /// Human readable message for the issue.
  ///
  /// This can be displayed to user for their information.
  final String? message;

  /// The location where the issue occurs.
  ///
  /// This is a re-formatted version of the "url" value in the json.
  /// The format looks like `<FileLocation>:<StartingLineNumber>:<StartingColumnNumber>`.
  final String? location;

  /// Warnings when constructing the issue object.
  final List<String> warnings;
}

/// The type of an `XCResultIssue`.
enum XCResultIssueType {
  /// The issue is an warning.
  ///
  /// This is for all the issues under the `warningSummaries` key in the xcresult.
  warning,

  /// The issue is an warning.
  ///
  /// This is for all the issues under the `errorSummaries` key in the xcresult.
  error,
}

/// Discards the [XCResultIssue] that matches any of the matchers.
class XCResultIssueDiscarder {
  XCResultIssueDiscarder({
    this.typeMatcher,
    this.subTypeMatcher,
    this.messageMatcher,
    this.locationMatcher,
  }) : assert(
         typeMatcher != null ||
             subTypeMatcher != null ||
             messageMatcher != null ||
             locationMatcher != null,
       );

  /// The type of the discarder.
  ///
  /// A [XCResultIssue] should be discarded if its `type` equals to this.
  final XCResultIssueType? typeMatcher;

  /// The subType of the discarder.
  ///
  /// A [XCResultIssue] should be discarded if its `subType` matches the RegExp.
  final RegExp? subTypeMatcher;

  /// The message of the discarder.
  ///
  /// A [XCResultIssue] should be discarded if its `message` matches the RegExp.
  final RegExp? messageMatcher;

  /// The location of the discarder.
  ///
  /// A [XCResultIssue] should be discarded if its `location` matches the RegExp.
  final RegExp? locationMatcher;
}

// A typical location url string looks like file:///foo.swift#CharacterRangeLen=0&EndingColumnNumber=82&EndingLineNumber=7&StartingColumnNumber=82&StartingLineNumber=7.
// This function is now used by BOTH the old and new parsers.
String? _convertUrlToLocationString(String url) {
  final Uri? fragmentLocation = Uri.tryParse(url);
  if (fragmentLocation == null || !fragmentLocation.hasFragment) {
    return null;
  }
  // Parse the fragment as a query of key-values:
  final fileLocation = Uri(path: fragmentLocation.path, query: fragmentLocation.fragment);
  String startingLineNumber = fileLocation.queryParameters['StartingLineNumber'] ?? '';
  if (startingLineNumber.isNotEmpty) {
    startingLineNumber = ':$startingLineNumber';
  }
  String startingColumnNumber = fileLocation.queryParameters['StartingColumnNumber'] ?? '';
  if (startingColumnNumber.isNotEmpty) {
    startingColumnNumber = ':$startingColumnNumber';
  }
  return '${fileLocation.path}$startingLineNumber$startingColumnNumber';
}

bool _shouldDiscardIssue({
  required XCResultIssue issue,
  required XCResultIssueDiscarder discarder,
}) {
  if (issue.type == discarder.typeMatcher) {
    return true;
  }
  if (issue.subType != null &&
      discarder.subTypeMatcher != null &&
      discarder.subTypeMatcher!.hasMatch(issue.subType!)) {
    return true;
  }
  if (issue.message != null &&
      discarder.messageMatcher != null &&
      discarder.messageMatcher!.hasMatch(issue.message!)) {
    return true;
  }
  if (issue.location != null &&
      discarder.locationMatcher != null &&
      discarder.locationMatcher!.hasMatch(issue.location!)) {
    return true;
  }

  return false;
}

/// Helper to parse issues from the (Xcode 16+) flat list format.
List<XCResultIssue> _parseIssuesFromXcode16Format({
  required XCResultIssueType type,
  required Object? jsonList,
  required List<XCResultIssueDiscarder> issueDiscarders,
}) {
  if (jsonList is! List<Object?>) {
    return const <XCResultIssue>[];
  }

  return jsonList
      .whereType<Map<String, Object?>>()
      .map((issueJson) => XCResultIssue.fromNewFormat(type: type, issueJson: issueJson))
      .where((issue) {
        final bool shouldDiscard = issueDiscarders.any(
          (discarder) => _shouldDiscardIssue(issue: issue, discarder: discarder),
        );
        return !shouldDiscard;
      })
      .toList();
}

/// Helper to parse issues from the old (pre-Xcode 16) format.
List<XCResultIssue> _parseIssuesFromXcode15Format({
  required XCResultIssueType type,
  required Map<String, Object?> issueSummariesJson,
  required List<XCResultIssueDiscarder> issueDiscarder,
}) {
  final issues = <XCResultIssue>[];
  final Object? errorsList = issueSummariesJson['_values'];
  if (errorsList is List<Object?>) {
    for (final Object? issueJson in errorsList) {
      if (issueJson is! Map<String, Object?>) {
        continue;
      }
      final resultIssue = XCResultIssue.fromOldFormat(type: type, issueJson: issueJson);
      var discard = false;
      for (final discarder in issueDiscarder) {
        if (_shouldDiscardIssue(issue: resultIssue, discarder: discarder)) {
          discard = true;
          break;
        }
      }
      if (!discard) {
        issues.add(resultIssue);
      }
    }
  }
  return issues;
}

/// Helper to parse issues from the `actions` block in the pre-Xcode 16 format.
List<XCResultIssue> _parseActionIssues(
  Map<String, Object?> actionsMap, {
  required List<XCResultIssueDiscarder> issueDiscarders,
}) {
  // Example of json:
  // {
  //   "actions" : {
  //     "_values" : [
  //       {
  //         "actionResult" : {
  //           "_type" : {
  //             "_name" : "ActionResult"
  //           },
  //           "issues" : {
  //             "_type" : {
  //               "_name" : "ResultIssueSummaries"
  //             },
  //             "testFailureSummaries" : {
  //               "_type" : {
  //                 "_name" : "Array"
  //               },
  //               "_values" : [
  //                 {
  //                   "_type" : {
  //                     "_name" : "TestFailureIssueSummary",
  //                     "_supertype" : {
  //                       "_name" : "IssueSummary"
  //                     }
  //                   },
  //                   "issueType" : {
  //                     "_type" : {
  //                       "_name" : "String"
  //                     },
  //                     "_value" : "Uncategorized"
  //                   },
  //                   "message" : {
  //                     "_type" : {
  //                       "_name" : "String"
  //                     },
  //                     "_value" : "Unable to find a destination matching the provided destination specifier:\n\t\t{ id:1234D567-890C-1DA2-34E5-F6789A0123C4 }\n\n\tIneligible destinations for the \"Runner\" scheme:\n\t\t{ platform:iOS, id:dvtdevice-DVTiPhonePlaceholder-iphoneos:placeholder, name:Any iOS Device, error:iOS 17.0 is not installed. To use with Xcode, first download and install the platform }"
  //                   }
  //                 }
  //               ]
  //             }
  //           }
  //         }
  //       }
  //     ]
  //   }
  // }
  final issues = <XCResultIssue>[];
  final Object? actionsValues = actionsMap['_values'];
  if (actionsValues is! List<Object?>) {
    return issues;
  }

  for (final Object? actionValue in actionsValues) {
    if (actionValue is! Map<String, Object?>) {
      continue;
    }
    final Object? actionResult = actionValue['actionResult'];
    if (actionResult is! Map<String, Object?>) {
      continue;
    }
    final Object? actionResultIssues = actionResult['issues'];
    if (actionResultIssues is! Map<String, Object?>) {
      continue;
    }
    final Object? testFailureSummaries = actionResultIssues['testFailureSummaries'];
    if (testFailureSummaries is Map<String, Object?>) {
      issues.addAll(
        _parseIssuesFromXcode15Format(
          type: XCResultIssueType.error,
          issueSummariesJson: testFailureSummaries,
          issueDiscarder: issueDiscarders,
        ),
      );
    }
  }
  return issues;
}
