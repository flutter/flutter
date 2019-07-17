// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/exceptions.dart';
import 'package:flutter_tools/src/build_system/file_hash_store.dart';
import 'package:flutter_tools/src/build_system/filecache.pb.dart' as pb;
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/testbed.dart';

void main() {
  setUpAll(() {
    Cache.disableLocking();
  });

  group(Target, () {
    Testbed testbed;
    MockPlatform mockPlatform;
    Environment environment;
    Target fooTarget;
    Target barTarget;
    Target fizzTarget;
    BuildSystem buildSystem;
    int fooInvocations;
    int barInvocations;

    setUp(() {
      fooInvocations = 0;
      barInvocations = 0;
      mockPlatform = MockPlatform();
      // Keep file paths the same.
      when(mockPlatform.isWindows).thenReturn(false);
      testbed = Testbed(
        setup: () {
          environment = Environment(
            projectDir: fs.currentDirectory,
          );
          fs.file('foo.dart').createSync(recursive: true);
          fs.file('pubspec.yaml').createSync();
          fooTarget = Target(
            name: 'foo',
            inputs: const <Source>[
              Source.pattern('{PROJECT_DIR}/foo.dart'),
            ],
            outputs: const <Source>[
              Source.pattern('{BUILD_DIR}/out'),
            ],
            dependencies: <Target>[],
            buildAction: (Map<String, ChangeType> updates, Environment environment) {
              environment
                .buildDir
                .childFile('out')
                ..createSync(recursive: true)
                ..writeAsStringSync('hey');
              fooInvocations++;
            }
          );
          barTarget = Target(
            name: 'bar',
            inputs: const <Source>[
              Source.pattern('{BUILD_DIR}/out'),
            ],
            outputs: const <Source>[
              Source.pattern('{BUILD_DIR}/bar'),
            ],
            dependencies: <Target>[fooTarget],
            buildAction: (Map<String, ChangeType> updates, Environment environment) {
              environment.buildDir
                .childFile('bar')
                ..createSync(recursive: true)
                ..writeAsStringSync('there');
              barInvocations++;
            }
          );
          fizzTarget = Target(
              name: 'fizz',
              inputs: const <Source>[
                Source.pattern('{BUILD_DIR}/out'),
              ],
              outputs: const <Source>[
                Source.pattern('{BUILD_DIR}/fizz'),
              ],
              dependencies: <Target>[fooTarget],
              buildAction: (Map<String, ChangeType> updates, Environment environment) {
                throw Exception('something bad happens');
              }
          );
          buildSystem = BuildSystem(<String, Target>{
            fooTarget.name: fooTarget,
            barTarget.name: barTarget,
            fizzTarget.name: fizzTarget,
          });
        },
        overrides: <Type, Generator>{
          Platform: () => mockPlatform,
        }
      );
    });

    test('can describe build rules', () => testbed.run(() {
      expect(buildSystem.describe('foo', environment), <Object>[
        <String, Object>{
          'name': 'foo',
          'dependencies': <String>[],
          'inputs': <String>['/foo.dart'],
          'outputs': <String>[fs.path.join(environment.buildDir.path, 'out')],
          'stamp': fs.path.join(environment.buildDir.path, 'foo.stamp'),
        }
      ]);
    }));

    test('Throws exception if asked to build non-existent target', () => testbed.run(() {
      expect(buildSystem.build('not_real', environment, const BuildSystemConfig()), throwsA(isInstanceOf<Exception>()));
    }));

    test('Throws exception if asked to build with missing inputs', () => testbed.run(() async {
      // Delete required input file.
      fs.file('foo.dart').deleteSync();
      final BuildResult buildResult = await buildSystem.build('foo', environment, const BuildSystemConfig());

      expect(buildResult.hasException, true);
      expect(buildResult.exceptions.values.single.exception, isInstanceOf<MissingInputException>());
    }));

    test('Throws exception if it does not produce a specified output', () => testbed.run(() async {
      final Target badTarget = Target
        (buildAction: (Map<String, ChangeType> inputs, Environment environment) {},
        inputs: const <Source>[
          Source.pattern('{PROJECT_DIR}/foo.dart'),
        ],
        outputs: const <Source>[
          Source.pattern('{BUILD_DIR}/out')
        ],
        name: 'bad'
      );
      buildSystem = BuildSystem(<String, Target>{
        badTarget.name: badTarget,
      });
      final BuildResult result = await buildSystem.build('bad', environment, const BuildSystemConfig());

      expect(result.hasException, true);
      expect(result.exceptions.values.single.exception, isInstanceOf<MissingOutputException>());
    }));

    test('Saves a stamp file with inputs and outputs', () => testbed.run(() async {
      await buildSystem.build('foo', environment, const BuildSystemConfig());

      final File stampFile = fs.file(fs.path.join(environment.buildDir.path, 'foo.stamp'));
      expect(stampFile.existsSync(), true);

      final Map<String, Object> stampContents = json.decode(stampFile.readAsStringSync());
      expect(stampContents['inputs'], <Object>['/foo.dart']);
    }));

    test('Does not re-invoke build if stamp is valid', () => testbed.run(() async {
      await buildSystem.build('foo', environment, const BuildSystemConfig());
      await buildSystem.build('foo', environment, const BuildSystemConfig());

      expect(fooInvocations, 1);
    }));

    test('Re-invoke build if input is modified', () => testbed.run(() async {
      await buildSystem.build('foo', environment, const BuildSystemConfig());

      fs.file('foo.dart').writeAsStringSync('new contents');

      await buildSystem.build('foo', environment, const BuildSystemConfig());
      expect(fooInvocations, 2);
    }));

    test('does not re-invoke build if input timestamp changes', () => testbed.run(() async {
      await buildSystem.build('foo', environment, const BuildSystemConfig());

      fs.file('foo.dart').writeAsStringSync('');

      await buildSystem.build('foo', environment, const BuildSystemConfig());
      expect(fooInvocations, 1);
    }));

    test('does not re-invoke build if output timestamp changes', () => testbed.run(() async {
      await buildSystem.build('foo', environment, const BuildSystemConfig());

      environment.buildDir.childFile('out').writeAsStringSync('hey');

      await buildSystem.build('foo', environment, const BuildSystemConfig());
      expect(fooInvocations, 1);
    }));


    test('Re-invoke build if output is modified', () => testbed.run(() async {
      await buildSystem.build('foo', environment, const BuildSystemConfig());

      environment.buildDir.childFile('out').writeAsStringSync('Something different');

      await buildSystem.build('foo', environment, const BuildSystemConfig());
      expect(fooInvocations, 2);
    }));

    test('Runs dependencies of targets', () => testbed.run(() async {
      await buildSystem.build('bar', environment, const BuildSystemConfig());

      expect(fs.file(fs.path.join(environment.buildDir.path, 'bar')).existsSync(), true);
      expect(fooInvocations, 1);
      expect(barInvocations, 1);
    }));

    test('handles a throwing build action', () => testbed.run(() async {
      final BuildResult result = await buildSystem.build('fizz', environment, const BuildSystemConfig());

      expect(result.hasException, true);
    }));

    test('Can describe itself with JSON output', () => testbed.run(() {
      environment.buildDir.createSync(recursive: true);
      expect(fooTarget.toJson(environment), <String, dynamic>{
        'inputs':  <Object>[
          '/foo.dart'
        ],
        'outputs': <Object>[
          fs.path.join(environment.buildDir.path, 'out'),
        ],
        'dependencies': <Object>[],
        'name':  'foo',
        'stamp': fs.path.join(environment.buildDir.path, 'foo.stamp'),
      });
    }));

    test('Compute update recognizes added files', () => testbed.run(() async {
      fs.directory('build').createSync();
      final FileHashStore fileCache = FileHashStore(environment);
      fileCache.initialize();
      final List<File> inputs = fooTarget.resolveInputs(environment);
      final Map<String, ChangeType> changes = await fooTarget.computeChanges(inputs, environment, fileCache);
      fileCache.persist();

      expect(changes, <String, ChangeType>{
        '/foo.dart': ChangeType.Added
      });

      await buildSystem.build('foo', environment, const BuildSystemConfig());
      final Map<String, ChangeType> secondChanges = await fooTarget.computeChanges(inputs, environment, fileCache);

      expect(secondChanges, <String, ChangeType>{});
    }));
  });

  group('FileCache', () {
    Testbed testbed;
    Environment environment;

    setUp(() {
      testbed = Testbed(setup: () {
        fs.directory('build').createSync();
        environment = Environment(
          projectDir: fs.currentDirectory,
        );
      });
    });

    test('Initializes file cache', () => testbed.run(() {
      final FileHashStore fileCache = FileHashStore(environment);
      fileCache.initialize();
      fileCache.persist();

      expect(fs.file(fs.path.join('build', '.filecache')).existsSync(), true);

      final List<int> buffer = fs.file(fs.path.join('build', '.filecache')).readAsBytesSync();
      final pb.FileStorage fileStorage = pb.FileStorage.fromBuffer(buffer);

      expect(fileStorage.files, isEmpty);
      expect(fileStorage.version, 1);
    }));

    test('saves and restores to file cache', () => testbed.run(() {
      final File file = fs.file('foo.dart')
        ..createSync()
        ..writeAsStringSync('hello');
      final FileHashStore fileCache = FileHashStore(environment);
      fileCache.initialize();
      fileCache.hashFiles(<File>[file]);
      fileCache.persist();
      final String currentHash =  fileCache.currentHashes[file.resolveSymbolicLinksSync()];
      final List<int> buffer = fs.file(fs.path.join('build', '.filecache')).readAsBytesSync();
      pb.FileStorage fileStorage = pb.FileStorage.fromBuffer(buffer);

      expect(fileStorage.files.single.hash, currentHash);
      expect(fileStorage.files.single.path, file.resolveSymbolicLinksSync());


      final FileHashStore newFileCache = FileHashStore(environment);
      newFileCache.initialize();
      expect(newFileCache.currentHashes, isEmpty);
      expect(newFileCache.previousHashes[fs.path.absolute('foo.dart')],  currentHash);
      newFileCache.persist();

      // Still persisted correctly.
      fileStorage = pb.FileStorage.fromBuffer(buffer);

      expect(fileStorage.files.single.hash, currentHash);
      expect(fileStorage.files.single.path, file.resolveSymbolicLinksSync());
    }));
  });

  group('Target', () {
    Testbed testbed;
    MockPlatform mockPlatform;
    Environment environment;
    Target sharedTarget;
    BuildSystem buildSystem;
    int shared;

    setUp(() {
      shared = 0;
      Cache.flutterRoot = '';
      mockPlatform = MockPlatform();
      // Keep file paths the same.
      when(mockPlatform.isWindows).thenReturn(false);
      when(mockPlatform.isLinux).thenReturn(true);
      when(mockPlatform.isMacOS).thenReturn(false);
      testbed = Testbed(
          setup: () {
            environment = Environment(
              projectDir: fs.currentDirectory,
            );
            fs.file('foo.dart').createSync(recursive: true);
            fs.file('pubspec.yaml').createSync();
            sharedTarget = Target(
              name: 'shared',
              inputs: const <Source>[
                Source.pattern('{PROJECT_DIR}/foo.dart'),
              ],
              outputs: const <Source>[],
              dependencies: <Target>[],
              buildAction: (Map<String, ChangeType> updates, Environment environment) {
                shared += 1;
              }
            );
            final Target fooTarget = Target(
                name: 'foo',
                inputs: const <Source>[
                  Source.pattern('{PROJECT_DIR}/foo.dart'),
                ],
                outputs: const <Source>[
                  Source.pattern('{BUILD_DIR}/out'),
                ],
                dependencies: <Target>[sharedTarget],
                buildAction: (Map<String, ChangeType> updates, Environment environment) {
                  environment
                    .buildDir
                    .childFile('out')
                    ..createSync(recursive: true)
                    ..writeAsStringSync('hey');
                }
            );
            final Target barTarget = Target(
                name: 'bar',
                inputs: const <Source>[
                  Source.pattern('{BUILD_DIR}/out'),
                ],
                outputs: const <Source>[
                  Source.pattern('{BUILD_DIR}/bar'),
                ],
                dependencies: <Target>[fooTarget, sharedTarget],
                buildAction: (Map<String, ChangeType> updates, Environment environment) {
                  environment
                    .buildDir
                    .childFile('bar')
                    ..createSync(recursive: true)
                    ..writeAsStringSync('there');
                }
            );
            buildSystem = BuildSystem(<String, Target>{
              fooTarget.name: fooTarget,
              barTarget.name: barTarget,
              sharedTarget.name: sharedTarget,
            });
          },
          overrides: <Type, Generator>{
            Platform: () => mockPlatform,
          }
      );
    });

    test('Only invokes shared target once', () => testbed.run(() async {
      await buildSystem.build('bar', environment, const BuildSystemConfig());

      expect(shared, 1);
    }));
  });

  group('Source', () {
    Testbed testbed;
    SourceVisitor visitor;
    Environment environment;

    setUp(() {
      testbed = Testbed(setup: () {
        fs.directory('cache').createSync();
        environment = Environment(
          projectDir: fs.currentDirectory,
          buildDir: fs.directory('build'),
        );
        visitor = SourceVisitor(environment);
        environment.buildDir.createSync(recursive: true);
      });
    });

    test('configures implicit vs explict correctly', () => testbed.run(() {
      expect(const Source.pattern('{PROJECT_DIR}/foo').implicit, false);
      expect(const Source.pattern('{PROJECT_DIR}/*foo').implicit, true);
      expect(Source.function((Environment environment) => <File>[]).implicit, true);
      expect(Source.behavior(TestBehavior()).implicit, true);
    }));

    test('can substitute {PROJECT_DIR}/foo', () => testbed.run(() {
      fs.file('foo').createSync();
      const Source fooSource = Source.pattern('{PROJECT_DIR}/foo');
      fooSource.accept(visitor);

      expect(visitor.sources.single.path, fs.path.absolute('foo'));
    }));

    test('can substitute {BUILD_DIR}/bar', () => testbed.run(() {
      final String path = fs.path.join(environment.buildDir.path, 'bar');
      fs.file(path).createSync();
      const Source barSource = Source.pattern('{BUILD_DIR}/bar');
      barSource.accept(visitor);

      expect(visitor.sources.single.path, fs.path.absolute(path));
    }));

    test('can substitute Artifact', () => testbed.run(() {
      final String path = fs.path.join(
        Cache.instance.getArtifactDirectory('engine').path,
        'windows-x64',
        'foo',
      );
      fs.file(path).createSync(recursive: true);
      const Source fizzSource = Source.artifact(Artifact.windowsDesktopPath, platform: TargetPlatform.windows_x64);
      fizzSource.accept(visitor);

      expect(visitor.sources.single.resolveSymbolicLinksSync(), fs.path.absolute(path));
    }));

    test('can substitute {PROJECT_DIR}/*.fizz', () => testbed.run(() {
      const Source fizzSource = Source.pattern('{PROJECT_DIR}/*.fizz');
      fizzSource.accept(visitor);

      expect(visitor.sources, isEmpty);

      fs.file('foo.fizz').createSync();
      fs.file('foofizz').createSync();


      fizzSource.accept(visitor);

      expect(visitor.sources.single.path, fs.path.absolute('foo.fizz'));
    }));

    test('can substitute {PROJECT_DIR}/fizz.*', () => testbed.run(() {
      const Source fizzSource = Source.pattern('{PROJECT_DIR}/fizz.*');
      fizzSource.accept(visitor);

      expect(visitor.sources, isEmpty);

      fs.file('fizz.foo').createSync();
      fs.file('fizz').createSync();

      fizzSource.accept(visitor);

      expect(visitor.sources.single.path, fs.path.absolute('fizz.foo'));
    }));


    test('can substitute {PROJECT_DIR}/a*bc', () => testbed.run(() {
      const Source fizzSource = Source.pattern('{PROJECT_DIR}/bc*bc');
      fizzSource.accept(visitor);

      expect(visitor.sources, isEmpty);

      fs.file('bcbc').createSync();
      fs.file('bc').createSync();

      fizzSource.accept(visitor);

      expect(visitor.sources.single.path, fs.path.absolute('bcbc'));
    }));


    test('crashes on bad substitute of two **', () => testbed.run(() {
      const Source fizzSource = Source.pattern('{PROJECT_DIR}/*.*bar');

      fs.file('abcd.bar').createSync();

      expect(() => fizzSource.accept(visitor), throwsA(isInstanceOf<InvalidPatternException>()));
    }));


    test('can\'t substitute foo', () => testbed.run(() {
      const Source invalidBase = Source.pattern('foo');

      expect(() => invalidBase.accept(visitor), throwsA(isInstanceOf<InvalidPatternException>()));
    }));
  });



  test('Can find dependency cycles', () {
    final Target barTarget = Target(
      name: 'bar',
      inputs: <Source>[],
      outputs: <Source>[],
      buildAction: null,
      dependencies: nonconst(<Target>[])
    );
    final Target fooTarget = Target(
      name: 'foo',
      inputs: <Source>[],
      outputs: <Source>[],
      buildAction: null,
      dependencies: nonconst(<Target>[])
    );
    barTarget.dependencies.add(fooTarget);
    fooTarget.dependencies.add(barTarget);
    expect(() => checkCycles(barTarget), throwsA(isInstanceOf<CycleException>()));
  });
}

class MockPlatform extends Mock implements Platform {}

// Work-around for silly lint check.
T nonconst<T>(T input) => input;

class TestBehavior extends SourceBehavior {
  @override
  List<File> inputs(Environment environment) {
    return null;
  }

  @override
  List<File> outputs(Environment environment) {
    return null;
  }
}
