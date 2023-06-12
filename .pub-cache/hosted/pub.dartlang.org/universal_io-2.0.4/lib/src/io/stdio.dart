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

import 'dart:async';
import 'dart:convert';

import '../io_impl_js.dart';

/// The standard output stream of errors written by this program.
///
/// The `addError` API is inherited from  `StreamSink` and calling it will
/// result in an unhandled asynchronous error unless there is an error handler
/// on `done`.
Stdout get stderr {
  throw UnimplementedError();
}

/// The standard input stream of data read by this program.
Stdin get stdin {
  throw UnimplementedError();
}

/// The standard output stream of data written by this program.
///
/// The `addError` API is inherited from  `StreamSink` and calling it will
/// result in an unhandled asynchronous error unless there is an error handler
/// on `done`.
Stdout get stdout {
  throw UnimplementedError();
}

/// For a stream, returns whether it is attached to a file, pipe, terminal, or
/// something else.
StdioType stdioType(object) {
  return StdioType.other;
}

/// [Stdin] allows both synchronous and asynchronous reads from the standard
/// input stream.
///
/// Mixing synchronous and asynchronous reads is undefined.
abstract class Stdin implements Stream<List<int>> {
  /// Check if echo mode is enabled on [stdin].
  ///
  /// If disabled, input from to console will not be echoed.
  ///
  /// Default depends on the parent process, but usually enabled.
  ///
  /// On Windows this mode can only be enabled if [lineMode] is enabled as well.
  bool echoMode = false;

  /// Returns true if there is a terminal attached to stdin.
  bool get hasTerminal => false;

  /// Check if line mode is enabled on [stdin].
  ///
  /// If enabled, characters are delayed until a new-line character is entered.
  /// If disabled, characters will be available as typed.
  ///
  /// Default depends on the parent process, but usually enabled.
  ///
  /// On Windows this mode can only be disabled if [echoMode] is disabled as well.
  bool lineMode = false;

  /// Whether connected to a terminal that supports ANSI escape sequences.
  ///
  /// Not all terminals are recognized, and not all recognized terminals can
  /// report whether they support ANSI escape sequences, so this value is a
  /// best-effort attempt at detecting the support.
  ///
  /// The actual escape sequence support may differ between terminals,
  /// with some terminals supporting more escape sequences than others,
  /// and some terminals even differing in behavior for the same escape
  /// sequence.
  ///
  /// The ANSI color selection is generally supported.
  ///
  /// Currently, a `TERM` environment variable containing the string `xterm`
  /// will be taken as evidence that ANSI escape sequences are supported.
  /// On Windows, only versions of Windows 10 after v.1511
  /// ("TH2", OS build 10586) will be detected as supporting the output of
  /// ANSI escape sequences, and only versions after v.1607 ("Anniversary
  /// Update", OS build 14393) will be detected as supporting the input of
  /// ANSI escape sequences.
  bool get supportsAnsiEscapes => false;

  /// Synchronously read a byte from stdin. This call will block until a byte is
  /// available.
  ///
  /// If at end of file, -1 is returned.
  int readByteSync() {
    throw UnimplementedError();
  }

  /// Read a line from stdin.
  ///
  /// Blocks until a full line is available.
  ///
  /// Lines my be terminated by either `<CR><LF>` or `<LF>`. On Windows in cases
  /// where the [stdioType] of stdin is [StdioType.terminal] the terminator may
  /// also be a single `<CR>`.
  ///
  /// Input bytes are converted to a string by [encoding].
  /// If [encoding] is omitted, it defaults to [systemEncoding].
  ///
  /// If [retainNewlines] is `false`, the returned String will not include the
  /// final line terminator. If `true`, the returned String will include the line
  /// terminator. Default is `false`.
  ///
  /// If end-of-file is reached after any bytes have been read from stdin,
  /// that data is returned without a line terminator.
  /// Returns `null` if no bytes preceded the end of input.
  String? readLineSync(
      {Encoding encoding = systemEncoding, bool retainNewlines = false}) {
    const CR = 13;
    const LF = 10;
    final line = <int>[];
    // On Windows, if lineMode is disabled, only CR is received.
    var crIsNewline = Platform.isWindows &&
        (stdioType(stdin) == StdioType.terminal) &&
        !lineMode;
    if (retainNewlines) {
      int byte;
      do {
        byte = readByteSync();
        if (byte < 0) {
          break;
        }
        line.add(byte);
      } while (byte != LF && !(byte == CR && crIsNewline));
      if (line.isEmpty) {
        return null;
      }
    } else if (crIsNewline) {
      // CR and LF are both line terminators, neither is retained.
      while (true) {
        var byte = readByteSync();
        if (byte < 0) {
          if (line.isEmpty) return null;
          break;
        }
        if (byte == LF || byte == CR) break;
        line.add(byte);
      }
    } else {
      // Case having to handle CR LF as a single unretained line terminator.
      outer:
      while (true) {
        var byte = readByteSync();
        if (byte == LF) break;
        if (byte == CR) {
          do {
            byte = readByteSync();
            if (byte == LF) break outer;

            line.add(CR);
          } while (byte == CR);
          // Fall through and handle non-CR character.
        }
        if (byte < 0) {
          if (line.isEmpty) return null;
          break;
        }
        line.add(byte);
      }
    }
    return encoding.decode(line);
  }
}

class StdinException implements IOException {
  final String message;
  final OSError? osError;

  const StdinException(this.message, [this.osError]);

  @override
  String toString() {
    return "StdinException: $message${osError == null ? "" : ", $osError"}";
  }
}

/// The type of object a standard IO stream is attached to.
class StdioType {
  static const StdioType terminal = StdioType._('terminal');
  static const StdioType pipe = StdioType._('pipe');
  static const StdioType file = StdioType._('file');
  static const StdioType other = StdioType._('other');

  @Deprecated('Use terminal instead')
  static const StdioType TERMINAL = terminal;
  @Deprecated('Use pipe instead')
  static const StdioType PIPE = pipe;
  @Deprecated('Use file instead')
  static const StdioType FILE = file;
  @Deprecated('Use other instead')
  static const StdioType OTHER = other;

  final String name;

  const StdioType._(this.name);

  @override
  String toString() => 'StdioType: $name';
}

/// [Stdout] represents the [IOSink] for either `stdout` or `stderr`.
///
/// It provides a *blocking* `IOSink`, so using this to write will block until
/// the output is written.
///
/// In some situations this blocking behavior is undesirable as it does not
/// provide the same non-blocking behavior as dart:io in general exposes.
/// Use the property [nonBlocking] to get an `IOSink` which has the non-blocking
/// behavior.
///
/// This class can also be used to check whether `stdout` or `stderr` is
/// connected to a terminal and query some terminal properties.
///
/// The [addError] API is inherited from  [StreamSink] and calling it will result
/// in an unhandled asynchronous error unless there is an error handler on
/// [done].
abstract class Stdout implements IOSink {
  /// Returns true if there is a terminal attached to stdout.
  bool get hasTerminal => false;

  /// Get a non-blocking `IOSink`.
  IOSink get nonBlocking => this;

  /// Whether connected to a terminal that supports ANSI escape sequences.
  ///
  /// Not all terminals are recognized, and not all recognized terminals can
  /// report whether they support ANSI escape sequences, so this value is a
  /// best-effort attempt at detecting the support.
  ///
  /// The actual escape sequence support may differ between terminals,
  /// with some terminals supporting more escape sequences than others,
  /// and some terminals even differing in behavior for the same escape
  /// sequence.
  ///
  /// The ANSI color selection is generally supported.
  ///
  /// Currently, a `TERM` environment variable containing the string `xterm`
  /// will be taken as evidence that ANSI escape sequences are supported.
  /// On Windows, only versions of Windows 10 after v.1511
  /// ("TH2", OS build 10586) will be detected as supporting the output of
  /// ANSI escape sequences, and only versions after v.1607 ("Anniversary
  /// Update", OS build 14393) will be detected as supporting the input of
  /// ANSI escape sequences.
  bool get supportsAnsiEscapes => false;

  /// Get the number of columns of the terminal.
  ///
  /// If no terminal is attached to stdout, a [StdoutException] is thrown. See
  /// [hasTerminal] for more info.
  int get terminalColumns => 80;

  /// Get the number of lines of the terminal.
  ///
  /// If no terminal is attached to stdout, a [StdoutException] is thrown. See
  /// [hasTerminal] for more info.
  int get terminalLines => 40;
}

class StdoutException implements IOException {
  final String message;
  final OSError? osError;

  const StdoutException(this.message, [this.osError]);

  @override
  String toString() {
    return "StdoutException: $message${osError == null ? "" : ", $osError"}";
  }
}
