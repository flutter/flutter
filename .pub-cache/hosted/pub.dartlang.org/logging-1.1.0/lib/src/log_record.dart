// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'level.dart';
import 'logger.dart';

/// A log entry representation used to propagate information from [Logger] to
/// individual handlers.
class LogRecord {
  final Level level;
  final String message;

  /// Non-string message passed to Logger.
  final Object? object;

  /// Logger where this record is stored.
  final String loggerName;

  /// Time when this record was created.
  final DateTime time;

  /// Unique sequence number greater than all log records created before it.
  final int sequenceNumber;

  static int _nextNumber = 0;

  /// Associated error (if any) when recording errors messages.
  final Object? error;

  /// Associated stackTrace (if any) when recording errors messages.
  final StackTrace? stackTrace;

  /// Zone of the calling code which resulted in this LogRecord.
  final Zone? zone;

  LogRecord(this.level, this.message, this.loggerName,
      [this.error, this.stackTrace, this.zone, this.object])
      : time = DateTime.now(),
        sequenceNumber = LogRecord._nextNumber++;

  @override
  String toString() => '[${level.name}] $loggerName: $message';
}
