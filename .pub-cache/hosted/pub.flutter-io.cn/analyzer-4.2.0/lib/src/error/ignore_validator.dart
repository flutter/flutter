// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/ignore_comments/ignore_info.dart';

/// Used to validate the ignore comments in a single file.
class IgnoreValidator {
  /// The error reporter to which errors are to be reported.
  final ErrorReporter _errorReporter;

  /// The diagnostics that are reported in the file being analyzed.
  final List<AnalysisError> _reportedErrors;

  /// The information about the ignore comments in the file being analyzed.
  final IgnoreInfo _ignoreInfo;

  /// The line info for the file being analyzed.
  final LineInfo _lineInfo;

  /// A list of the names and unique names of all known error codes that can't
  /// be ignored. Note that this list is incomplete. Plugins might well define
  /// diagnostics with a severity of `ERROR`, but we won't be able to flag their
  /// use because we have no visibility of them here.
  final Set<String> _unignorableNames;

  /// Initialize a newly created validator to report any issues with ignore
  /// comments in the file being analyzed. The diagnostics will be reported to
  /// the [_errorReporter].
  IgnoreValidator(this._errorReporter, this._reportedErrors, this._ignoreInfo,
      this._lineInfo, this._unignorableNames);

  /// Report any issues with ignore comments in the file being analyzed.
  void reportErrors() {
    if (!_ignoreInfo.hasIgnores) {
      return;
    }
    var ignoredOnLineMap = _ignoreInfo.ignoredOnLine;
    var ignoredForFile = _ignoreInfo.ignoredForFile;
    //
    // Report and remove any un-ignorable or duplicated names.
    //
    var namesIgnoredForFile = <String>{};
    var typesIgnoredForFile = <String>{};
    var unignorable = <DiagnosticName>[];
    var duplicated = <IgnoredElement>[];
    for (var ignoredElement in ignoredForFile) {
      if (ignoredElement is DiagnosticName) {
        var name = ignoredElement.name;
        if (_unignorableNames.contains(name)) {
          unignorable.add(ignoredElement);
        } else if (!namesIgnoredForFile.add(name)) {
          duplicated.add(ignoredElement);
        }
      } else if (ignoredElement is DiagnosticType) {
        if (!typesIgnoredForFile.add(ignoredElement.type)) {
          duplicated.add(ignoredElement);
        }
      }
    }
    _reportUnknownAndDuplicateIgnores(unignorable, duplicated, ignoredForFile);
    for (var ignoredOnLine in ignoredOnLineMap.values) {
      var namedIgnoredOnLine = <String>{};
      var typesIgnoredOnLine = <String>{};
      var unignorable = <IgnoredElement>[];
      var duplicated = <IgnoredElement>[];
      for (var ignoredElement in ignoredOnLine) {
        if (ignoredElement is DiagnosticName) {
          var name = ignoredElement.name;
          if (_unignorableNames.contains(name)) {
            unignorable.add(ignoredElement);
          } else if (namesIgnoredForFile.contains(name) ||
              !namedIgnoredOnLine.add(name)) {
            duplicated.add(ignoredElement);
          }
        } else if (ignoredElement is DiagnosticType) {
          var type = ignoredElement.type;
          if (typesIgnoredForFile.contains(type) ||
              !typesIgnoredOnLine.add(type)) {
            duplicated.add(ignoredElement);
          }
        }
      }
      _reportUnknownAndDuplicateIgnores(unignorable, duplicated, ignoredOnLine);
    }
    //
    // Remove all of the errors that are actually being ignored.
    //
    for (var error in _reportedErrors) {
      var lineNumber = _lineInfo.getLocation(error.offset).lineNumber;
      var ignoredOnLine = ignoredOnLineMap[lineNumber];

      ignoredForFile.removeByName(error.ignoreName);
      ignoredForFile.removeByName(error.ignoreUniqueName);

      ignoredOnLine?.removeByName(error.ignoreName);
      ignoredOnLine?.removeByName(error.ignoreUniqueName);
    }
    //
    // Report any remaining ignored names as being unnecessary.
    //
    _reportUnnecessaryIgnores(ignoredForFile);
    for (var ignoredOnLine in ignoredOnLineMap.values) {
      _reportUnnecessaryIgnores(ignoredOnLine);
    }
  }

  /// Report the names that are [unignorable] or [duplicated] and remove them
  /// from the [list] of names from which they were extracted.
  void _reportUnknownAndDuplicateIgnores(List<IgnoredElement> unignorable,
      List<IgnoredElement> duplicated, List<IgnoredElement> list) {
    // TODO(brianwilkerson) Uncomment the code below after the unignorable
    //  ignores in the Flutter code base have been cleaned up.
    // for (var unignorableName in unignorable) {
    //   var name = unignorableName.name;
    //   _errorReporter.reportErrorForOffset(HintCode.UNIGNORABLE_IGNORE,
    //       unignorableName.offset, name.length, [name]);
    //   list.remove(unignorableName);
    // }
    for (var ignoredElement in duplicated) {
      if (ignoredElement is DiagnosticName) {
        var name = ignoredElement.name;
        _errorReporter.reportErrorForOffset(HintCode.DUPLICATE_IGNORE,
            ignoredElement.offset, name.length, [name]);
        list.remove(ignoredElement);
      } else if (ignoredElement is DiagnosticType) {
        _errorReporter.reportErrorForOffset(
          HintCode.DUPLICATE_IGNORE,
          ignoredElement.offset,
          ignoredElement.length,
          [ignoredElement.type],
        );
        list.remove(ignoredElement);
      }
    }
  }

  /// Report the [ignoredNames] as being unnecessary.
  void _reportUnnecessaryIgnores(List<IgnoredElement> ignoredNames) {
    // TODO(brianwilkerson) Uncomment the code below after the unnecessary
    //  ignores in the Flutter code base have been cleaned up.
    // for (var ignoredName in ignoredNames) {
    //   var name = ignoredName.name;
    //   _errorReporter.reportErrorForOffset(
    //       HintCode.UNNECESSARY_IGNORE, ignoredName.offset, name.length,
    //       [name]);
    // }
  }
}

extension on AnalysisError {
  String get ignoreName => errorCode.name.toLowerCase();

  String get ignoreUniqueName {
    String uniqueName = errorCode.uniqueName;
    int period = uniqueName.indexOf('.');
    if (period >= 0) {
      uniqueName = uniqueName.substring(period + 1);
    }
    return uniqueName.toLowerCase();
  }
}

extension on List<IgnoredElement> {
  void removeByName(String name) {
    removeWhere((ignoredElement) =>
        ignoredElement is DiagnosticName && ignoredElement.name == name);
  }
}
