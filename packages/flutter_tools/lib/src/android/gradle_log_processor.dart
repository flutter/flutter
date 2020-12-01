// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'gradle_errors.dart';

/// Process log output from gradle, removing irrelevant output and capturing
/// exception information.
class GradleLogProcessor {
  GradleLogProcessor(this.localGradleErrors, this.verbose);

  final List<GradleHandledError> localGradleErrors;
  final bool verbose;

  GradleHandledError detectedGradleError;
  String detectedGradleErrorLine;
  bool atFailureFooter = false;

  String consumeLog(String line) {
    // All gradle failures lead to a fairly long footer which contains mostly
    // irrelevant information for a flutter build, along with misleading advice to
    // run with --stacktrace (which does not exist for the flutter CLI). remove this.
    if (!verbose && (line.startsWith('FAILURE: Build failed with an exception.') || atFailureFooter)) {
      atFailureFooter = true;
      return null;
    }
    // This message was removed from first-party plugins,
    // but older plugin versions still display this message.
    if (androidXPluginWarningRegex.hasMatch(line)) {
      // Don't pipe.
      return null;
    }
    if (detectedGradleError != null) {
      // Pipe stdout/stderr from Gradle.
      return line;
    }
    for (final GradleHandledError gradleError in localGradleErrors) {
      if (gradleError.test(line)) {
        detectedGradleErrorLine = line;
        detectedGradleError = gradleError;
        // The first error match wins.
        break;
      }
    }
    // Pipe stdout/stderr from Gradle.
    return line;
  }
}
