// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

// TODO(ager): The only reason for this class is that we
// cannot patch a top-level at this point.
class _ProcessUtils {
  external static Never _exit(int status);
  external static void _setExitCode(int status);
  external static int _getExitCode();
  external static void _sleep(int millis);
  external static int _pid(Process? process);
  external static Stream<ProcessSignal> _watchSignal(ProcessSignal signal);
}

/// Exit the Dart VM process immediately with the given exit code.
///
/// This does not wait for any asynchronous operations to terminate nor execute
/// `finally` blocks. Using [exit] is therefore very likely to lose data.
///
/// Child processes are not explicitly terminated (but they may terminate
/// themselves when they detect that their parent has exited).
///
/// While debugging, the VM will not respect the `--pause-isolates-on-exit`
/// flag if [exit] is called as invoking this method causes the Dart VM
/// process to shutdown immediately. To properly break on exit, consider
/// calling [debugger] from `dart:developer` or [Isolate.pause] from
/// `dart:isolate` on [Isolate.current] to pause the isolate before
/// invoking [exit].
///
/// The handling of exit codes is platform specific.
///
/// On Linux and OS X an exit code for normal termination will always
/// be in the range `[0..255]`. If an exit code outside this range is
/// set the actual exit code will be the lower 8 bits masked off and
/// treated as an unsigned value. E.g. using an exit code of -1 will
/// result in an actual exit code of 255 being reported.
///
/// On Windows the exit code can be set to any 32-bit value. However
/// some of these values are reserved for reporting system errors like
/// crashes.
///
/// Besides this the Dart executable itself uses an exit code of `254`
/// for reporting compile time errors and an exit code of `255` for
/// reporting runtime error (unhandled exception).
///
/// Due to these facts it is recommended to only use exit codes in the
/// range \[0..127\] for communicating the result of running a Dart
/// program to the surrounding environment. This will avoid any
/// cross-platform issues.
Never exit(int code) {
  ArgumentError.checkNotNull(code, "code");
  if (!_EmbedderConfig._mayExit) {
    throw new UnsupportedError(
        "This embedder disallows calling dart:io's exit()");
  }
  _ProcessUtils._exit(code);
}

/// Set the global exit code for the Dart VM.
///
/// The exit code is global for the Dart VM and the last assignment to
/// exitCode from any isolate determines the exit code of the Dart VM
/// on normal termination.
///
/// Default value is `0`.
///
/// See [exit] for more information on how to chose a value for the
/// exit code.
void set exitCode(int code) {
  ArgumentError.checkNotNull(code, "code");
  _ProcessUtils._setExitCode(code);
}

/// Get the global exit code for the Dart VM.
///
/// The exit code is global for the Dart VM and the last assignment to
/// exitCode from any isolate determines the exit code of the Dart VM
/// on normal termination.
///
/// See [exit] for more information on how to chose a value for the
/// exit code.
int get exitCode => _ProcessUtils._getExitCode();

/// Sleep for the duration specified in [duration].
///
/// Use this with care, as no asynchronous operations can be processed
/// in a isolate while it is blocked in a [sleep] call.
/// ```dart
/// var duration = const Duration(seconds: 5);
/// print('Start sleeping');
/// sleep(duration);
/// print('5 seconds has passed');
/// ```
void sleep(Duration duration) {
  int milliseconds = duration.inMilliseconds;
  if (milliseconds < 0) {
    throw new ArgumentError("sleep: duration cannot be negative");
  }
  if (!_EmbedderConfig._maySleep) {
    throw new UnsupportedError(
        "This embedder disallows calling dart:io's sleep()");
  }
  _ProcessUtils._sleep(milliseconds);
}

/// Returns the PID of the current process.
int get pid => _ProcessUtils._pid(null);

/// Methods for retrieving information about the current process.
abstract final class ProcessInfo {
  /// The current resident set size of memory for the process, in bytes.
  ///
  /// Note that the meaning of this field is platform dependent. For example,
  /// some memory accounted for here may be shared with other processes, or if
  /// the same page is mapped into a process's address space, it may be counted
  /// twice.
  external static int get currentRss;

  /// The high-watermark in bytes for the resident set size of memory for the
  /// process.
  ///
  /// Note that the meaning of this field is platform dependent. For example,
  /// some memory accounted for here may be shared with other processes, or if
  /// the same page is mapped into a process's address space, it may be counted
  /// twice.
  external static int get maxRss;
}

/// Modes for running a new process.
final class ProcessStartMode {
  /// Normal child process.
  static const normal = const ProcessStartMode._internal(0);

  /// Stdio handles are inherited by the child process.
  static const inheritStdio = const ProcessStartMode._internal(1);

  /// Detached child process with no open communication channel.
  static const detached = const ProcessStartMode._internal(2);

  /// Detached child process with stdin, stdout and stderr still open
  /// for communication with the child.
  static const detachedWithStdio = const ProcessStartMode._internal(3);

  static List<ProcessStartMode> get values => const <ProcessStartMode>[
        normal,
        inheritStdio,
        detached,
        detachedWithStdio
      ];
  String toString() =>
      const ["normal", "inheritStdio", "detached", "detachedWithStdio"][_mode];

  final int _mode;
  const ProcessStartMode._internal(this._mode);
}

/// The means to execute a program.
///
/// Use the static [start] and [run] methods to start a new process.
/// The run method executes the process non-interactively to completion.
/// In contrast, the start method allows your code to interact with the
/// running process.
///
/// ## Start a process with the run method
///
/// The following code sample uses the run method to create a process
/// that runs the UNIX command `ls`, which lists the contents of a directory.
/// The run method completes with a [ProcessResult] object when the process
/// terminates. This provides access to the output and exit code from the
/// process. The run method does not return a `Process` object;
/// this prevents your code from interacting with the running process.
/// ```dart
/// import 'dart:io';
///
/// main() async {
///   // List all files in the current directory in UNIX-like systems.
///   var result = await Process.run('ls', ['-l']);
///   print(result.stdout);
/// }
/// ```
/// ## Start a process with the start method
///
/// The following example uses start to create the process.
/// The start method returns a [Future] for a `Process` object.
/// When the future completes the process is started and
/// your code can interact with the process:
/// writing to stdin, listening to stdout, and so on.
///
/// The following sample starts the UNIX `cat` utility, which when given no
/// command-line arguments, echos its input.
/// The program writes to the process's standard input stream
/// and prints data from its standard output stream.
/// ```dart
/// import 'dart:io';
/// import 'dart:convert';
///
/// main() async {
///   var process = await Process.start('cat', []);
///   process.stdout
///       .transform(utf8.decoder)
///       .forEach(print);
///   process.stdin.writeln('Hello, world!');
///   process.stdin.writeln('Hello, galaxy!');
///   process.stdin.writeln('Hello, universe!');
/// }
/// ```
/// ## Standard I/O streams
///
/// As seen in the previous code sample, you can interact with the `Process`'s
/// standard output stream through the getter [stdout],
/// and you can interact with the `Process`'s standard input stream through
/// the getter [stdin].
/// In addition, `Process` provides a getter [stderr] for using the `Process`'s
/// standard error stream.
///
/// A `Process`'s streams are distinct from the top-level streams
/// for the current program.
///
/// **NOTE:**
/// `stdin`, `stdout`, and `stderr` are implemented using pipes between
/// the parent process and the spawned subprocess. These pipes have limited
/// capacity. If the subprocess writes to stderr or stdout in excess of that
/// limit without the output being read, the subprocess blocks waiting for
/// the pipe buffer to accept more data. For example:
///
/// ```dart
/// import 'dart:io';
///
/// main() async {
///   var process = await Process.start('cat', ['largefile.txt']);
///   // The following await statement will never complete because the
///   // subprocess never exits since it is blocked waiting for its
///   // stdout to be read.
///   await process.stderr.forEach(print);
/// }
/// ```
///
/// ## Exit codes
///
/// Call the [exitCode] method to get the exit code of the process.
/// The exit code indicates whether the program terminated successfully
/// (usually indicated with an exit code of 0) or with an error.
///
/// If the start method is used, the [exitCode] is available through a future
/// on the `Process` object (as shown in the example below).
/// If the run method is used, the [exitCode] is available
/// through a getter on the [ProcessResult] instance.
/// ```dart
/// import 'dart:io';
///
/// main() async {
///   var process = await Process.start('ls', ['-l']);
///   var exitCode = await process.exitCode;
///   print('exit code: $exitCode');
/// }
/// ```
abstract interface class Process {
  /// A `Future` which completes with the exit code of the process
  /// when the process completes.
  ///
  /// The exit code is not available for processes running with
  /// [ProcessStartMode.detached] or [ProcessStartMode.detachedWithStdio] and
  /// the getter will throw [StateError] if it is used.
  ///
  /// The handling of exit codes is platform specific.
  ///
  /// On Linux and OS X a normal exit code will be a positive value in
  /// the range `[0..255]`. If the process was terminated due to a signal
  /// the exit code will be a negative value in the range `[-255..-1]`,
  /// where the absolute value of the exit code is the signal
  /// number. For example, if a process crashes due to a segmentation
  /// violation the exit code will be -11, as the signal SIGSEGV has the
  /// number 11.
  ///
  /// On Windows a process can report any 32-bit value as an exit
  /// code. When returning the exit code this exit code is turned into
  /// a signed value. Some special values are used to report
  /// termination due to some system event. E.g. if a process crashes
  /// due to an access violation the 32-bit exit code is `0xc0000005`,
  /// which will be returned as the negative number `-1073741819`. To
  /// get the original 32-bit value use `(0x100000000 + exitCode) &
  /// 0xffffffff`.
  ///
  /// There is no guarantee that [stdout] and [stderr] have finished reporting
  /// the buffered output of the process when the returned future completes.
  /// To be sure that all output is captured,
  /// wait for the done event on the streams.
  Future<int> get exitCode;

  /// Starts a process running the [executable] with the specified
  /// [arguments].
  ///
  /// Returns a `Future<Process>` that completes with a
  /// [Process] instance when the process has been successfully
  /// started. That [Process] object can be used to interact with the
  /// process. If the process cannot be started the returned [Future]
  /// completes with an exception.
  ///
  /// Using an absolute path for [executable] is recommended since resolving
  /// the [executable] path is platform-specific. On Windows, both any `PATH`
  /// set in the [environment] map parameter and the path set in
  /// [workingDirectory] parameter are ignored for the purposes of resolving
  /// the [executable] path.
  ///
  /// Use [workingDirectory] to set the working directory for the process. Note
  /// that the change of directory occurs before executing the process on some
  /// platforms, which may have impact when using relative paths for the
  /// executable and the arguments.
  ///
  /// Use [environment] to set the environment variables for the process. If not
  /// set the environment of the parent process is inherited. Currently, only
  /// US-ASCII environment variables are supported and errors are likely to occur
  /// if an environment variable with code-points outside the US-ASCII range is
  /// passed in.
  ///
  /// If [includeParentEnvironment] is `true`, the process's environment will
  /// include the parent process's environment, with [environment] taking
  /// precedence. Default is `true`.
  ///
  /// If [runInShell] is `true`, the process will be spawned through a system
  /// shell. On Linux and OS X, `/bin/sh` is used, while
  /// `%WINDIR%\system32\cmd.exe` is used on Windows.
  ///
  /// **NOTE**: On Windows, if [executable] is a batch file
  /// ('*.bat' or '*.cmd'), it may be launched by the operating system in a
  /// system shell regardless of the value of [runInShell]. This could result in
  /// arguments being parsed according to shell rules. For example:
  ///
  /// ```
  /// void main() async {
  ///   // Will launch notepad.
  ///   Process.start('test.bat', ['test&notepad.exe']);
  /// }
  /// ```
  ///
  /// Users must read all data coming on the [stdout] and [stderr]
  /// streams of processes started with `Process.start`. If the user
  /// does not read all data on the streams the underlying system
  /// resources will not be released since there is still pending data.
  ///
  /// The following code uses `Process.start` to grep for `main` in the
  /// file `test.dart` on Linux.
  /// ```dart
  /// var process = await Process.start('grep', ['-i', 'main', 'test.dart']);
  /// stdout.addStream(process.stdout);
  /// stderr.addStream(process.stderr);
  /// ```
  /// If [mode] is [ProcessStartMode.normal] (the default) a child
  /// process will be started with `stdin`, `stdout` and `stderr`
  /// connected to its parent. The parent process will not exit so long as the
  /// child is running, unless [exit] is called by the parent. If [exit] is
  /// called by the parent then the parent will be terminated but the child
  /// will continue running.
  ///
  /// If `mode` is [ProcessStartMode.detached] a detached process will
  /// be created. A detached process has no connection to its parent,
  /// and can keep running on its own when the parent dies. The only
  /// information available from a detached process is its `pid`. There
  /// is no connection to its `stdin`, `stdout` or `stderr`, nor will
  /// the process' exit code become available when it terminates.
  ///
  /// If `mode` is [ProcessStartMode.detachedWithStdio] a detached
  /// process will be created where the `stdin`, `stdout` and `stderr`
  /// are connected. The creator can communicate with the child through
  /// these. The detached process will keep running even if these
  /// communication channels are closed or the parent dies. The process'
  /// exit code will not become available when it terminated.
  ///
  /// The default value for `mode` is `ProcessStartMode.normal`.
  external static Future<Process> start(
      String executable, List<String> arguments,
      {String? workingDirectory,
      Map<String, String>? environment,
      bool includeParentEnvironment = true,
      bool runInShell = false,
      ProcessStartMode mode = ProcessStartMode.normal});

  /// Starts a process and runs it non-interactively to completion. The
  /// process run is [executable] with the specified [arguments].
  ///
  /// Using an absolute path for [executable] is recommended since resolving
  /// the [executable] path is platform-specific. On Windows, both any `PATH`
  /// set in the [environment] map parameter and the path set in
  /// [workingDirectory] parameter are ignored for the purposes of resolving
  /// the [executable] path.
  ///
  /// Use [workingDirectory] to set the working directory for the process. Note
  /// that the change of directory occurs before executing the process on some
  /// platforms, which may have impact when using relative paths for the
  /// executable and the arguments.
  ///
  /// Use [environment] to set the environment variables for the process. If not
  /// set the environment of the parent process is inherited. Currently, only
  /// US-ASCII environment variables are supported and errors are likely to occur
  /// if an environment variable with code-points outside the US-ASCII range is
  /// passed in.
  ///
  /// If [includeParentEnvironment] is `true`, the process's environment will
  /// include the parent process's environment, with [environment] taking
  /// precedence. Default is `true`.
  ///
  /// If [runInShell] is true, the process will be spawned through a system
  /// shell. On Linux and OS X, `/bin/sh` is used, while
  /// `%WINDIR%\system32\cmd.exe` is used on Windows.
  ///
  /// **NOTE**: On Windows, if [executable] is a batch file
  /// ('*.bat' or '*.cmd'), it may be launched by the operating system in a
  /// system shell regardless of the value of [runInShell]. This could result in
  /// arguments being parsed according to shell rules. For example:
  ///
  /// ```
  /// void main() async {
  ///   // Will launch notepad.
  ///   await Process.run('test.bat', ['test&notepad.exe']);
  /// }
  /// ```
  ///
  /// The encoding used for decoding `stdout` and `stderr` into text is
  /// controlled through [stdoutEncoding] and [stderrEncoding]. The
  /// default encoding is [systemEncoding]. If `null` is used no
  /// decoding will happen and the [ProcessResult] will hold binary
  /// data.
  ///
  /// Returns a `Future<ProcessResult>` that completes with the
  /// result of running the process, i.e., exit code, standard out and
  /// standard in.
  ///
  /// The following code uses `Process.run` to grep for `main` in the
  /// file `test.dart` on Linux.
  /// ```dart
  /// var result = await Process.run('grep', ['-i', 'main', 'test.dart']);
  /// stdout.write(result.stdout);
  /// stderr.write(result.stderr);
  /// ```
  external static Future<ProcessResult> run(
      String executable, List<String> arguments,
      {String? workingDirectory,
      Map<String, String>? environment,
      bool includeParentEnvironment = true,
      bool runInShell = false,
      Encoding? stdoutEncoding = systemEncoding,
      Encoding? stderrEncoding = systemEncoding});

  /// Starts a process and runs it to completion. This is a synchronous
  /// call and will block until the child process terminates.
  ///
  /// The arguments are the same as for [Process.run].
  ///
  /// Returns a [ProcessResult] with the result of running the process,
  /// i.e., exit code, standard out and standard in.
  external static ProcessResult runSync(
      String executable, List<String> arguments,
      {String? workingDirectory,
      Map<String, String>? environment,
      bool includeParentEnvironment = true,
      bool runInShell = false,
      Encoding? stdoutEncoding = systemEncoding,
      Encoding? stderrEncoding = systemEncoding});

  /// Kills the process with id [pid].
  ///
  /// Where possible, sends the [signal] to the process with id
  /// [pid]. This includes Linux and OS X. The default signal is
  /// [ProcessSignal.sigterm] which will normally terminate the
  /// process.
  ///
  /// On platforms without signal support, including Windows, the call
  /// just terminates the process with id [pid] in a platform specific
  /// way, and the [signal] parameter is ignored.
  ///
  /// Returns `true` if the signal is successfully delivered to the
  /// process. Otherwise the signal could not be sent, usually meaning
  /// that the process is already dead.
  external static bool killPid(int pid,
      [ProcessSignal signal = ProcessSignal.sigterm]);

  /// The standard output stream of the process as a `Stream`.
  ///
  /// **NOTE:**
  /// `stdin`, `stdout`, and `stderr` are implemented using pipes between
  /// the parent process and the spawned subprocess. These pipes have limited
  /// capacity. If the subprocess writes to stderr or stdout in excess of that
  /// limit without the output being read, the subprocess blocks waiting for
  /// the pipe buffer to accept more data. For example:
  ///
  /// ```dart
  /// import 'dart:io';
  ///
  /// main() async {
  ///   var process = await Process.start('cat', ['largefile.txt']);
  ///   // The following await statement will never complete because the
  ///   // subprocess never exits since it is blocked waiting for its
  ///   // stdout to be read.
  ///   await process.stderr.forEach(print);
  /// }
  /// ```
  Stream<List<int>> get stdout;

  /// The standard error stream of the process as a `Stream`.
  ///
  /// **NOTE:**
  /// `stdin`, `stdout`, and `stderr` are implemented using pipes between
  /// the parent process and the spawned subprocess. These pipes have limited
  /// capacity. If the subprocess writes to stderr or stdout in excess of that
  /// limit without the output being read, the subprocess blocks waiting for
  /// the pipe buffer to accept more data. For example:
  ///
  /// ```dart
  /// import 'dart:io';
  ///
  /// main() async {
  ///   var process = await Process.start('cat', ['largefile.txt']);
  ///   // The following await statement will never complete because the
  ///   // subprocess never exits since it is blocked waiting for its
  ///   // stdout to be read.
  ///   await process.stderr.forEach(print);
  /// }
  /// ```
  Stream<List<int>> get stderr;

  /// The standard input stream of the process as an [IOSink].
  IOSink get stdin;

  /// The process id of the process.
  int get pid;

  /// Kills the process.
  ///
  /// Where possible, sends the [signal] to the process. This includes
  /// Linux and OS X. The default signal is [ProcessSignal.sigterm]
  /// which will normally terminate the process.
  ///
  /// On platforms without signal support, including Windows, the call
  /// just terminates the process in a platform specific way, and the
  /// [signal] parameter is ignored.
  ///
  /// Returns `true` if the signal is successfully delivered to the
  /// process. Otherwise the signal could not be sent, usually meaning
  /// that the process is already dead.
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]);
}

/// The result of running a non-interactive
/// process started with [Process.run] or [Process.runSync].
final class ProcessResult {
  /// Exit code for the process.
  ///
  /// See [Process.exitCode] for more information in the exit code
  /// value.
  final int exitCode;

  /// Standard output from the process. The value used for the
  /// `stdoutEncoding` argument to `Process.run` determines the type. If
  /// `null` was used, this value is of type `List<int>` otherwise it is
  /// of type `String`.
  final stdout;

  /// Standard error from the process. The value used for the
  /// `stderrEncoding` argument to `Process.run` determines the type. If
  /// `null` was used, this value is of type `List<int>`
  /// otherwise it is of type `String`.
  final stderr;

  /// Process id of the process.
  final int pid;

  ProcessResult(this.pid, this.exitCode, this.stdout, this.stderr);
}

/// On Posix systems, [ProcessSignal] is used to send a specific signal
/// to a child process, see `Process.kill`.
///
/// Some [ProcessSignal]s can also be watched, as a way to intercept the default
/// signal handler and implement another. See [ProcessSignal.watch] for more
/// information.
interface class ProcessSignal {
  static const ProcessSignal sighup = const ProcessSignal._(1, "SIGHUP");
  static const ProcessSignal sigint = const ProcessSignal._(2, "SIGINT");
  static const ProcessSignal sigquit = const ProcessSignal._(3, "SIGQUIT");
  static const ProcessSignal sigill = const ProcessSignal._(4, "SIGILL");
  static const ProcessSignal sigtrap = const ProcessSignal._(5, "SIGTRAP");
  static const ProcessSignal sigabrt = const ProcessSignal._(6, "SIGABRT");
  static const ProcessSignal sigbus = const ProcessSignal._(7, "SIGBUS");
  static const ProcessSignal sigfpe = const ProcessSignal._(8, "SIGFPE");
  static const ProcessSignal sigkill = const ProcessSignal._(9, "SIGKILL");
  static const ProcessSignal sigusr1 = const ProcessSignal._(10, "SIGUSR1");
  static const ProcessSignal sigsegv = const ProcessSignal._(11, "SIGSEGV");
  static const ProcessSignal sigusr2 = const ProcessSignal._(12, "SIGUSR2");
  static const ProcessSignal sigpipe = const ProcessSignal._(13, "SIGPIPE");
  static const ProcessSignal sigalrm = const ProcessSignal._(14, "SIGALRM");
  static const ProcessSignal sigterm = const ProcessSignal._(15, "SIGTERM");
  static const ProcessSignal sigchld = const ProcessSignal._(17, "SIGCHLD");
  static const ProcessSignal sigcont = const ProcessSignal._(18, "SIGCONT");
  static const ProcessSignal sigstop = const ProcessSignal._(19, "SIGSTOP");
  static const ProcessSignal sigtstp = const ProcessSignal._(20, "SIGTSTP");
  static const ProcessSignal sigttin = const ProcessSignal._(21, "SIGTTIN");
  static const ProcessSignal sigttou = const ProcessSignal._(22, "SIGTTOU");
  static const ProcessSignal sigurg = const ProcessSignal._(23, "SIGURG");
  static const ProcessSignal sigxcpu = const ProcessSignal._(24, "SIGXCPU");
  static const ProcessSignal sigxfsz = const ProcessSignal._(25, "SIGXFSZ");
  static const ProcessSignal sigvtalrm = const ProcessSignal._(26, "SIGVTALRM");
  static const ProcessSignal sigprof = const ProcessSignal._(27, "SIGPROF");
  static const ProcessSignal sigwinch = const ProcessSignal._(28, "SIGWINCH");
  static const ProcessSignal sigpoll = const ProcessSignal._(29, "SIGPOLL");
  static const ProcessSignal sigsys = const ProcessSignal._(31, "SIGSYS");

  /// The numeric constant for the signal e.g. [ProcessSignal.signalNumber]
  /// will be 1 for [ProcessSignal.sighup] on most platforms.
  final int signalNumber;

  /// The POSIX-standardized name of the signal e.g. [ProcessSignal.name] will
  /// be "SIGHUP" for [ProcessSignal.sighup].
  final String name;

  const ProcessSignal._(this.signalNumber, this.name);

  String toString() => name;

  /// Watch for process signals.
  ///
  /// The following [ProcessSignal]s can be listened to:
  ///
  ///   * [ProcessSignal.sighup].
  ///   * [ProcessSignal.sigint]. Signal sent by e.g. CTRL-C.
  ///   * [ProcessSignal.sigterm]. Not available on Windows.
  ///   * [ProcessSignal.sigusr1]. Not available on Windows.
  ///   * [ProcessSignal.sigusr2]. Not available on Windows.
  ///   * [ProcessSignal.sigwinch]. Not available on Windows.
  ///
  /// Other signals are disallowed, as they may be used by the VM.
  ///
  /// A signal can be watched multiple times, from multiple isolates, where all
  /// callbacks are invoked when signaled, in no specific order.
  Stream<ProcessSignal> watch() => _ProcessUtils._watchSignal(this);
}

class SignalException implements IOException {
  final String message;
  final osError;

  const SignalException(this.message, [this.osError]);

  String toString() {
    var msg = "";
    if (osError != null) {
      msg = ", osError: $osError";
    }
    return "SignalException: $message$msg";
  }
}

class ProcessException implements IOException {
  /// The executable provided for the process.
  final String executable;

  /// The arguments provided for the process.
  final List<String> arguments;

  /// The system message for the process exception, if any.
  ///
  /// The empty string if no message was available.
  final String message;

  /// The OS error code for the process exception, if any.
  ///
  /// The value is zero if no OS error code was available.
  final int errorCode;

  const ProcessException(this.executable, this.arguments,
      [this.message = "", this.errorCode = 0]);
  String toString() {
    var args = arguments.join(' ');
    return "ProcessException: $message\n  Command: $executable $args";
  }
}
