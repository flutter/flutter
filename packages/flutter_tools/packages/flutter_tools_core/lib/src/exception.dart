// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

/// An exception thrown by a tool extension or host handler to report an
/// intentional, user-actionable operational failure over JSON-RPC 2.0 without
/// triggering a crash report.
///
/// When thrown inside an extension RPC handler, `ToolExtensionEntryPoint.run`
/// catches [ToolExtensionException] and serializes it as a JSON-RPC 2.0 error
/// with [code] and [message]. The host tool routes the failure
/// through the calling subsystem's error channel: logging a warning and
/// skipping the extension during discovery or configuration queries, returning
/// a failed validation row in `flutter doctor`, logging or returning a failed
/// result for builds, cleans, and device launch/stop operations, or aborting
/// the command when generating parameters for an explicitly selected template
/// or executing an explicitly requested configuration action.
@immutable
class ToolExtensionException implements Exception {
  /// Creates a [ToolExtensionException] with a user-facing [message] and
  /// JSON-RPC 2.0 error [code].
  const ToolExtensionException(this.message, {this.code = domainErrorCode});

  /// JSON-RPC 2.0 error code for intentional, user-actionable domain errors.
  ///
  /// Distinct from `-32000` (`SERVER_ERROR`), which indicates an unhandled
  /// exception in the extension isolate.
  static const int domainErrorCode = -32001;

  /// JSON-RPC 2.0 error code returned when an interactive terminal prompt is
  /// requested while the host tool is running in non-interactive or `--machine`
  /// mode.
  static const int nonInteractiveErrorCode = -32002;

  /// JSON-RPC 2.0 error code associated with this exception.
  final int code;

  /// Human-readable error message surfaced by the Flutter Tool.
  final String message;

  @override
  String toString() => 'ToolExtensionException: $message';
}
