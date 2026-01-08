// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:test_core/src/executable.dart' as test; // ignore: implementation_imports
import 'package:test_core/src/platform.dart' // ignore: implementation_imports
    as hack
    show registerPlatformPlugin;
import 'package:test_core/src/platform.dart'; // ignore: implementation_imports

export 'package:test_api/backend.dart' show Runtime;
export 'package:test_core/src/platform.dart' show PlatformPlugin;

/// Callback for processing each line of test output.
typedef OutputLineCallback = void Function(String line);

abstract class TestWrapper {
  const factory TestWrapper() = _DefaultTestWrapper;

  /// Runs the test package with the given arguments.
  Future<void> main(List<String> args);

  /// Runs the test package with output interception.
  ///
  /// All stdout output from the test runner will be passed to [onOutputLine]
  /// line-by-line, allowing for stream processing of test results.
  Future<void> mainWithOutputCapture(
    List<String> args, {
    required OutputLineCallback onOutputLine,
  });

  void registerPlatformPlugin(
    Iterable<Runtime> runtimes,
    FutureOr<PlatformPlugin> Function() platforms,
  );
}

class _DefaultTestWrapper implements TestWrapper {
  const _DefaultTestWrapper();

  @override
  Future<void> main(List<String> args) async {
    await test.main(args);
  }

  @override
  Future<void> mainWithOutputCapture(
    List<String> args, {
    required OutputLineCallback onOutputLine,
  }) async {
    final io.Stdout originalStdout = io.stdout;
    final buffer = StringBuffer();

    void processBuffer() {
      final content = buffer.toString();
      if (content.isEmpty) {
        return;
      }
      buffer.clear();

      final List<String> lines = content.split('\n');
      for (var i = 0; i < lines.length; i++) {
        final String line = lines[i];
        // The last element might be incomplete if content doesn't end with \n
        if (i == lines.length - 1 && !content.endsWith('\n') && line.isNotEmpty) {
          buffer.write(line);
        } else if (line.isNotEmpty) {
          onOutputLine(line);
        }
      }
    }

    await io.IOOverrides.runZoned(
      () async {
        await test.main(args);
        processBuffer();
      },
      stdout: () => _InterceptingStdout(
        originalStdout,
        onWrite: (String data) {
          buffer.write(data);
          processBuffer();
        },
      ),
    );
  }

  @override
  void registerPlatformPlugin(
    Iterable<Runtime> runtimes,
    FutureOr<PlatformPlugin> Function() platforms,
  ) {
    hack.registerPlatformPlugin(runtimes, platforms);
  }
}

/// A stdout wrapper that intercepts writes for processing.
class _InterceptingStdout implements io.Stdout {
  _InterceptingStdout(this._original, {required this.onWrite});

  final io.Stdout _original;
  final void Function(String data) onWrite;

  @override
  void write(Object? object) {
    onWrite(object.toString());
  }

  @override
  void writeln([Object? object = '']) {
    onWrite('${object ?? ''}\n');
  }

  @override
  void writeAll(Iterable<dynamic> objects, [String sep = '']) {
    onWrite(objects.join(sep));
  }

  @override
  void writeCharCode(int charCode) {
    onWrite(String.fromCharCode(charCode));
  }

  @override
  Encoding get encoding => _original.encoding;

  @override
  set encoding(Encoding encoding) => _original.encoding = encoding;

  @override
  void add(List<int> data) {
    onWrite(utf8.decode(data));
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      _original.addError(error, stackTrace);

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    await for (final List<int> data in stream) {
      onWrite(utf8.decode(data));
    }
  }

  @override
  Future<void> close() => _original.close();

  @override
  Future<void> get done => _original.done;

  @override
  Future<void> flush() => _original.flush();

  @override
  bool get hasTerminal => _original.hasTerminal;

  @override
  io.IOSink get nonBlocking => _original.nonBlocking;

  @override
  bool get supportsAnsiEscapes => _original.supportsAnsiEscapes;

  @override
  int get terminalColumns => _original.terminalColumns;

  @override
  int get terminalLines => _original.terminalLines;

  @override
  String get lineTerminator => _original.lineTerminator;

  @override
  set lineTerminator(String value) => _original.lineTerminator = value;
}
