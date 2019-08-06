// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/src/interface/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/phases.dart';

import '../../src/common.dart';
import '../../src/testbed.dart';

final TestTarget testTargetA = TestTarget('a');
final TestTarget testTargetB = TestTarget('b');
final TestTarget testTargetC = TestTarget('c');

void main() {
  Testbed testbed;

  setUp(() {
    testbed = Testbed();
  });

  test('Can generate reasonable build graph', () => testbed.run(() async {
    final BuildDefinition definition = BuildDefinition(
      name: 'example',
      phases: <BuildPhase>[
        TestPhaseHello(),
        TestPhaseGoodbye(),
      ]
    );
    final Target result = await definition.createBuild(Environment(projectDir: fs.currentDirectory));

    expect(<String>[for (Target target in result.dependencies) target.name], unorderedEquals(<String>['hello', 'goodbye']));
    expect(<String>[for (Target target in result.dependencies.first.dependencies) target.name], unorderedEquals(<String>['a']));
    expect(<String>[for (Target target in result.dependencies.last.dependencies) target.name], unorderedEquals(<String>['b', 'c', 'hello']));
  }));
}

class TestPhaseHello extends BuildPhase {
  @override
  List<String> get dependencies => <String>[];

  @override
  String get name => 'hello';

  @override
  Future<List<Target>> plan(Environment environment) async {
    return <Target>[
      testTargetA,
    ];
  }
}

class TestPhaseGoodbye extends BuildPhase {
  @override
  List<String> get dependencies => <String>[
    'hello'
  ];

  @override
  String get name => 'goodbye';

  @override
  Future<List<Target>> plan(Environment environment) async {
    return <Target>[
      testTargetB,
      testTargetC,
    ];
  }
}

class TestTarget extends Target {
  TestTarget(this.name);

  @override
  final String name;

  @override
  Future<void> build(List<File> inputFiles, Environment environment) async { }

  @override
  List<Target> get dependencies => <Target>[];

  @override
  List<Source> get inputs => <Source>[];

  @override
  List<Source> get outputs => <Source>[];
}
