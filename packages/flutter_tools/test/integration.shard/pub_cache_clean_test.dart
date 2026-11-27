// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_utils.dart';

const _pubCacheEnvKey = 'PUB_CACHE';
const _confirmationPrompt = 'Are you sure?';
const _confirmationTimeout = Duration(seconds: 30);

void main() {
  late Directory tempPubCache;

  setUpAll(() async {
    // Ensure the flutter_tools snapshot is up to date before invoking flutter
    // with an empty temporary PUB_CACHE.
    final ProcessResult result = await processManager.run(<String>[flutterBin, '--version']);
    expect(result.exitCode, 0, reason: 'stderr:\n${result.stderr}\nstdout:\n${result.stdout}');
  });

  setUp(() {
    tempPubCache = createResolvedTempDirectorySync('pub_cache_clean_test.');
  });

  tearDown(() {
    tryToDelete(tempPubCache);
  });

  test('flutter pub cache clean accepts confirmation input on stdin', () async {
    final Directory cachedPackageDir = tempPubCache
        .childDirectory('hosted')
        .childDirectory('pub.dev')
        .childDirectory('foo-1.0.0');
    cachedPackageDir.childFile('pubspec.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync('name: foo\n');

    final Process process = await processManager.start(
      <String>[flutterBin, 'pub', 'cache', 'clean'],
      environment: <String, String>{_pubCacheEnvKey: tempPubCache.path},
    );

    final stdoutBuffer = StringBuffer();
    final stderrBuffer = StringBuffer();
    final promptReceived = Completer<void>();

    final StreamSubscription<String> stdoutSub = process.stdout.transform(utf8.decoder).listen((
      String chunk,
    ) {
      stdoutBuffer.write(chunk);
      if (!promptReceived.isCompleted && stdoutBuffer.toString().contains(_confirmationPrompt)) {
        promptReceived.complete();
      }
    });
    final StreamSubscription<String> stderrSub = process.stderr
        .transform(utf8.decoder)
        .listen(stderrBuffer.write);
    final Future<void> stdoutDone = stdoutSub.asFuture<void>();
    final Future<void> stderrDone = stderrSub.asFuture<void>();

    try {
      await promptReceived.future.timeout(
        _confirmationTimeout,
        onTimeout: () {
          process.kill();
          fail(
            'Timed out waiting for confirmation prompt.\n'
            'stdout:\n$stdoutBuffer\n'
            'stderr:\n$stderrBuffer',
          );
        },
      );

      process.stdin.writeln('y');
      await process.stdin.flush();
      await process.stdin.close();

      final int exitCode = await process.exitCode.timeout(
        _confirmationTimeout,
        onTimeout: () {
          process.kill();
          fail(
            'flutter pub cache clean hung after confirming with "y".\n'
            'stdout:\n$stdoutBuffer\n'
            'stderr:\n$stderrBuffer',
          );
        },
      );

      await stdoutDone;
      await stderrDone;

      expect(exitCode, 0, reason: 'stdout:\n$stdoutBuffer\nstderr:\n$stderrBuffer');
      expect(stdoutBuffer.toString(), contains('Removing pub cache directory'));
      expect(cachedPackageDir.existsSync(), isFalse);
    } finally {
      await stdoutSub.cancel();
      await stderrSub.cancel();
    }
  });
}
