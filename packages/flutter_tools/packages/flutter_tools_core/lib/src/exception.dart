// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

/// An exception thrown by a tool extension to report an intentional,
/// user-actionable operational failure over JSON-RPC 2.0 without triggering a
/// crash report.
///
/// When thrown inside an extension RPC handler, `ToolExtensionEntryPoint.run`
/// catches [ToolExtensionException] and serializes it as a JSON-RPC 2.0 error
/// with [domainErrorCode] and [message]. The host tool routes the failure
/// through the calling subsystem's error channel: logging a warning and
/// skipping the extension during discovery or configuration queries, returning
/// a failed validation row in `flutter doctor`, logging or returning a failed
/// result for builds, cleans, and device launch/stop operations, or aborting
/// the command when generating parameters for an explicitly selected template.
@immutable
class ToolExtensionException implements Exception {
  /// Creates a [ToolExtensionException] with a user-facing [message].
  const ToolExtensionException(this.message);

  /// JSON-RPC 2.0 error code for intentional, user-actionable domain errors.
  ///
  /// Distinct from `-32000` (`SERVER_ERROR`), which indicates an unhandled
  /// exception in the extension isolate.
  static const int domainErrorCode = -32001;

  /// Human-readable error message surfaced by the Flutter Tool.
  final String message;

  @override
  String toString() => 'ToolExtensionException: $message';
}
