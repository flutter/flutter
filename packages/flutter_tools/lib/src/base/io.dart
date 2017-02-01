// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// This file serves as the single point of entry into the `dart:io` APIs
/// within Flutter tools.
///
/// In order to make Flutter tools more testable, we use the `FileSystem` APIs
/// in `package:file` rather than using the `dart:io` file APIs directly (see
/// `file_system.dart`). Doing so allows us to swap out local file system
/// access with mockable (or in-memory) file systems, making our tests hermetic
/// vis-a-vis file system access.
///
/// We also use `package:platform` to provide an abstraction away from the
/// static methods in the `dart:io` `Platform` class (see `platform.dart`). As
/// such, do not export Platform from this file!
///
/// To ensure that all file system and platform API access within Flutter tools
/// goes through the proper APIs, we forbid direct imports of `dart:io` (via a
/// test), forcing all callers to instead import this file, which exports the
/// blessed subset of `dart:io` that is legal to use in Flutter tools.
///
/// Because of the nature of this file, it is important that **platform and file
/// APIs not be exported from `dart:io` in this file**! Moreover, be careful
/// about any additional exports that you add to this file, as doing so will
/// increase the API surface that we have to test in Flutter tools, and the APIs
/// in `dart:io` can sometimes be hard to use in tests.
import 'dart:io' as io show exit, exitCode;

import 'package:meta/meta.dart';

export 'dart:io'
    show
        BytesBuilder,
        // Directory         NO! Use `file_system.dart`
        exitCode,
        // File              NO! Use `file_system.dart`
        // FileSystemEntity  NO! Use `file_system.dart`
        GZIP,
        InternetAddress,
        IOException,
        IOSink,
        HttpClient,
        HttpClientRequest,
        HttpClientResponse,
        HttpHeaders,
        HttpRequest,
        HttpServer,
        HttpStatus,
        // Link              NO! Use `file_system.dart`
        pid,
        // Platform          NO! use `platform.dart`
        Process,
        ProcessException,
        ProcessResult,
        ProcessSignal,
        ProcessStartMode,
        // RandomAccessFile  NO! Use `file_system.dart`
        ServerSocket,
        stderr,
        stdin,
        StdinException,
        stdout,
        Socket,
        SocketException,
        SYSTEM_ENCODING,
        WebSocket,
        WebSocketTransformer;

/// Exits the process with the given [exitCode].
typedef void ExitFunction(int exitCode);

final ExitFunction _defaultExitFunction = (int exitCode) => io.exit(exitCode);

ExitFunction _exitFunction = _defaultExitFunction;

/// Exits the process.
///
/// This is analogous to the `exit` function in `dart:io`, except that this
/// function may be set to a testing-friendly value by calling
/// [setExitFunctionForTests] (and then restored to its default implementation
/// with [restoreExitFunction]). The default implementation delegates to
/// `dart:io`.
ExitFunction get exit => _exitFunction;

/// Sets the [exit] function to a function that throws an exception rather
/// than exiting the process; this is intended for testing purposes.
@visibleForTesting
void setExitFunctionForTests([ExitFunction exitFunction]) {
  _exitFunction = exitFunction ?? (int exitCode) {
    throw new Exception('Exited with code ${io.exitCode}');
  };
}

/// Restores the [exit] function to the `dart:io` implementation.
@visibleForTesting
void restoreExitFunction() {
  _exitFunction = _defaultExitFunction;
}
