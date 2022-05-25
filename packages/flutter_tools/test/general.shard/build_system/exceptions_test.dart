// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/exceptions.dart';

import '../../src/common.dart';

void main() {
  test('Exceptions', () {
    final CycleException cycleException = CycleException(<Target>{
      TestTarget()..name = 'foo',
      TestTarget()..name = 'bar',
    });
    final InvalidPatternException invalidPatternException = InvalidPatternException(
      'ABC'
    );
    final MissingDefineException missingDefineException = MissingDefineException(
      'foobar',
      'example',
    );

    expect(
        cycleException.toString(),
        'Dependency cycle detected in build: foo -> bar',
    );
    expect(
        invalidPatternException.toString(),
        'The pattern "ABC" is not valid',
    );
    expect(
        missingDefineException.toString(),
        'Target example required define foobar but it was not provided',
    );
  });
}

class TestTarget extends Target {
  @override
  Future<void> build(Environment environment) async {}

  @override
  List<Target> dependencies = <Target>[];

  @override
  List<Source> inputs = <Source>[];

  @override
  String name = 'test';

  @override
  List<Source> outputs = <Source>[];
}
