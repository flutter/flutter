// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';

/// Defines style and best practice recommendations.
///
/// Unlike [HintCode]s, which are akin to traditional static warnings from a
/// compiler, lint recommendations focus on matters of style and practices that
/// might aggregated to define a project's style guide.
class LintCode extends ErrorCode {
  const LintCode(
    String name,
    String problemMessage, {
    @Deprecated('Use correctionMessage instead') String? correction,
    String? correctionMessage,
    String? uniqueName,
  }) : super(
          correctionMessage: correctionMessage ?? correction,
          problemMessage: problemMessage,
          name: name,
          uniqueName: uniqueName ?? 'LintCode.$name',
        );

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.INFO;

  @override
  int get hashCode => uniqueName.hashCode;

  @Deprecated('Use problemMessage instead')
  String get message => problemMessage;

  @override
  ErrorType get type => ErrorType.LINT;

  @override
  String get url => 'https://dart-lang.github.io/linter/lints/$name.html';

  @override
  bool operator ==(Object other) =>
      other is LintCode && uniqueName == other.uniqueName;
}

/// Defines security-related best practice recommendations.
///
/// The primary difference from [LintCode]s is that these codes cannot be
/// suppressed with `// ignore:` or `// ignore_for_file:` comments.
class SecurityLintCode extends LintCode {
  const SecurityLintCode(String name, String problemMessage,
      {String? uniqueName, String? correctionMessage})
      : super(name, problemMessage,
            uniqueName: uniqueName ?? 'LintCode.$name',
            correctionMessage: correctionMessage);

  @override
  bool get isIgnorable => false;
}
