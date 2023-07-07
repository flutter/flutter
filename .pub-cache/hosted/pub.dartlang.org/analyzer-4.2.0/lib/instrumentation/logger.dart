// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// The interface used by client code to communicate with an instrumentation
/// server.
abstract class InstrumentationLogger {
  /// Pass the given [message] to the instrumentation server so that it will be
  /// logged with other messages.
  ///
  /// This method should be used for most logging.
  void log(String message);

  /// Shut down this logger, including file handles etc.
  Future<void> shutdown();
}
