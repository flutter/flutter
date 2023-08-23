// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:githooks/githooks.dart';
import 'package:githooks/src/pre_push_command.dart';
import 'package:litetest/litetest.dart';
import 'package:path/path.dart' as path;

void main() {
  test('Fails gracefully without a command', () async {
    int? result;
    try {
      result = await run(<String>[]);
    } catch (e, st) {
      fail('Unexpected exception: $e\n$st');
    }
    expect(result, equals(1));
  });

  test('Fails gracefully with an unknown command', () async {
    int? result;
    try {
      result = await run(<String>['blah']);
    } catch (e, st) {
      fail('Unexpected exception: $e\n$st');
    }
    expect(result, equals(1));
  });

  test('Fails gracefully without --flutter', () async {
    int? result;
    try {
      result = await run(<String>['pre-push']);
    } catch (e, st) {
      fail('Unexpected exception: $e\n$st');
    }
    expect(result, equals(1));
  });

  test('Fails gracefully when --flutter is not an absolute path', () async {
    int? result;
    try {
      result = await run(<String>[
        'pre-push',
        '--flutter',
        'non/absolute',
      ]);
    } catch (e, st) {
      fail('Unexpected exception: $e\n$st');
    }
    expect(result, equals(1));
  });

  test('Fails gracefully when --flutter does not exist', () async {
    int? result;
    try {
      result = await run(<String>[
        'pre-push',
        '--flutter',
        if (io.Platform.isWindows) r'C:\does\not\exist'
        else '/does/not/exist',
      ]);
    } catch (e, st) {
      fail('Unexpected exception: $e\n$st');
    }
    expect(result, equals(1));
  });

  group('findMostRelevantCompileCommands', () {
    late io.Directory fakeEngineRoot;
    late io.Directory fakeFlutterRoot;

    // We can't use standard setUp because this package uses 'litetest'.
    void setUp() {
      fakeEngineRoot = io.Directory.systemTemp.createTempSync('flutter_tools_githooks_test');
      fakeFlutterRoot = io.Directory(path.join(fakeEngineRoot.path, 'flutter'));
      fakeFlutterRoot.createSync(recursive: true);
    }

    void createHostFor(String target, {DateTime? lastModified}) {
      final io.Directory host = io.Directory(path.join(fakeEngineRoot.path, 'out', target));
      host.createSync(recursive: true);

      final io.File compileCommands = io.File(path.join(host.path, 'compile_commands.json'));
      compileCommands.createSync();
      if (lastModified != null) {
        compileCommands.setLastModifiedSync(lastModified);
      }
    }

    test('returns null if there are no built outputs', () {
      setUp();

      expect(
        PrePushCommand.findMostRelevantCompileCommands(fakeFlutterRoot.path, verbose: false),
        isNull,
      );
    });

    test('returns the most recently modified compile_commands.json', () {
      setUp();

      // Assume host_debug_unopt was created on 8/5, and then *_arm64 on 8/6.
      createHostFor('host_debug_unopt', lastModified: DateTime(2023, 8, 5));
      createHostFor('host_debug_unopt_arm64', lastModified: DateTime(2023, 8, 6));

      expect(
        PrePushCommand.findMostRelevantCompileCommands(fakeFlutterRoot.path, verbose: false)!.path,
        equals(path.join(fakeEngineRoot.path, 'out', 'host_debug_unopt_arm64', 'compile_commands.json')),
      );
    });

    test('in verbose mode, if there are multiple outputs, prints all of them', () {
      final StringBuffer outBuffer = StringBuffer();
      io.IOOverrides.runZoned(() {
        setUp();

        createHostFor('host_debug_unopt', lastModified: DateTime(2023, 8, 5));
        createHostFor('host_debug_unopt_arm64', lastModified: DateTime(2023, 8, 6));
        PrePushCommand.findMostRelevantCompileCommands(fakeFlutterRoot.path, verbose: true);
      }, stdout: () => _BufferedStdOut(outBuffer));

      final String outString = outBuffer.toString();
      expect(outString, contains('out/host_debug_unopt/compile_commands.json'));
      expect(outString, contains('out/host_debug_unopt_arm64/compile_commands.json'));
    });
  });
}

final class _BufferedStdOut implements io.Stdout {
  _BufferedStdOut(this.buffer);

  final StringBuffer buffer;

  // We don't need to implement any other methods.
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }

  @override
  void write(Object? obj) {
    buffer.write(obj);
  }

  @override
  void writeln([Object? obj = '']) {
    buffer.writeln(obj);
  }
}
