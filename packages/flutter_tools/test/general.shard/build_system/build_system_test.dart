// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:platform/platform.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/utils.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/exceptions.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/testbed.dart';

void main() {
  setUpAll(() {
    Cache.disableLocking();
  });

  const BuildSystem buildSystem = BuildSystem();
  Testbed testbed;
  MockPlatform mockPlatform;
  Environment environment;
  Target fooTarget;
  Target barTarget;
  Target fizzTarget;
  Target sharedTarget;
  int fooInvocations;
  int barInvocations;
  int shared;

  setUp(() {
    fooInvocations = 0;
    barInvocations = 0;
    shared = 0;
    mockPlatform = MockPlatform();
    // Keep file paths the same.
    when(mockPlatform.isWindows).thenReturn(false);

    /// Create various testing targets.
    fooTarget = TestTarget((Environment environment) async {
      environment
        .buildDir
        .childFile('out')
        ..createSync(recursive: true)
        ..writeAsStringSync('hey');
      fooInvocations++;
    })
      ..name = 'foo'
      ..inputs = const <Source>[
        Source.pattern('{PROJECT_DIR}/foo.dart'),
      ]
      ..outputs = const <Source>[
        Source.pattern('{BUILD_DIR}/out'),
      ]
      ..dependencies = <Target>[];
    barTarget = TestTarget((Environment environment) async {
      environment.buildDir
        .childFile('bar')
        ..createSync(recursive: true)
        ..writeAsStringSync('there');
      barInvocations++;
    })
      ..name = 'bar'
      ..inputs = const <Source>[
        Source.pattern('{BUILD_DIR}/out'),
      ]
      ..outputs = const <Source>[
        Source.pattern('{BUILD_DIR}/bar'),
      ]
      ..dependencies = <Target>[];
    fizzTarget = TestTarget((Environment environment) async {
      throw Exception('something bad happens');
    })
      ..name = 'fizz'
      ..inputs = const <Source>[
        Source.pattern('{BUILD_DIR}/out'),
      ]
      ..outputs = const <Source>[
        Source.pattern('{BUILD_DIR}/fizz'),
      ]
      ..dependencies = <Target>[fooTarget];
    sharedTarget = TestTarget((Environment environment) async {
      shared += 1;
    })
      ..name = 'shared'
      ..inputs = const <Source>[
        Source.pattern('{PROJECT_DIR}/foo.dart'),
      ];
    testbed = Testbed(
      setup: () {
        environment = Environment.test(
          globals.fs.currentDirectory,
        );
        globals.fs.file('foo.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('');
        globals.fs.file('pubspec.yaml').createSync();
      },
      overrides: <Type, Generator>{
        Platform: () => mockPlatform,
      },
    );
  });

  test('Does not throw exception if asked to build with missing inputs', () => testbed.run(() async {
    // Delete required input file.
    globals.fs.file('foo.dart').deleteSync();
    final BuildResult buildResult = await buildSystem.build(fooTarget, environment);

    expect(buildResult.hasException, false);
  }));

  test('Does not throw exception if it does not produce a specified output', () => testbed.run(() async {
    final Target badTarget = TestTarget((Environment environment) async {})
      ..inputs = const <Source>[
        Source.pattern('{PROJECT_DIR}/foo.dart'),
      ]
      ..outputs = const <Source>[
        Source.pattern('{BUILD_DIR}/out'),
      ];
    final BuildResult result = await buildSystem.build(badTarget, environment);

    expect(result.hasException, false);
  }));

  test('Saves a stamp file with inputs and outputs', () => testbed.run(() async {
    await buildSystem.build(fooTarget, environment);

    final File stampFile = globals.fs.file(globals.fs.path.join(environment.buildDir.path, 'foo.stamp'));
    expect(stampFile.existsSync(), true);

    final Map<String, dynamic> stampContents = castStringKeyedMap(json.decode(stampFile.readAsStringSync()));
    expect(stampContents['inputs'], <Object>['/foo.dart']);
  }));

  test('Creates a BuildResult with inputs and outputs', () => testbed.run(() async {
    final BuildResult result = await buildSystem.build(fooTarget, environment);

    expect(result.inputFiles.single.path, globals.fs.path.absolute('foo.dart'));
    expect(result.outputFiles.single.path,
        globals.fs.path.absolute(globals.fs.path.join(environment.buildDir.path, 'out')));
  }));

  test('Does not re-invoke build if stamp is valid', () => testbed.run(() async {
    await buildSystem.build(fooTarget, environment);
    await buildSystem.build(fooTarget, environment);

    expect(fooInvocations, 1);
  }));

  test('Re-invoke build if input is modified', () => testbed.run(() async {
    await buildSystem.build(fooTarget, environment);

    globals.fs.file('foo.dart').writeAsStringSync('new contents');

    await buildSystem.build(fooTarget, environment);
    expect(fooInvocations, 2);
  }));

  test('does not re-invoke build if input timestamp changes', () => testbed.run(() async {
    await buildSystem.build(fooTarget, environment);

    globals.fs.file('foo.dart').writeAsStringSync('');

    await buildSystem.build(fooTarget, environment);
    expect(fooInvocations, 1);
  }));

  test('does not re-invoke build if output timestamp changes', () => testbed.run(() async {
    await buildSystem.build(fooTarget, environment);

    environment.buildDir.childFile('out').writeAsStringSync('hey');

    await buildSystem.build(fooTarget, environment);
    expect(fooInvocations, 1);
  }));


  test('Re-invoke build if output is modified', () => testbed.run(() async {
    await buildSystem.build(fooTarget, environment);

    environment.buildDir.childFile('out').writeAsStringSync('Something different');

    await buildSystem.build(fooTarget, environment);
    expect(fooInvocations, 2);
  }));

  test('Runs dependencies of targets', () => testbed.run(() async {
    barTarget.dependencies.add(fooTarget);

    await buildSystem.build(barTarget, environment);

    expect(globals.fs.file(globals.fs.path.join(environment.buildDir.path, 'bar')).existsSync(), true);
    expect(fooInvocations, 1);
    expect(barInvocations, 1);
  }));

  test('Only invokes shared dependencies once', () => testbed.run(() async {
    fooTarget.dependencies.add(sharedTarget);
    barTarget.dependencies.add(sharedTarget);
    barTarget.dependencies.add(fooTarget);

    await buildSystem.build(barTarget, environment);

    expect(shared, 1);
  }));

  test('Automatically cleans old outputs when dag changes', () => testbed.run(() async {
    final TestTarget testTarget = TestTarget((Environment envionment) async {
      environment.buildDir.childFile('foo.out').createSync();
    })
      ..inputs = const <Source>[Source.pattern('{PROJECT_DIR}/foo.dart')]
      ..outputs = const <Source>[Source.pattern('{BUILD_DIR}/foo.out')];
    globals.fs.file('foo.dart').createSync();

    await buildSystem.build(testTarget, environment);

    expect(environment.buildDir.childFile('foo.out').existsSync(), true);

    final TestTarget testTarget2 = TestTarget((Environment envionment) async {
      environment.buildDir.childFile('bar.out').createSync();
    })
      ..inputs = const <Source>[Source.pattern('{PROJECT_DIR}/foo.dart')]
      ..outputs = const <Source>[Source.pattern('{BUILD_DIR}/bar.out')];

    await buildSystem.build(testTarget2, environment);

    expect(environment.buildDir.childFile('bar.out').existsSync(), true);
    expect(environment.buildDir.childFile('foo.out').existsSync(), false);
  }));

  test('Does not crash when filesytem and cache are out of sync', () => testbed.run(() async {
    final TestTarget testTarget = TestTarget((Environment environment) async {
      environment.buildDir.childFile('foo.out').createSync();
    })
      ..inputs = const <Source>[Source.pattern('{PROJECT_DIR}/foo.dart')]
      ..outputs = const <Source>[Source.pattern('{BUILD_DIR}/foo.out')];
    globals.fs.file('foo.dart').createSync();

    await buildSystem.build(testTarget, environment);

    expect(environment.buildDir.childFile('foo.out').existsSync(), true);
    environment.buildDir.childFile('foo.out').deleteSync();

    final TestTarget testTarget2 = TestTarget((Environment environment) async {
      environment.buildDir.childFile('bar.out').createSync();
    })
      ..inputs = const <Source>[Source.pattern('{PROJECT_DIR}/foo.dart')]
      ..outputs = const <Source>[Source.pattern('{BUILD_DIR}/bar.out')];

    await buildSystem.build(testTarget2, environment);

    expect(environment.buildDir.childFile('bar.out').existsSync(), true);
    expect(environment.buildDir.childFile('foo.out').existsSync(), false);
  }));

  test('reruns build if stamp is corrupted', () => testbed.run(() async {
    final TestTarget testTarget = TestTarget((Environment envionment) async {
      environment.buildDir.childFile('foo.out').createSync();
    })
      ..inputs = const <Source>[Source.pattern('{PROJECT_DIR}/foo.dart')]
      ..outputs = const <Source>[Source.pattern('{BUILD_DIR}/foo.out')];
    globals.fs.file('foo.dart').createSync();
    await buildSystem.build(testTarget, environment);

    // invalid JSON
    environment.buildDir.childFile('test.stamp').writeAsStringSync('{X');
    await buildSystem.build(testTarget, environment);

    // empty file
    environment.buildDir.childFile('test.stamp').writeAsStringSync('');
    await buildSystem.build(testTarget, environment);

    // invalid format
    environment.buildDir.childFile('test.stamp').writeAsStringSync('{"inputs": 2, "outputs": 3}');
    await buildSystem.build(testTarget, environment);
  }));


  test('handles a throwing build action', () => testbed.run(() async {
    final BuildResult result = await buildSystem.build(fizzTarget, environment);

    expect(result.hasException, true);
  }));

  test('Can describe itself with JSON output', () => testbed.run(() {
    environment.buildDir.createSync(recursive: true);
    expect(fooTarget.toJson(environment), <String, dynamic>{
      'inputs':  <Object>[
        '/foo.dart',
      ],
      'outputs': <Object>[
        globals.fs.path.join(environment.buildDir.path, 'out'),
      ],
      'dependencies': <Object>[],
      'name':  'foo',
      'stamp': globals.fs.path.join(environment.buildDir.path, 'foo.stamp'),
    });
  }));

  test('Can find dependency cycles', () {
    final Target barTarget = TestTarget()..name = 'bar';
    final Target fooTarget = TestTarget()..name = 'foo';
    barTarget.dependencies.add(fooTarget);
    fooTarget.dependencies.add(barTarget);

    expect(() => checkCycles(barTarget), throwsA(isInstanceOf<CycleException>()));
  });

  test('Target with depfile dependency will not run twice without invalidation', () => testbed.run(() async {
    int called = 0;
    final TestTarget target = TestTarget((Environment environment) async {
      environment.buildDir.childFile('example.d')
        .writeAsStringSync('a.txt: b.txt');
      globals.fs.file('a.txt').writeAsStringSync('a');
      called += 1;
    })
      ..depfiles = <String>['example.d'];
    globals.fs.file('b.txt').writeAsStringSync('b');

    await buildSystem.build(target, environment);

    expect(globals.fs.file('a.txt').existsSync(), true);
    expect(called, 1);

    // Second build is up to date due to depfil parse.
    await buildSystem.build(target, environment);
    expect(called, 1);
  }));

  test('output directory is an input to the build',  () => testbed.run(() async {
    final Environment environmentA = Environment.test(globals.fs.currentDirectory, outputDir: globals.fs.directory('a'));
    final Environment environmentB = Environment.test(globals.fs.currentDirectory, outputDir: globals.fs.directory('b'));

    expect(environmentA.buildDir.path, isNot(environmentB.buildDir.path));
  }));

  test('A target with depfile dependencies can delete stale outputs on the first run',  () => testbed.run(() async {
    int called = 0;
    final TestTarget target = TestTarget((Environment environment) async {
      if (called == 0) {
        environment.buildDir.childFile('example.d')
          .writeAsStringSync('a.txt c.txt: b.txt');
        globals.fs.file('a.txt').writeAsStringSync('a');
        globals.fs.file('c.txt').writeAsStringSync('a');
      } else {
        // On second run, we no longer claim c.txt as an output.
        environment.buildDir.childFile('example.d')
          .writeAsStringSync('a.txt: b.txt');
        globals.fs.file('a.txt').writeAsStringSync('a');
      }
      called += 1;
    })
      ..depfiles = const <String>['example.d'];
    globals.fs.file('b.txt').writeAsStringSync('b');

    await buildSystem.build(target, environment);

    expect(globals.fs.file('a.txt').existsSync(), true);
    expect(globals.fs.file('c.txt').existsSync(), true);
    expect(called, 1);

    // rewrite an input to force a rerun, espect that the old c.txt is deleted.
    globals.fs.file('b.txt').writeAsStringSync('ba');
    await buildSystem.build(target, environment);

    expect(globals.fs.file('a.txt').existsSync(), true);
    expect(globals.fs.file('c.txt').existsSync(), false);
    expect(called, 2);
  }));
}

class MockPlatform extends Mock implements Platform {}

// Work-around for silly lint check.
T nonconst<T>(T input) => input;

class TestTarget extends Target {
  TestTarget([this._build]);

  final Future<void> Function(Environment environment) _build;

  @override
  Future<void> build(Environment environment) => _build(environment);

  @override
  List<Target> dependencies = <Target>[];

  @override
  List<Source> inputs = <Source>[];

  @override
  List<String> depfiles = <String>[];

  @override
  String name = 'test';

  @override
  List<Source> outputs = <Source>[];
}
