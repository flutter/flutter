// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'utils/server_driver.dart';

late final DevToolsServerTestController testController;

void main() {
  const testScriptContents =
      'Future<void> main() => Future.delayed(const Duration(minutes: 10));';
  final tempDir = Directory.systemTemp.createTempSync('devtools_server.');
  final devToolsBannerRegex =
      RegExp(r'DevTools[\w\s]+at: (https?:.*\/devtools\/)');

  test('serves index.html contents for /token/devtools/inspector', () async {
    final testFile = File(path.join(tempDir.path, 'foo.dart'));
    testFile.writeAsStringSync(testScriptContents);

    final proc = await Process.start(
        Platform.resolvedExecutable, ['--observe=0', testFile.path]);
    try {
      final completer = Completer<String>();
      proc.stderr
          .transform(utf8.decoder)
          .transform(LineSplitter())
          .listen(print);
      proc.stdout.transform(utf8.decoder).transform(LineSplitter()).listen(
        (String line) {
          print(line);
          final match = devToolsBannerRegex.firstMatch(line);
          if (match != null) {
            completer.complete(match.group(1));
          }
        },
        onDone: () {
          if (!completer.isCompleted) {
            completer.completeError(
                'Process ended without emitting DevTools banner');
          }
        },
        onError: (e) {
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        },
      );

      final devToolsUrl = Uri.parse(await completer.future);
      final httpClient = HttpClient();
      late HttpClientResponse resp;
      try {
        final req = await httpClient.get(
            devToolsUrl.host, devToolsUrl.port, '${devToolsUrl.path}inspector');
        resp = await req.close();
        expect(resp.statusCode, 200);
        final bodyContent = await resp.transform(utf8.decoder).join();
        expect(bodyContent, contains('Dart DevTools'));
        final expectedBaseHref = htmlEscape.convert(devToolsUrl.path);
        expect(bodyContent, contains('<base href="$expectedBaseHref">'));
      } finally {
        httpClient.close();
      }
    } finally {
      proc.kill();
    }
  }, timeout: const Timeout.factor(10));
}
