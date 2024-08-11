// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

// These match enum StdioHandleType in file.h
const int _stdioHandleTypeTerminal = 0;
const int _stdioHandleTypePipe = 1;
const int _stdioHandleTypeFile = 2;
const int _stdioHandleTypeSocket = 3;
const int _stdioHandleTypeOther = 4;
const int _stdioHandleTypeError = 5;

class _StdStream extends Stream<List<int>> {
  final Stream<List<int>> _stream;

  _StdStream(this._stream);

  StreamSubscription<List<int>> listen(void onData(List<int> event)?,
      {Function? onError, void onDone()?, bool? cancelOnError}) {
    return _stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
}

/// The standard input stream of the process.
///
/// Allows both synchronous and asynchronous reads from the standard
/// input stream.
///
/// Mixing synchronous and asynchronous reads is undefined.
class Stdin extends _StdStream implements Stream<List<int>> {
  int _fd;

  Stdin._(Stream<List<int>> stream, this._fd) : super(stream);

  /// Reads a line from stdin.
  ///
  /// Blocks until a full line is available.
  ///
  /// Lines my be terminated by either `<CR><LF>` or `<LF>`. On Windows,
  /// in cases where the [stdioType] of stdin is [StdioType.terminal],
  /// the terminator may also be a single `<CR>`.
  ///
  /// Input bytes are converted to a string by [encoding].
  /// If [encoding] is omitted, it defaults to [systemEncoding].
  ///
  /// If [retainNewlines] is `false`, the returned string will not include the
  /// final line terminator. If `true`, the returned string will include the line
  /// terminator. Default is `false`.
  ///
  /// If end-of-file is reached after any bytes have been read from stdin,
  /// that data is returned without a line terminator.
  /// Returns `null` if no bytes preceded the end of input.
  String? readLineSync(
      {Encoding encoding = systemEncoding, bool retainNewlines = false}) {
    const CR = 13;
    const LF = 10;
    final List<int> line = <int>[];
    // On Windows, if lineMode is disabled, only CR is received.
    bool crIsNewline = Platform.isWindows &&
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
        int byte = readByteSync();
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
        int byte = readByteSync();
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

  /// Whether echo mode is enabled on [stdin].
  ///
  /// If disabled, input from the console will not be echoed.
  ///
  /// Default depends on the parent process, but is usually enabled.
  ///
  /// On POSIX systems this mode is the `echo` local terminal mode. Before
  /// Dart 2.18, it also controlled the `echonl` mode, which is now controlled
  /// by [echoNewlineMode].
  ///
  /// On Windows this mode can only be enabled if [lineMode] is enabled as well.
  external bool get echoMode;
  external set echoMode(bool echoMode);

  /// Whether echo newline mode is enabled on [stdin].
  ///
  /// If enabled, newlines from the terminal will be echoed even if the regular
  /// [echoMode] is disabled. This mode may require `lineMode` to be turned on
  /// to have an effect.
  ///
  /// Default depends on the parent process, but is usually disabled.
  ///
  /// On POSIX systems this mode is the `echonl` local terminal mode.
  ///
  /// On Windows this mode cannot be set.
  @Since("2.18")
  external bool get echoNewlineMode;
  @Since("2.18")
  external set echoNewlineMode(bool echoNewlineMode);

  /// Whether line mode is enabled on [stdin].
  ///
  /// If enabled, characters are delayed until a newline character is entered.
  /// If disabled, characters will be available as typed.
  ///
  /// Default depends on the parent process, but is usually enabled.
  ///
  /// On POSIX systems this mode is the `icanon` local terminal mode.
  ///
  /// On Windows this mode can only be disabled if [echoMode] is disabled as
  /// well.
  external bool get lineMode;
  external set lineMode(bool lineMode);

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
  external bool get supportsAnsiEscapes;

  /// Synchronously reads a byte from stdin.
  ///
  /// This call will block until a byte is available.
  ///
  /// If at end of file, -1 is returned.
  external int readByteSync();

  /// Whether there is a terminal attached to stdin.
  bool get hasTerminal {
    try {
      return stdioType(this) == StdioType.terminal;
    } on FileSystemException catch (_) {
      // If stdioType throws a FileSystemException, then it is not hooked up to
      // a terminal, probably because it is closed, but let other exception
      // types bubble up.
      return false;
    }
  }
}

/// An [IOSink] connected to either the standard out or error of the process.
///
/// Provides a *blocking* `IOSink`, so using it to write will block until
/// the output is written.
///
/// In some situations this blocking behavior is undesirable as it does not
/// provide the same non-blocking behavior that `dart:io` in general exposes.
/// Use the property [nonBlocking] to get an [IOSink] which has the non-blocking
/// behavior.
///
/// This class can also be used to check whether `stdout` or `stderr` is
/// connected to a terminal and query some terminal properties.
///
/// The [addError] API is inherited from [StreamSink] and calling it will result
/// in an unhandled asynchronous error unless there is an error handler on
/// [done].
///
/// The [lineTerminator] field is used by the [write], [writeln], [writeAll]
/// and [writeCharCode] methods to translate `"\n"`. By default, `"\n"` is
/// output literally.
class Stdout extends _StdSink implements IOSink {
  final int _fd;
  IOSink? _nonBlocking;

  Stdout._(IOSink sink, this._fd) : super(sink);

  /// Whether there is a terminal attached to stdout.
  bool get hasTerminal => _hasTerminal(_fd);

  /// The number of columns of the terminal.
  ///
  /// If no terminal is attached to stdout, a [StdoutException] is thrown. See
  /// [hasTerminal] for more info.
  int get terminalColumns => _terminalColumns(_fd);

  /// The number of lines of the terminal.
  ///
  /// If no terminal is attached to stdout, a [StdoutException] is thrown. See
  /// [hasTerminal] for more info.
  int get terminalLines => _terminalLines(_fd);

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
  bool get supportsAnsiEscapes => _supportsAnsiEscapes(_fd);

  external bool _hasTerminal(int fd);
  external int _terminalColumns(int fd);
  external int _terminalLines(int fd);
  external static bool _supportsAnsiEscapes(int fd);

  /// A non-blocking `IOSink` for the same output.
  ///
  /// The returned `IOSink` will be initialized with an [encoding] of UTF-8 and
  /// will not do line ending conversion.
  IOSink get nonBlocking {
    return _nonBlocking ??= new IOSink(new _FileStreamConsumer.fromStdio(_fd));
  }
}

/// Exception thrown by some operations of [Stdout]
class StdoutException implements IOException {
  /// Message describing cause of the exception.
  final String message;

  /// The underlying OS error, if available.
  final OSError? osError;

  const StdoutException(this.message, [this.osError]);

  String toString() {
    return "StdoutException: $message${osError == null ? "" : ", $osError"}";
  }
}

/// Exception thrown by some operations of [Stdin]
class StdinException implements IOException {
  /// Message describing cause of the exception.
  final String message;

  /// The underlying OS error, if available.
  final OSError? osError;

  const StdinException(this.message, [this.osError]);

  String toString() {
    return "StdinException: $message${osError == null ? "" : ", $osError"}";
  }
}

class _StdConsumer implements StreamConsumer<List<int>> {
  final RandomAccessFile _file;

  _StdConsumer(int fd) : _file = _File._openStdioSync(fd);

  Future addStream(Stream<List<int>> stream) {
    var completer = new Completer();
    late StreamSubscription<List<int>> sub;
    sub = stream.listen((data) {
      try {
        _file.writeFromSync(data);
      } catch (e, s) {
        sub.cancel();
        completer.completeError(e, s);
      }
    },
        onError: completer.completeError,
        onDone: completer.complete,
        cancelOnError: true);
    return completer.future;
  }

  Future close() {
    _file.closeSync();
    return new Future.value();
  }
}

/// Pattern matching a "\n" character not following a "\r".
///
/// Used to replace such with "\r\n" in the [_StdSink] write methods.
final _newLineDetector = RegExp(r'(?<!\r)\n');

/// Pattern matching "\n" characters not following a "\r", or at the start of
/// input.
///
/// Used to replace those with "\r\n" in the [_StdSink] write methods,
/// when the previously written string ended in a \r character.
final _newLineDetectorAfterCr = RegExp(r'(?<!\r|^)\n');

class _StdSink implements IOSink {
  final IOSink _sink;
  bool _windowsLineTerminator = false;
  bool _lastWrittenCharIsCR = false;

  _StdSink(this._sink);

  /// Line ending appended by [writeln], and replacing `"\n"` in some methods.
  ///
  /// Must be one of the values `"\n"` (the default) or `"\r\n"`.
  ///
  /// When set to `"\r\n"`, the methods [write], [writeln], [writeAll] and
  /// [writeCharCode] will convert embedded newlines, `"\n"`, in their
  /// arguments to `"\r\n"`. If their arguments already contain `"\r\n"`
  /// sequences, then these sequences will be not be converted. This is true
  /// even if the sequence is generated across different method calls.
  ///
  /// If `lineTerminator` is `"\n"` then the written strings are not modified.
  //
  /// Setting `lineTerminator` to [Platform.lineTerminator] will result in
  /// "write" methods outputting the line endings for the platform:
  ///
  /// ```dart
  /// stdout.lineTerminator = Platform.lineTerminator;
  /// stderr.lineTerminator = Platform.lineTerminator;
  /// ```
  ///
  /// The value of `lineTerminator` has no effect on byte-oriented methods
  /// such as [add].
  ///
  /// The value of `lineTerminator` does not effect the output of the [print]
  /// function.
  ///
  /// Throws [ArgumentError] if set to a value other than `"\n"` or `"\r\n"`.
  String get lineTerminator => _windowsLineTerminator ? "\r\n" : "\n";
  set lineTerminator(String lineTerminator) {
    if (lineTerminator == "\r\n") {
      assert(!_lastWrittenCharIsCR || _windowsLineTerminator);
      _windowsLineTerminator = true;
    } else if (lineTerminator == "\n") {
      _windowsLineTerminator = false;
      _lastWrittenCharIsCR = false;
    } else {
      throw ArgumentError.value(lineTerminator, "lineTerminator",
          r'invalid line terminator, must be one of "\r" or "\r\n"');
    }
  }

  Encoding get encoding => _sink.encoding;
  void set encoding(Encoding encoding) {
    _sink.encoding = encoding;
  }

  void _write(Object? object) {
    if (!_windowsLineTerminator) {
      _sink.write(object);
      return;
    }

    var string = '$object';
    if (string.isEmpty) return;
    if (_lastWrittenCharIsCR) {
      string = string.replaceAll(_newLineDetectorAfterCr, "\r\n");
    } else {
      string = string.replaceAll(_newLineDetector, "\r\n");
    }
    _lastWrittenCharIsCR = string.endsWith('\r');
    _sink.write(string);
  }

  void write(Object? object) => _write(object);

  void writeln([Object? object = ""]) {
    _write(object);
    _sink.write(_windowsLineTerminator ? "\r\n" : "\n");
    _lastWrittenCharIsCR = false;
  }

  void writeAll(Iterable objects, [String sep = ""]) {
    Iterator iterator = objects.iterator;
    if (!iterator.moveNext()) return;
    if (sep.isEmpty) {
      do {
        _write(iterator.current);
      } while (iterator.moveNext());
    } else {
      _write(iterator.current);
      while (iterator.moveNext()) {
        _write(sep);
        _write(iterator.current);
      }
    }
  }

  void add(List<int> data) {
    _lastWrittenCharIsCR = false;
    _sink.add(data);
  }

  void addError(error, [StackTrace? stackTrace]) {
    _sink.addError(error, stackTrace);
  }

  void writeCharCode(int charCode) {
    if (!_windowsLineTerminator) {
      _sink.writeCharCode(charCode);
      return;
    }

    _write(String.fromCharCode(charCode));
  }

  Future addStream(Stream<List<int>> stream) {
    _lastWrittenCharIsCR = false;
    return _sink.addStream(stream);
  }

  Future flush() => _sink.flush();
  Future close() => _sink.close();
  Future get done => _sink.done;
}

/// The type of object a standard IO stream can be attached to.
final class StdioType {
  static const StdioType terminal = const StdioType._("terminal");
  static const StdioType pipe = const StdioType._("pipe");
  static const StdioType file = const StdioType._("file");
  static const StdioType other = const StdioType._("other");

  final String name;
  const StdioType._(this.name);
  String toString() => "StdioType: $name";
}

final Stdin _stdin = _StdIOUtils._getStdioInputStream(_stdinFD);
final Stdout _stdout = _StdIOUtils._getStdioOutputStream(_stdoutFD);
final Stdout _stderr = _StdIOUtils._getStdioOutputStream(_stderrFD);

// These may be set to different values by the embedder by calling
// _setStdioFDs when initializing dart:io.
int _stdinFD = 0;
int _stdoutFD = 1;
int _stderrFD = 2;

@pragma('vm:entry-point', 'call')
void _setStdioFDs(int stdin, int stdout, int stderr) {
  _stdinFD = stdin;
  _stdoutFD = stdout;
  _stderrFD = stderr;
}

/// The standard input stream of data read by this program.
Stdin get stdin {
  return IOOverrides.current?.stdin ?? _stdin;
}

/// The standard output stream of data written by this program.
///
/// The `addError` API is inherited from  `StreamSink` and calling it will
/// result in an unhandled asynchronous error unless there is an error handler
/// on `done`.
Stdout get stdout {
  return IOOverrides.current?.stdout ?? _stdout;
}

/// The standard output stream of errors written by this program.
///
/// The `addError` API is inherited from  `StreamSink` and calling it will
/// result in an unhandled asynchronous error unless there is an error handler
/// on `done`.
Stdout get stderr {
  return IOOverrides.current?.stderr ?? _stderr;
}

/// Whether a stream is attached to a file, pipe, terminal, or
/// something else.
StdioType stdioType(object) {
  if (object is _StdStream) {
    object = object._stream;
  } else if (object == stdout || object == stderr) {
    int stdiofd = object == stdout ? _stdoutFD : _stderrFD;
    final type = _StdIOUtils._getStdioHandleType(stdiofd);
    if (type is OSError) {
      throw FileSystemException(
          "Failed to get type of stdio handle (fd $stdiofd)", "", type);
    }
    switch (type) {
      case _stdioHandleTypeTerminal:
        return StdioType.terminal;
      case _stdioHandleTypePipe:
        return StdioType.pipe;
      case _stdioHandleTypeFile:
        return StdioType.file;
    }
  }
  if (object is _FileStream) {
    return StdioType.file;
  }
  if (object is Socket) {
    int? socketType = _StdIOUtils._socketType(object);
    if (socketType == null) return StdioType.other;
    switch (socketType) {
      case _stdioHandleTypeTerminal:
        return StdioType.terminal;
      case _stdioHandleTypePipe:
        return StdioType.pipe;
      case _stdioHandleTypeFile:
        return StdioType.file;
    }
  }
  if (object is _IOSinkImpl) {
    try {
      if (object._target is _FileStreamConsumer) {
        return StdioType.file;
      }
    } catch (e) {
      // Only the interface implemented, _sink not available.
    }
  }
  return StdioType.other;
}

class _StdIOUtils {
  external static _getStdioOutputStream(int fd);
  external static Stdin _getStdioInputStream(int fd);

  /// Returns the socket type or `null` if [socket] is not a builtin socket.
  external static int? _socketType(Socket socket);
  external static _getStdioHandleType(int fd);
}
