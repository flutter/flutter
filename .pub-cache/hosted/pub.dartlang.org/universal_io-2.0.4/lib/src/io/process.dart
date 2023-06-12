// ------------------------------------------------------------------
// THIS FILE WAS DERIVED FROM SOURCE CODE UNDER THE FOLLOWING LICENSE
// ------------------------------------------------------------------
//
// Copyright 2012, the Dart project authors. All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
//       copyright notice, this list of conditions and the following
//       disclaimer in the documentation and/or other materials provided
//       with the distribution.
//     * Neither the name of Google Inc. nor the names of its
//       contributors may be used to endorse or promote products derived
//       from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// ---------------------------------------------------------
// THIS, DERIVED FILE IS LICENSE UNDER THE FOLLOWING LICENSE
// ---------------------------------------------------------
// Copyright 2020 terrier989@gmail.com.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import '../io_impl_js.dart';

/// Get the global exit code for the Dart VM.
///
/// The exit code is global for the Dart VM and the last assignment to
/// exitCode from any isolate determines the exit code of the Dart VM
/// on normal termination.
///
/// See [exit] for more information on how to chose a value for the
/// exit code.
int get exitCode => 0;

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
set exitCode(int code) {
  ArgumentError.checkNotNull(code, 'code');
}

/// Returns the PID of the current process.
int get pid => 0;

/// Exit the Dart VM process immediately with the given exit code.
///
/// This does not wait for any asynchronous operations to terminate nor execute
/// `finally` blocks. Using [exit] is therefore very likely to lose data.
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
/// be in the range [0..255]. If an exit code outside this range is
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
/// range [0..127] for communicating the result of running a Dart
/// program to the surrounding environment. This will avoid any
/// cross-platform issues.
Never exit(int code) {
  throw UnimplementedError();
}

/// Sleep for the duration specified in [duration].
///
/// Use this with care, as no asynchronous operations can be processed
/// in a isolate while it is blocked in a [sleep] call.
void sleep(Duration duration) {}

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
/// process. The run method does not return a Process object; this prevents your
/// code from interacting with the running process.
///
///     import 'dart:io';
///
///     main() {
///       // List all files in the current directory in UNIX-like systems.
///       Process.run('ls', ['-l']).then((ProcessResult results) {
///         print(results.stdout);
///       });
///     }
///
/// ## Start a process with the start method
///
/// The following example uses start to create the process.
/// The start method returns a [Future] for a Process object.
/// When the future completes the process is started and
/// your code can interact with the
/// Process: writing to stdin, listening to stdout, and so on.
///
/// The following sample starts the UNIX `cat` utility, which when given no
/// command-line arguments, echos its input.
/// The program writes to the process's standard input stream
/// and prints data from its standard output stream.
///
///     import 'dart:io';
///     import 'dart:convert';
///
///     main() {
///       Process.start('cat', []).then((Process process) {
///         process.stdout
///             .transform(utf8.decoder)
///             .listen((data) { print(data); });
///         process.stdin.writeln('Hello, world!');
///         process.stdin.writeln('Hello, galaxy!');
///         process.stdin.writeln('Hello, universe!');
///       });
///     }
///
/// ## Standard I/O streams
///
/// As seen in the previous code sample, you can interact with the Process's
/// standard output stream through the getter [stdout],
/// and you can interact with the Process's standard input stream through
/// the getter [stdin].
/// In addition, Process provides a getter [stderr] for using the Process's
/// standard error stream.
///
/// A Process's streams are distinct from the top-level streams
/// for the current program.
///
/// ## Exit codes
///
/// Call the [exitCode] method to get the exit code of the process.
/// The exit code indicates whether the program terminated successfully
/// (usually indicated with an exit code of 0) or with an error.
///
/// If the start method is used, the exitCode is available through a future
/// on the Process object (as shown in the example below).
/// If the run method is used, the exitCode is available
/// through a getter on the ProcessResult instance.
///
///     import 'dart:io';
///
///     main() {
///       Process.start('ls', ['-l']).then((process) {
///         // Get the exit code from the new process.
///         process.exitCode.then((exitCode) {
///           print('exit code: $exitCode');
///         });
///       });
///     }
abstract class Process {
  /// Returns a [:Future:] which completes with the exit code of the process
  /// when the process completes.
  ///
  /// The handling of exit codes is platform specific.
  ///
  /// On Linux and OS X a normal exit code will be a positive value in
  /// the range [0..255]. If the process was terminated due to a signal
  /// the exit code will be a negative value in the range [-255..-1],
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

  /// Returns the process id of the process.
  int get pid;

  /// Returns the standard error stream of the process as a [:Stream:].
  Stream<List<int>> get stderr;

  /// Returns the standard input stream of the process as an [IOSink].
  IOSink get stdin;

  /// Returns the standard output stream of the process as a [:Stream:].
  Stream<List<int>> get stdout;

  /// Kills the process.
  ///
  /// Where possible, sends the [signal] to the process. This includes
  /// Linux and OS X. The default signal is [ProcessSignal.sigterm]
  /// which will normally terminate the process.
  ///
  /// On platforms without signal support, including Windows, the call
  /// just terminates the process in a platform specific way, and the
  /// `signal` parameter is ignored.
  ///
  /// Returns `true` if the signal is successfully delivered to the
  /// process. Otherwise the signal could not be sent, usually meaning
  /// that the process is already dead.
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]);

  /// Kills the process with id [pid].
  ///
  /// Where possible, sends the [signal] to the process with id
  /// `pid`. This includes Linux and OS X. The default signal is
  /// [ProcessSignal.sigterm] which will normally terminate the
  /// process.
  ///
  /// On platforms without signal support, including Windows, the call
  /// just terminates the process with id `pid` in a platform specific
  /// way, and the `signal` parameter is ignored.
  ///
  /// Returns `true` if the signal is successfully delivered to the
  /// process. Otherwise the signal could not be sent, usually meaning
  /// that the process is already dead.
  static bool killPid(int pid,
          [ProcessSignal signal = ProcessSignal.sigterm]) =>
      throw UnimplementedError();

  /// Starts a process and runs it non-interactively to completion. The
  /// process run is [executable] with the specified [arguments].
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
  ///
  ///     Process.run('grep', ['-i', 'main', 'test.dart']).then((result) {
  ///       stdout.write(result.stdout);
  ///       stderr.write(result.stderr);
  ///     });
  static Future<ProcessResult> run(String executable, List<String> arguments,
          {String? workingDirectory,
          Map<String, String>? environment,
          bool includeParentEnvironment = true,
          bool runInShell = false,
          Encoding? stdoutEncoding = systemEncoding,
          Encoding? stderrEncoding = systemEncoding}) =>
      throw UnimplementedError();

  /// Starts a process and runs it to completion. This is a synchronous
  /// call and will block until the child process terminates.
  ///
  /// The arguments are the same as for `Process.run`.
  ///
  /// Returns a `ProcessResult` with the result of running the process,
  /// i.e., exit code, standard out and standard in.
  static ProcessResult runSync(String executable, List<String> arguments,
          {String? workingDirectory,
          Map<String, String>? environment,
          bool includeParentEnvironment = true,
          bool runInShell = false,
          Encoding? stdoutEncoding = systemEncoding,
          Encoding? stderrEncoding = systemEncoding}) =>
      throw UnimplementedError();

  /// Starts a process running the [executable] with the specified
  /// [arguments]. Returns a [:Future<Process>:] that completes with a
  /// Process instance when the process has been successfully
  /// started. That [Process] object can be used to interact with the
  /// process. If the process cannot be started the returned [Future]
  /// completes with an exception.
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
  /// shell. On Linux and OS X, [:/bin/sh:] is used, while
  /// [:%WINDIR%\system32\cmd.exe:] is used on Windows.
  ///
  /// Users must read all data coming on the [stdout] and [stderr]
  /// streams of processes started with [:Process.start:]. If the user
  /// does not read all data on the streams the underlying system
  /// resources will not be released since there is still pending data.
  ///
  /// The following code uses `Process.start` to grep for `main` in the
  /// file `test.dart` on Linux.
  ///
  ///     Process.start('grep', ['-i', 'main', 'test.dart']).then((process) {
  ///       stdout.addStream(process.stdout);
  ///       stderr.addStream(process.stderr);
  ///     });
  ///
  /// If [mode] is [ProcessStartMode.normal] (the default) a child
  /// process will be started with `stdin`, `stdout` and `stderr`
  /// connected.
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
  /// communication channels are closed. The process' exit code will
  /// not become available when it terminated.
  ///
  /// The default value for `mode` is `ProcessStartMode.normal`.
  static Future<Process> start(String executable, List<String> arguments,
          {String? workingDirectory,
          Map<String, String>? environment,
          bool includeParentEnvironment = true,
          bool runInShell = false,
          ProcessStartMode mode = ProcessStartMode.normal}) =>
      throw UnimplementedError();
}

class ProcessException implements IOException {
  /// Contains the executable provided for the process.
  final String executable;

  /// Contains the arguments provided for the process.
  final List<String> arguments;

  /// Contains the system message for the process exception if any.
  final String message;

  /// Contains the OS error code for the process exception if any.
  final int errorCode;

  const ProcessException(this.executable, this.arguments,
      [this.message = '', this.errorCode = 0]);

  @override
  String toString() {
    var args = arguments.join(' ');
    return 'ProcessException: $message\n  Command: $executable $args';
  }
}

/// [ProcessInfo] provides methods for retrieving information about the
/// current process.
abstract class ProcessInfo {
  /// The current resident set size of memory for the process.
  ///
  /// Note that the meaning of this field is platform dependent. For example,
  /// some memory accounted for here may be shared with other processes, or if
  /// the same page is mapped into a process's address space, it may be counted
  /// twice.
  static int get currentRss => throw UnimplementedError();

  /// The high-watermark in bytes for the resident set size of memory for the
  /// process.
  ///
  /// Note that the meaning of this field is platform dependent. For example,
  /// some memory accounted for here may be shared with other processes, or if
  /// the same page is mapped into a process's address space, it may be counted
  /// twice.
  static int get maxRss => throw UnimplementedError();
}

/// [ProcessResult] represents the result of running a non-interactive
/// process started with [Process.run] or [Process.runSync].
class ProcessResult {
  /// Exit code for the process.
  ///
  /// See [Process.exitCode] for more information in the exit code
  /// value.
  final int exitCode;

  /// Standard output from the process. The value used for the
  /// `stdoutEncoding` argument to `Process.run` determines the type. If
  /// `null` was used this value is of type `List<int>` otherwise it is
  /// of type `String`.
  final stdout;

  /// Standard error from the process. The value used for the
  /// `stderrEncoding` argument to `Process.run` determines the type. If
  /// `null` was used this value is of type `List<int>`
  /// otherwise it is of type `String`.
  final stderr;

  /// Process id of the process.
  final int pid;

  ProcessResult(this.pid, this.exitCode, this.stdout, this.stderr);
}

/// On Posix systems, [ProcessSignal] is used to send a specific signal
/// to a child process, see [:Process.kill:].
///
/// Some [ProcessSignal]s can also be watched, as a way to intercept the default
/// signal handler and implement another. See [ProcessSignal.watch] for more
/// information.
class ProcessSignal {
  static const ProcessSignal sighup = ProcessSignal._(1, 'SIGHUP');
  static const ProcessSignal sigint = ProcessSignal._(2, 'SIGINT');
  static const ProcessSignal sigquit = ProcessSignal._(3, 'SIGQUIT');
  static const ProcessSignal sigill = ProcessSignal._(4, 'SIGILL');
  static const ProcessSignal sigtrap = ProcessSignal._(5, 'SIGTRAP');
  static const ProcessSignal sigabrt = ProcessSignal._(6, 'SIGABRT');
  static const ProcessSignal sigbus = ProcessSignal._(7, 'SIGBUS');
  static const ProcessSignal sigfpe = ProcessSignal._(8, 'SIGFPE');
  static const ProcessSignal sigkill = ProcessSignal._(9, 'SIGKILL');
  static const ProcessSignal sigusr1 = ProcessSignal._(10, 'SIGUSR1');
  static const ProcessSignal sigsegv = ProcessSignal._(11, 'SIGSEGV');
  static const ProcessSignal sigusr2 = ProcessSignal._(12, 'SIGUSR2');
  static const ProcessSignal sigpipe = ProcessSignal._(13, 'SIGPIPE');
  static const ProcessSignal sigalrm = ProcessSignal._(14, 'SIGALRM');
  static const ProcessSignal sigterm = ProcessSignal._(15, 'SIGTERM');
  static const ProcessSignal sigchld = ProcessSignal._(17, 'SIGCHLD');
  static const ProcessSignal sigcont = ProcessSignal._(18, 'SIGCONT');
  static const ProcessSignal sigstop = ProcessSignal._(19, 'SIGSTOP');
  static const ProcessSignal sigtstp = ProcessSignal._(20, 'SIGTSTP');
  static const ProcessSignal sigttin = ProcessSignal._(21, 'SIGTTIN');
  static const ProcessSignal sigttou = ProcessSignal._(22, 'SIGTTOU');
  static const ProcessSignal sigurg = ProcessSignal._(23, 'SIGURG');
  static const ProcessSignal sigxcpu = ProcessSignal._(24, 'SIGXCPU');
  static const ProcessSignal sigxfsz = ProcessSignal._(25, 'SIGXFSZ');
  static const ProcessSignal sigvtalrm = ProcessSignal._(26, 'SIGVTALRM');
  static const ProcessSignal sigprof = ProcessSignal._(27, 'SIGPROF');
  static const ProcessSignal sigwinch = ProcessSignal._(28, 'SIGWINCH');
  static const ProcessSignal sigpoll = ProcessSignal._(29, 'SIGPOLL');
  static const ProcessSignal sigsys = ProcessSignal._(31, 'SIGSYS');

  @Deprecated('Use sighup instead')
  static const ProcessSignal SIGHUP = sighup;
  @Deprecated('Use sigint instead')
  static const ProcessSignal SIGINT = sigint;
  @Deprecated('Use sigquit instead')
  static const ProcessSignal SIGQUIT = sigquit;
  @Deprecated('Use sigill instead')
  static const ProcessSignal SIGILL = sigill;
  @Deprecated('Use sigtrap instead')
  static const ProcessSignal SIGTRAP = sigtrap;
  @Deprecated('Use sigabrt instead')
  static const ProcessSignal SIGABRT = sigabrt;
  @Deprecated('Use sigbus instead')
  static const ProcessSignal SIGBUS = sigbus;
  @Deprecated('Use sigfpe instead')
  static const ProcessSignal SIGFPE = sigfpe;
  @Deprecated('Use sigkill instead')
  static const ProcessSignal SIGKILL = sigkill;
  @Deprecated('Use sigusr1 instead')
  static const ProcessSignal SIGUSR1 = sigusr1;
  @Deprecated('Use sigsegv instead')
  static const ProcessSignal SIGSEGV = sigsegv;
  @Deprecated('Use sigusr2 instead')
  static const ProcessSignal SIGUSR2 = sigusr2;
  @Deprecated('Use sigpipe instead')
  static const ProcessSignal SIGPIPE = sigpipe;
  @Deprecated('Use sigalrm instead')
  static const ProcessSignal SIGALRM = sigalrm;
  @Deprecated('Use sigterm instead')
  static const ProcessSignal SIGTERM = sigterm;
  @Deprecated('Use sigchld instead')
  static const ProcessSignal SIGCHLD = sigchld;
  @Deprecated('Use sigcont instead')
  static const ProcessSignal SIGCONT = sigcont;
  @Deprecated('Use sigstop instead')
  static const ProcessSignal SIGSTOP = sigstop;
  @Deprecated('Use sigtstp instead')
  static const ProcessSignal SIGTSTP = sigtstp;
  @Deprecated('Use sigttin instead')
  static const ProcessSignal SIGTTIN = sigttin;
  @Deprecated('Use sigttou instead')
  static const ProcessSignal SIGTTOU = sigttou;
  @Deprecated('Use sigurg instead')
  static const ProcessSignal SIGURG = sigurg;
  @Deprecated('Use sigxcpu instead')
  static const ProcessSignal SIGXCPU = sigxcpu;
  @Deprecated('Use sigxfsz instead')
  static const ProcessSignal SIGXFSZ = sigxfsz;
  @Deprecated('Use sigvtalrm instead')
  static const ProcessSignal SIGVTALRM = sigvtalrm;
  @Deprecated('Use sigprof instead')
  static const ProcessSignal SIGPROF = sigprof;
  @Deprecated('Use sigwinch instead')
  static const ProcessSignal SIGWINCH = sigwinch;
  @Deprecated('Use sigpoll instead')
  static const ProcessSignal SIGPOLL = sigpoll;
  @Deprecated('Use sigsys instead')
  static const ProcessSignal SIGSYS = sigsys;

  final int _signalNumber;
  final String _name;

  const ProcessSignal._(this._signalNumber, this._name);

  @override
  int get hashCode => _signalNumber;

  @override
  String toString() => _name;

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
  Stream<ProcessSignal> watch() => throw UnimplementedError();
}

/// Modes for running a new process.
class ProcessStartMode {
  /// Normal child process.
  static const normal = ProcessStartMode._internal(0);
  @Deprecated('Use normal instead')
  static const NORMAL = normal;

  /// Stdio handles are inherited by the child process.
  static const inheritStdio = ProcessStartMode._internal(1);
  @Deprecated('Use inheritStdio instead')
  static const INHERIT_STDIO = inheritStdio;

  /// Detached child process with no open communication channel.
  static const detached = ProcessStartMode._internal(2);
  @Deprecated('Use detached instead')
  static const DETACHED = detached;

  /// Detached child process with stdin, stdout and stderr still open
  /// for communication with the child.
  static const detachedWithStdio = ProcessStartMode._internal(3);
  @Deprecated('Use detachedWithStdio instead')
  static const DETACHED_WITH_STDIO = detachedWithStdio;

  static List<ProcessStartMode> get values => const <ProcessStartMode>[
        normal,
        inheritStdio,
        detached,
        detachedWithStdio
      ];

  final int _mode;

  const ProcessStartMode._internal(this._mode);

  @override
  String toString() =>
      const ['normal', 'inheritStdio', 'detached', 'detachedWithStdio'][_mode];
}

class SignalException implements IOException {
  final String message;
  final osError;

  const SignalException(this.message, [this.osError]);

  @override
  String toString() {
    var msg = '';
    if (osError != null) {
      msg = ', osError: $osError';
    }
    return 'SignalException: $message$msg';
  }
}
