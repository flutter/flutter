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
import 'dart:async';
import 'dart:io' as io show exit, IOSink, ProcessSignal, stderr, stdin, stdout;

import 'package:meta/meta.dart';

import 'context.dart';
import 'platform.dart';
import 'process.dart';

export 'dart:io'
    show
        BytesBuilder,
        // Directory         NO! Use `file_system.dart`
        exitCode,
        // File              NO! Use `file_system.dart`
        // FileSystemEntity  NO! Use `file_system.dart`
        gzip,
        HandshakeException,
        HttpClient,
        HttpClientRequest,
        HttpClientResponse,
        HttpHeaders,
        HttpRequest,
        HttpServer,
        HttpStatus,
        InternetAddress,
        InternetAddressType,
        IOException,
        IOSink,
        // Link              NO! Use `file_system.dart`
        pid,
        // Platform          NO! use `platform.dart`
        Process,
        ProcessException,
        ProcessResult,
        // ProcessSignal     NO! Use [ProcessSignal] below.
        ProcessStartMode,
        // RandomAccessFile  NO! Use `file_system.dart`
        ServerSocket,
        // stderr,           NO! Use `io.dart`
        // stdin,            NO! Use `io.dart`
        Stdin,
        StdinException,
        // stdout,           NO! Use `io.dart`
        Socket,
        SocketException,
        systemEncoding,
        WebSocket,
        WebSocketException,
        WebSocketTransformer;

/// Exits the process with the given [exitCode].
typedef ExitFunction = void Function(int exitCode);

const ExitFunction _defaultExitFunction = io.exit;

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
    throw ProcessExit(exitCode, immediate: true);
  };
}

/// Restores the [exit] function to the `dart:io` implementation.
@visibleForTesting
void restoreExitFunction() {
  _exitFunction = _defaultExitFunction;
}

/// A portable version of [io.ProcessSignal].
///
/// Listening on signals that don't exist on the current platform is just a
/// no-op. This is in contrast to [io.ProcessSignal], where listening to
/// non-existent signals throws an exception.
class ProcessSignal implements io.ProcessSignal {
  @visibleForTesting
  const ProcessSignal(this._delegate);

  static const ProcessSignal SIGWINCH = _PosixProcessSignal._(io.ProcessSignal.sigwinch);
  static const ProcessSignal SIGTERM = _PosixProcessSignal._(io.ProcessSignal.sigterm);
  static const ProcessSignal SIGUSR1 = _PosixProcessSignal._(io.ProcessSignal.sigusr1);
  static const ProcessSignal SIGUSR2 = _PosixProcessSignal._(io.ProcessSignal.sigusr2);
  static const ProcessSignal SIGINT =  ProcessSignal(io.ProcessSignal.sigint);
  static const ProcessSignal SIGKILL =  ProcessSignal(io.ProcessSignal.sigkill);

  final io.ProcessSignal _delegate;

  @override
  Stream<ProcessSignal> watch() {
    return _delegate.watch().map<ProcessSignal>((io.ProcessSignal signal) => this);
  }

  @override
  String toString() => _delegate.toString();
}

/// A [ProcessSignal] that is only available on Posix platforms.
///
/// Listening to a [_PosixProcessSignal] is a no-op on Windows.
class _PosixProcessSignal extends ProcessSignal {

  const _PosixProcessSignal._(io.ProcessSignal wrappedSignal) : super(wrappedSignal);

  @override
  Stream<ProcessSignal> watch() {
    if (platform.isWindows)
      return const Stream<ProcessSignal>.empty();
    return super.watch();
  }
}

class Stdio {
  const Stdio();

  Stream<List<int>> get stdin => io.stdin;
  io.IOSink get stdout => io.stdout;
  io.IOSink get stderr => io.stderr;

  bool get hasTerminal => io.stdout.hasTerminal;
  int get terminalColumns => hasTerminal ? io.stdout.terminalColumns : null;
  int get terminalLines => hasTerminal ? io.stdout.terminalLines : null;
  bool get supportsAnsiEscapes => hasTerminal ? io.stdout.supportsAnsiEscapes : false;
}

io.IOSink get stderr => context[Stdio].stderr;

Stream<List<int>> get stdin => context[Stdio].stdin;

io.IOSink get stdout => context[Stdio].stdout;

Stdio get stdio => context[Stdio];
