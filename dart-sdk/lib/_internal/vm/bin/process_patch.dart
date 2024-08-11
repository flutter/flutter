// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "common_patch.dart";

@patch
class _WindowsCodePageDecoder {
  @patch
  @pragma("vm:external-name", "SystemEncodingToString")
  external static String _decodeBytes(List<int> bytes);
}

@patch
class _WindowsCodePageEncoder {
  @patch
  @pragma("vm:external-name", "StringToSystemEncoding")
  external static List<int> _encodeString(String string);
}

@patch
class Process {
  @patch
  static Future<Process> start(String executable, List<String> arguments,
      {String? workingDirectory,
      Map<String, String>? environment,
      bool includeParentEnvironment = true,
      bool runInShell = false,
      ProcessStartMode mode = ProcessStartMode.normal}) {
    _ProcessImpl process = new _ProcessImpl(
        executable,
        arguments,
        workingDirectory,
        environment,
        includeParentEnvironment,
        runInShell,
        mode);
    return process._start();
  }

  @patch
  static Future<ProcessResult> run(String executable, List<String> arguments,
      {String? workingDirectory,
      Map<String, String>? environment,
      bool includeParentEnvironment = true,
      bool runInShell = false,
      Encoding? stdoutEncoding = systemEncoding,
      Encoding? stderrEncoding = systemEncoding}) {
    return _runNonInteractiveProcess(
        executable,
        arguments,
        workingDirectory,
        environment,
        includeParentEnvironment,
        runInShell,
        stdoutEncoding,
        stderrEncoding);
  }

  @patch
  static ProcessResult runSync(String executable, List<String> arguments,
      {String? workingDirectory,
      Map<String, String>? environment,
      bool includeParentEnvironment = true,
      bool runInShell = false,
      Encoding? stdoutEncoding = systemEncoding,
      Encoding? stderrEncoding = systemEncoding}) {
    return _runNonInteractiveProcessSync(
        executable,
        arguments,
        workingDirectory,
        environment,
        includeParentEnvironment,
        runInShell,
        stdoutEncoding,
        stderrEncoding);
  }

  @patch
  static bool killPid(int pid, [ProcessSignal signal = ProcessSignal.sigterm]) {
    // TODO(40614): Remove once non-nullability is sound.
    ArgumentError.checkNotNull(signal, "signal");
    return _ProcessUtils._killPid(pid, signal.signalNumber);
  }
}

List<_SignalController?> _signalControllers = new List.filled(32, null);

class _SignalController {
  final ProcessSignal signal;

  final _controller = new StreamController<ProcessSignal>.broadcast();
  var _id;

  _SignalController(this.signal) {
    _controller
      ..onListen = _listen
      ..onCancel = _cancel;
  }

  Stream<ProcessSignal> get stream => _controller.stream;

  void _listen() {
    var id = _setSignalHandler(signal.signalNumber);
    if (id is! int) {
      _controller
          .addError(new SignalException("Failed to listen for $signal", id));
      return;
    }
    _id = id;
    var socket = new _RawSocket(new _NativeSocket.watchSignal(id));
    socket.listen((event) {
      if (event == RawSocketEvent.read) {
        var bytes = socket.read()!;
        for (int i = 0; i < bytes.length; i++) {
          _controller.add(signal);
        }
      }
    });
  }

  void _cancel() {
    if (_id != null) {
      _clearSignalHandler(signal.signalNumber);
      _id = null;
    }
  }

  @pragma("vm:external-name", "Process_SetSignalHandler")
  external static _setSignalHandler(int signal);
  @pragma("vm:external-name", "Process_ClearSignalHandler")
  external static void _clearSignalHandler(int signal);
}

@pragma("vm:entry-point", "call")
Function _getWatchSignalInternal() => _ProcessUtils._watchSignalInternal;

@patch
class _ProcessUtils {
  @patch
  @pragma("vm:external-name", "Process_Exit")
  external static Never _exit(int status);
  @patch
  @pragma("vm:external-name", "Process_SetExitCode")
  external static void _setExitCode(int status);
  @patch
  @pragma("vm:external-name", "Process_GetExitCode")
  external static int _getExitCode();
  @patch
  @pragma("vm:external-name", "Process_Sleep")
  external static void _sleep(int millis);
  @patch
  @pragma("vm:external-name", "Process_Pid")
  external static int _pid(Process? process);
  @pragma("vm:external-name", "Process_KillPid")
  external static bool _killPid(int pid, int signal);
  @patch
  static Stream<ProcessSignal> _watchSignal(ProcessSignal signal) {
    if (signal != ProcessSignal.sighup &&
        signal != ProcessSignal.sigint &&
        signal != ProcessSignal.sigterm &&
        (Platform.isWindows ||
            (signal != ProcessSignal.sigusr1 &&
                signal != ProcessSignal.sigusr2 &&
                signal != ProcessSignal.sigwinch))) {
      throw new SignalException(
          "Listening for signal $signal is not supported");
    }
    return _watchSignalInternal(signal);
  }

  static Stream<ProcessSignal> _watchSignalInternal(ProcessSignal signal) {
    if (_signalControllers[signal.signalNumber] == null) {
      _signalControllers[signal.signalNumber] = new _SignalController(signal);
    }
    return _signalControllers[signal.signalNumber]!.stream;
  }
}

@patch
class ProcessInfo {
  @patch
  static int get maxRss {
    var result = _maxRss();
    if (result is OSError) {
      throw result;
    }
    return result;
  }

  @patch
  static int get currentRss {
    var result = _currentRss();
    if (result is OSError) {
      throw result;
    }
    return result;
  }

  @pragma("vm:external-name", "ProcessInfo_MaxRSS")
  external static _maxRss();
  @pragma("vm:external-name", "ProcessInfo_CurrentRSS")
  external static _currentRss();
}

@pragma("vm:entry-point")
class _ProcessStartStatus {
  @pragma("vm:entry-point", "set")
  int? _errorCode; // Set to OS error code if process start failed.
  @pragma("vm:entry-point", "set")
  String? _errorMessage; // Set to OS error message if process start failed.
}

// The NativeFieldWrapperClass1 can not be used with a mixin, due to missing
// implicit constructor.
base class _ProcessImplNativeWrapper extends NativeFieldWrapperClass1 {}

base class _ProcessImpl extends _ProcessImplNativeWrapper implements _Process {
  static bool connectedResourceHandler = false;

  _ProcessImpl(
      String path,
      List<String> arguments,
      this._workingDirectory,
      Map<String, String>? environment,
      bool includeParentEnvironment,
      bool runInShell,
      this._mode)
      : super() {
    // TODO(40614): Remove once non-nullability is sound.
    ArgumentError.checkNotNull(path, "path");
    ArgumentError.checkNotNull(arguments, "arguments");
    for (int i = 0; i < arguments.length; i++) {
      ArgumentError.checkNotNull(arguments[i], "arguments[]");
    }
    ArgumentError.checkNotNull(_mode, "mode");

    if (!const bool.fromEnvironment("dart.vm.product") &&
        !connectedResourceHandler) {
      registerExtension('ext.dart.io.getSpawnedProcesses',
          _SpawnedProcessResourceInfo.getStartedProcesses);
      registerExtension('ext.dart.io.getSpawnedProcessById',
          _SpawnedProcessResourceInfo.getProcessInfoMapById);
      connectedResourceHandler = true;
    }

    if (runInShell) {
      arguments = _getShellArguments(path, arguments);
      path = _getShellCommand();
    }

    if (Platform.isWindows && path.contains(' ') && !path.contains('"')) {
      // Escape paths that may contain spaces
      // Bug: https://github.com/dart-lang/sdk/issues/37751
      _path = '"$path"';
    } else {
      _path = path;
    }

    _arguments = [
      for (int i = 0; i < arguments.length; i++)
        Platform.isWindows
            ? _windowsArgumentEscape(arguments[i])
            : arguments[i],
    ];

    _environment = [];
    // Ensure that we have a non-null environment.
    environment ??= const {};
    environment.forEach((key, value) {
      _environment.add('$key=$value');
    });
    if (includeParentEnvironment) {
      Platform.environment.forEach((key, value) {
        // Do not override keys already set as part of environment.
        if (!environment!.containsKey(key)) {
          _environment.add('$key=$value');
        }
      });
    }

    if (_modeHasStdio(_mode)) {
      // stdin going to process.
      _stdin = new _StdSink(new _Socket._writePipe().._owner = this);
      // stdout coming from process.
      _stdout = new _StdStream(new _Socket._readPipe().._owner = this);
      // stderr coming from process.
      _stderr = new _StdStream(new _Socket._readPipe().._owner = this);
    }
    if (_modeIsAttached(_mode)) {
      _exitHandler = new _Socket._readPipe();
    }
  }

  _NativeSocket get _stdinNativeSocket =>
      (_stdin!._sink as _Socket)._nativeSocket;
  _NativeSocket get _stdoutNativeSocket =>
      (_stdout!._stream as _Socket)._nativeSocket;
  _NativeSocket get _stderrNativeSocket =>
      (_stderr!._stream as _Socket)._nativeSocket;

  static bool _modeIsAttached(ProcessStartMode mode) {
    return (mode == ProcessStartMode.normal) ||
        (mode == ProcessStartMode.inheritStdio);
  }

  static bool _modeHasStdio(ProcessStartMode mode) {
    return (mode == ProcessStartMode.normal) ||
        (mode == ProcessStartMode.detachedWithStdio);
  }

  static String _getShellCommand() {
    if (Platform.isWindows) {
      return 'cmd.exe';
    }
    return '/bin/sh';
  }

  static List<String> _getShellArguments(
      String executable, List<String> arguments) {
    List<String> shellArguments = [];
    if (Platform.isWindows) {
      shellArguments.add('/c');
      shellArguments.add(executable);
      for (var arg in arguments) {
        shellArguments.add(arg);
      }
    } else {
      var commandLine = new StringBuffer();
      executable = executable.replaceAll("'", "'\"'\"'");
      commandLine.write("'$executable'");
      shellArguments.add("-c");
      for (var arg in arguments) {
        arg = arg.replaceAll("'", "'\"'\"'");
        commandLine.write(" '$arg'");
      }
      shellArguments.add(commandLine.toString());
    }
    return shellArguments;
  }

  String _windowsArgumentEscape(String argument) {
    if (argument.isEmpty) {
      return '""';
    }
    var result = argument;
    if (argument.contains('\t') ||
        argument.contains(' ') ||
        argument.contains('"')) {
      // Produce something that the C runtime on Windows will parse
      // back as this string.

      // Replace any number of '\' followed by '"' with
      // twice as many '\' followed by '\"'.
      var backslash = '\\'.codeUnitAt(0);
      var sb = new StringBuffer();
      var nextPos = 0;
      var quotePos = argument.indexOf('"', nextPos);
      while (quotePos != -1) {
        var numBackslash = 0;
        var pos = quotePos - 1;
        while (pos >= 0 && argument.codeUnitAt(pos) == backslash) {
          numBackslash++;
          pos--;
        }
        sb.write(argument.substring(nextPos, quotePos - numBackslash));
        for (var i = 0; i < numBackslash; i++) {
          sb.write(r'\\');
        }
        sb.write(r'\"');
        nextPos = quotePos + 1;
        quotePos = argument.indexOf('"', nextPos);
      }
      sb.write(argument.substring(nextPos, argument.length));
      result = sb.toString();

      // Add '"' at the beginning and end and replace all '\' at
      // the end with two '\'.
      sb = new StringBuffer('"');
      sb.write(result);
      nextPos = argument.length - 1;
      while (argument.codeUnitAt(nextPos) == backslash) {
        sb.write('\\');
        nextPos--;
      }
      sb.write('"');
      result = sb.toString();
    }

    return result;
  }

  int _intFromBytes(List<int> bytes, int offset) {
    return (bytes[offset] +
        (bytes[offset + 1] << 8) +
        (bytes[offset + 2] << 16) +
        (bytes[offset + 3] << 24));
  }

  Future<Process> _start() {
    var completer = new Completer<Process>();
    var stackTrace = StackTrace.current;
    if (_modeIsAttached(_mode)) {
      _exitCode = new Completer<int>();
    }
    // TODO(ager): Make the actual process starting really async instead of
    // simulating it with a timer.
    Timer.run(() {
      var status = new _ProcessStartStatus();
      bool success = _startNative(
          _Namespace._namespace,
          _path,
          _arguments,
          _workingDirectory,
          _environment,
          _mode._mode,
          _modeHasStdio(_mode) ? _stdinNativeSocket : null,
          _modeHasStdio(_mode) ? _stdoutNativeSocket : null,
          _modeHasStdio(_mode) ? _stderrNativeSocket : null,
          _modeIsAttached(_mode) ? _exitHandler._nativeSocket : null,
          status);
      if (!success) {
        completer.completeError(
            new ProcessException(
                _path, _arguments, status._errorMessage!, status._errorCode!),
            stackTrace);
        return;
      }

      _started = true;
      final resourceInfo = new _SpawnedProcessResourceInfo(this);

      // Setup an exit handler to handle internal cleanup and possible
      // callback when a process terminates.
      if (_modeIsAttached(_mode)) {
        int exitDataRead = 0;
        final int EXIT_DATA_SIZE = 8;
        List<int> exitDataBuffer = new List<int>.filled(EXIT_DATA_SIZE, 0);
        _exitHandler.listen((data) {
          int exitCode(List<int> ints) {
            var code = _intFromBytes(ints, 0);
            var negative = _intFromBytes(ints, 4);
            assert(negative == 0 || negative == 1);
            return (negative == 0) ? code : -code;
          }

          void handleExit() {
            _ended = true;
            _exitCode!.complete(exitCode(exitDataBuffer));
            // Kill stdin, helping hand if the user forgot to do it.
            if (_modeHasStdio(_mode)) {
              (_stdin!._sink as _Socket).destroy();
            }
            resourceInfo.stopped();
          }

          exitDataBuffer.setRange(
              exitDataRead, exitDataRead + data.length, data);
          exitDataRead += data.length;
          if (exitDataRead == EXIT_DATA_SIZE) {
            handleExit();
          }
        });
      }

      completer.complete(this);
    });
    return completer.future;
  }

  ProcessResult _runAndWait(
      Encoding? stdoutEncoding, Encoding? stderrEncoding) {
    var status = new _ProcessStartStatus();
    _exitCode = new Completer<int>();
    bool success = _startNative(
        _Namespace._namespace,
        _path,
        _arguments,
        _workingDirectory,
        _environment,
        ProcessStartMode.normal._mode,
        _stdinNativeSocket,
        _stdoutNativeSocket,
        _stderrNativeSocket,
        _exitHandler._nativeSocket,
        status);
    if (!success) {
      throw new ProcessException(
          _path, _arguments, status._errorMessage!, status._errorCode!);
    }

    final resourceInfo = new _SpawnedProcessResourceInfo(this);

    var result = _wait(_stdinNativeSocket, _stdoutNativeSocket,
        _stderrNativeSocket, _exitHandler._nativeSocket);

    getOutput(output, encoding) {
      if (encoding == null) return output;
      return encoding.decode(output);
    }

    resourceInfo.stopped();

    return new ProcessResult(
        result[0],
        result[1],
        getOutput(result[2], stdoutEncoding),
        getOutput(result[3], stderrEncoding));
  }

  @pragma("vm:external-name", "Process_Start")
  external bool _startNative(
      _Namespace namespace,
      String path,
      List<String> arguments,
      String? workingDirectory,
      List<String> environment,
      int mode,
      _NativeSocket? stdin,
      _NativeSocket? stdout,
      _NativeSocket? stderr,
      _NativeSocket? exitHandler,
      _ProcessStartStatus status);

  @pragma("vm:external-name", "Process_Wait")
  external _wait(_NativeSocket? stdin, _NativeSocket? stdout,
      _NativeSocket? stderr, _NativeSocket exitHandler);

  Stream<List<int>> get stdout =>
      _stdout ?? (throw StateError("stdio is not connected"));

  Stream<List<int>> get stderr =>
      _stderr ?? (throw StateError("stdio is not connected"));

  IOSink get stdin => _stdin ?? (throw StateError("stdio is not connected"));

  Future<int> get exitCode =>
      _exitCode?.future ?? (throw StateError("Process is detached"));

  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    // TODO(40614): Remove once non-nullability is sound.
    ArgumentError.checkNotNull(kill, "kill");
    assert(_started);
    if (_ended) return false;
    return _ProcessUtils._killPid(pid, signal.signalNumber);
  }

  int get pid => _ProcessUtils._pid(this);

  late String _path;
  late List<String> _arguments;
  String? _workingDirectory;
  late List<String> _environment;
  final ProcessStartMode _mode;
  // Private methods of Socket are used by _in, _out, and _err.
  _StdSink? _stdin;
  _StdStream? _stdout;
  _StdStream? _stderr;
  late _Socket _exitHandler;
  bool _ended = false;
  bool _started = false;
  Completer<int>? _exitCode;
}

// _NonInteractiveProcess is a wrapper around an interactive process
// that buffers output so it can be delivered when the process exits.
// _NonInteractiveProcess is used to implement the Process.run
// method.
Future<ProcessResult> _runNonInteractiveProcess(
    String path,
    List<String> arguments,
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment,
    bool runInShell,
    Encoding? stdoutEncoding,
    Encoding? stderrEncoding) {
  // Start the underlying process.
  return Process.start(path, arguments,
          workingDirectory: workingDirectory,
          environment: environment,
          includeParentEnvironment: includeParentEnvironment,
          runInShell: runInShell)
      .then((Process p) {
    int pid = p.pid;

    // Make sure the process stdin is closed.
    p.stdin.close();

    // Setup stdout and stderr handling.
    Future foldStream(Stream<List<int>> stream, Encoding? encoding) {
      if (encoding == null) {
        return stream
            .fold<BytesBuilder>(
                new BytesBuilder(), (builder, data) => builder..add(data))
            .then((builder) => builder.takeBytes());
      } else {
        return stream
            .transform(encoding.decoder)
            .fold<StringBuffer>(new StringBuffer(), (buf, data) {
          buf.write(data);
          return buf;
        }).then((sb) => sb.toString());
      }
    }

    Future stdout = foldStream(p.stdout, stdoutEncoding);
    Future stderr = foldStream(p.stderr, stderrEncoding);

    return Future.wait([p.exitCode, stdout, stderr]).then((result) {
      return new ProcessResult(pid, result[0], result[1], result[2]);
    });
  });
}

ProcessResult _runNonInteractiveProcessSync(
    String executable,
    List<String> arguments,
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment,
    bool runInShell,
    Encoding? stdoutEncoding,
    Encoding? stderrEncoding) {
  var process = new _ProcessImpl(
      executable,
      arguments,
      workingDirectory,
      environment,
      includeParentEnvironment,
      runInShell,
      ProcessStartMode.normal);
  return process._runAndWait(stdoutEncoding, stderrEncoding);
}
