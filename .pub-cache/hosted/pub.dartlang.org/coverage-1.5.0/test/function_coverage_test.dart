// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show json;
import 'dart:io';

import 'package:coverage/coverage.dart';
import 'package:coverage/src/util.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_process/test_process.dart';

import 'test_util.dart';

final _collectAppPath = p.join('bin', 'collect_coverage.dart');
final _funcCovApp = p.join('test', 'test_files', 'function_coverage_app.dart');
final _sampleAppFileUri = p.toUri(p.absolute(_funcCovApp)).toString();

void main() {
  test('Function coverage', () async {
    final resultString = await _collectCoverage();
    final jsonResult = json.decode(resultString) as Map<String, dynamic>;
    final coverage = jsonResult['coverage'] as List;
    final hitMap = await HitMap.parseJson(
      coverage.cast<Map<String, dynamic>>(),
    );

    // function_coverage_app.dart.
    expect(hitMap, contains(_sampleAppFileUri));
    final isolateFile = hitMap[_sampleAppFileUri]!;
    expect(isolateFile.funcHits, {
      7: 1,
      12: 0, // TODO(#398): This abstract method should be ignored.
      16: 1,
      21: 1,
      25: 1,
      29: 1,
      36: 1,
      42: 1,
      47: 1,
    });
    expect(isolateFile.funcNames, {
      7: 'normalFunction',
      12: 'BaseClass.abstractMethod',
      16: 'SomeClass.SomeClass',
      21: 'SomeClass.normalMethod',
      25: 'SomeClass.staticMethod',
      29: 'SomeClass.abstractMethod',
      36: 'SomeExtension.extensionMethod',
      42: 'OtherClass.otherMethod',
      47: 'main',
    });

    // test_library.dart.
    final testLibraryPath =
        p.absolute(p.join('test', 'test_files', 'test_library.dart'));
    final testLibraryUri = p.toUri(testLibraryPath).toString();
    expect(hitMap, contains(testLibraryUri));
    final libraryfile = hitMap[testLibraryUri]!;
    expect(libraryfile.funcHits, {9: 1});
    expect(libraryfile.funcNames, {9: 'libraryFunction'});

    // test_library_part.dart.
    final testLibraryPartPath =
        p.absolute(p.join('test', 'test_files', 'test_library_part.dart'));
    final testLibraryPartUri = p.toUri(testLibraryPartPath).toString();
    expect(hitMap, contains(testLibraryPartUri));
    final libraryPartFile = hitMap[testLibraryPartUri]!;
    expect(libraryPartFile.funcHits, {7: 1});
    expect(libraryPartFile.funcNames, {7: 'otherLibraryFunction'});
  });
}

Future<String> _collectCoverage() async {
  expect(FileSystemEntity.isFileSync(_funcCovApp), isTrue);

  final openPort = await getOpenPort();

  // Run the sample app with the right flags.
  final sampleProcess = await TestProcess.start(Platform.resolvedExecutable, [
    '--enable-vm-service=$openPort',
    '--pause_isolates_on_exit',
    _funcCovApp
  ]);

  final serviceUri = await serviceUriFromProcess(sampleProcess.stdoutStream());

  // Run the collection tool.
  final toolResult = await TestProcess.start(Platform.resolvedExecutable, [
    _collectAppPath,
    '--function-coverage',
    '--uri',
    '$serviceUri',
    '--resume-isolates',
    '--wait-paused'
  ]);

  await toolResult.shouldExit(0).timeout(timeout, onTimeout: () {
    throw 'We timed out waiting for the tool to finish.';
  });

  await sampleProcess.shouldExit();

  return toolResult.stdoutStream().join('\n');
}
