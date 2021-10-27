// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show json;

import '../../src/base/process.dart';
import '../../src/macos/xcode.dart';
import '../convert.dart';

const int _kDefaultResultBundleVersion = 3;

/// The generator of xcresults.
///
/// Call [generate] after an iOS/MacOS build will generate a [XCResult].
/// * See also: [XCResult].
class XCResultGenerator {
  /// Construct the [XCResultGenerator].
  ///
  /// The `resultBundleVersion` is set to 3 by default.
  XCResultGenerator(
      {required this.resultPath,
      this.resultBundleVersion = _kDefaultResultBundleVersion,
      required this.xcode,
      required this.processUtils});

  /// The file path that used to store the xcrun result.
  ///
  /// There's usually a `resultPath.xcresult` file in the same folder.
  final String resultPath;

  /// The version that is specified in `-resultBundleVersion` when generating the result.
  final int resultBundleVersion;

  /// The [ProcessUtils] to run commands.
  final ProcessUtils processUtils;

  /// [Xcode] object used to run xcode command.
  final Xcode xcode;

  /// Generates the XCResult.
  ///
  /// Calls `xcrun xcresulttool get --path <resultPath> --format json`,
  /// then stores the useful information the json into an [XCResult] object.
  Future<XCResult> generate() async {
    RunResult result = await processUtils.run(
      <String>[
        ...xcode.xcrunCommand(),
        'xcresulttool',
        'get',
        '--path',
        resultPath,
        '--format',
        'json'
      ],
    );
    final dynamic resultJson =
        json.decode(result.stdout);
    if (resultJson == null || resultJson is! Map<String, dynamic>) {
      // If json parsing failed, indicate such error.
      // This also includes the top level json object is an array, which indicates
      // the structure of the json is changed and this parser class possibly needs to update for this change.
      return XCResult.failed(
          errorMessage: 'xcresult parser: Unrecognized top level json format.');
    }
    return XCResult(resultJson: resultJson);
  }
}

const List<XCResultIssue> _kEmptyIssueResultList = <XCResultIssue>[];

/// The xcresult of an `xcodebuild` command.
///
/// This is the result from an `xcrun xcresulttool get --path <resultPath> --format json` run.
/// The result contains useful information such as build errors and warnings.
class XCResult {
  /// Parse the `resultJson` and stores useful informations in the returned `XCResult`.
  factory XCResult({required Map<String, dynamic> resultJson}) {
    final List<XCResultIssue> issues = <XCResultIssue>[];
    final dynamic actionsMap =
        resultJson['actions'];
    if (actionsMap == null || actionsMap is! Map<String, dynamic>) {
      return XCResult.failed(errorMessage: 'xcresult parser: Failed to parse the actions map.');
    }
    final dynamic actionValueList =
        actionsMap['_values'];
    if (actionValueList == null || actionValueList is! List<dynamic> || actionValueList.isEmpty) {
      return XCResult.failed(errorMessage: 'xcresult parser: Failed to parse the actions map.');
    }
    final dynamic actionMap =
        actionValueList.first;
    if (actionMap == null || actionMap is! Map<String, dynamic>) {
      return XCResult.failed(errorMessage: 'xcresult parser: Failed to parse the first action map.');
    }
    final dynamic buildResultMap =
        actionMap['buildResult'];
    if (buildResultMap == null || buildResultMap is! Map<String, dynamic>) {
      return XCResult.failed(errorMessage: 'xcresult parser: Failed to parse the buildResult map.');
    }
    final dynamic issuesMap =
        buildResultMap['issues'];
    if (issuesMap == null || issuesMap is! Map<String, dynamic>) {
      return XCResult.failed(errorMessage: 'xcresult parser: Failed to parse the issues map.');
    }
    List<XCResultIssue> _parseIssuesFromIssueSummariesJson(
        Map<String, dynamic> issueSummariesJson) {
      final List<XCResultIssue> issues = <XCResultIssue>[];
      final dynamic errorsList =
          issueSummariesJson['_values'];
      if (errorsList != null && errorsList is List<dynamic>) {
        for (final dynamic issueJson in errorsList) {
          if (issueJson is! Map<String, dynamic>) {
            continue;
          }
          final XCResultIssue resultIssue = XCResultIssue(issueJson: issueJson);
          issues.add(resultIssue);
        }
      }
      return issues;
    }

    final dynamic errorSummaries =
        issuesMap['errorSummaries'];
    if (errorSummaries != null && errorSummaries is Map<String, dynamic>) {
      issues.addAll(_parseIssuesFromIssueSummariesJson(errorSummaries));
    }

    final dynamic warningSummaries =
        issuesMap['warningSummaries'];
    if (warningSummaries != null && warningSummaries is Map<String, dynamic>) {
      issues.addAll(_parseIssuesFromIssueSummariesJson(warningSummaries));
    }
    return XCResult._(issues: issues);
  }

  factory XCResult.failed({required String errorMessage}) {
    return XCResult._(parseSuccess: false, parsingErrorMessage: errorMessage);
  }

  XCResult._(
      {this.issues = _kEmptyIssueResultList,
      this.parseSuccess = true,
      this.parsingErrorMessage = ''});

  /// The issues in the xcresult file.
  final List<XCResultIssue> issues;

  /// Indicate if the xcresult was successfully parsed.
  ///
  /// See also: [parsingErrorMessage] for the error message if the parsing was unsuccessful.
  final bool parseSuccess;

  /// The error message describes why the parse if unsuccessful.
  ///
  /// This is empty if [parseSuccess] is `true`.
  final String parsingErrorMessage;
}

/// An issue object in the XCResult
class XCResultIssue {
  /// Construct an `XCResultIssue` object from `issueJson`.
  ///
  /// `issueJson` is the object at xcresultJson[['actions']['_values'][0]['buildResult']['issues']['errorSummaries'/'warningSummaries']['_values'].
  factory XCResultIssue({required Map<String, dynamic> issueJson}) {
    final Map<String, dynamic>? issueTypeMap =
        issueJson['issueType'] as Map<String, dynamic>?;
    String type = '';
    if (issueTypeMap != null) {
      final String? typeValue = issueTypeMap['_value'] as String?;
      if (typeValue != null) {
        type = typeValue;
      }
    }

    String message = '';
    final Map<String, dynamic>? messageMap =
        issueJson['message'] as Map<String, dynamic>?;
    if (messageMap != null) {
      final String? messageValue = messageMap['_value'] as String?;
      if (messageValue != null) {
        message = messageValue;
      }
    }

    return XCResultIssue._(type: type, message: message);
  }

  XCResultIssue._({required this.type, required this.message});

  /// The type of the issue.
  ///
  /// The possible values are `warning`, `error` etc.
  final String type;

  /// Human readable message for the issue.
  ///
  /// This can be displayed to user for their information.
  final String message;
}
