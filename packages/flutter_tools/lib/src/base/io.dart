import 'dart:io' as io show exit, exitCode;

import 'package:meta/meta.dart';

export 'dart:io'
    show
        BytesBuilder,
        exitCode,
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
        pid,
        Platform,
        Process,
        ProcessException,
        ProcessResult,
        ProcessSignal,
        ProcessStartMode,
        ServerSocket,
        stderr,
        stdin,
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
/// During tests, this may be set to a testing-friendly value by calling
/// [setExitFunctionForTests] (and then restored with [restoreExitFunction]).
ExitFunction get exit => _exitFunction;

/// Sets the [exit] function to a function that throws an exception rather
/// than exiting the process; intended for testing purposes.
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
