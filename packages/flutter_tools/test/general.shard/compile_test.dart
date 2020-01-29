// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/compile.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  testUsingContext('StdOutHandler test', () async {
    final StdoutHandler stdoutHandler = StdoutHandler();
    stdoutHandler.handler('result 12345');
    expect(stdoutHandler.boundaryKey, '12345');
    stdoutHandler.handler('12345');
    stdoutHandler.handler('12345 message 0');
    final CompilerOutput output = await stdoutHandler.compilerOutput.future;
    expect(output.errorCount, 0);
    expect(output.outputFilename, 'message');
  });

  testUsingContext('StdOutHandler crash test', () async {
    final StdoutHandler stdoutHandler = StdoutHandler();
    final Future<CompilerOutput> output = stdoutHandler.compilerOutput.future;
    stdoutHandler.handler('message with no result');

    expect(output, throwsToolExit());
  });

  test('TargetModel values', () {
    expect(TargetModel('vm'), TargetModel.vm);
    expect(TargetModel.vm.toString(), 'vm');

    expect(TargetModel('flutter'), TargetModel.flutter);
    expect(TargetModel.flutter.toString(), 'flutter');

    expect(TargetModel('flutter_runner'), TargetModel.flutterRunner);
    expect(TargetModel.flutterRunner.toString(), 'flutter_runner');

    expect(TargetModel('dartdevc'), TargetModel.dartdevc);
    expect(TargetModel.dartdevc.toString(), 'dartdevc');

    expect(() => TargetModel('foobar'), throwsAssertionError);
  });
}
