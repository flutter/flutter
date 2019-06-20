// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/exceptions.dart';
import 'package:flutter_tools/src/build_system/file_cache.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:mockito/mockito.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/testbed.dart';

void main() {
  group(Target, () {
    Testbed testbed;
    MockPlatform mockPlatform;
    Environment environment;
    Target fooTarget;
    Target barTarget;
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
            invocation: (Map<String, ChangeType> updates, Environment environment) {
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
            invocation: (Map<String, ChangeType> updates, Environment environment) {
              environment.buildDir
                .childFile('bar')
                ..createSync(recursive: true)
                ..writeAsStringSync('there');
              barInvocations++;
            }
          );
          buildSystem = BuildSystem(<Target>[
            fooTarget,
            barTarget,
          ]);
        },
        overrides: <Type, Generator>{
          Platform: () => mockPlatform,
        }
      );
    });

    test('Throws exception if asked to build non-existent target', () => testbed.run(() {
      expect(buildSystem.build('not_real', environment, const BuildSystemConfig()), throwsA(isInstanceOf<Exception>()));
    }));

    test('Throws exception if asked to build with missing inputs', () => testbed.run(() {
      // Delete required input file.
      fs.file('foo.dart').deleteSync();

      expect(buildSystem.build('foo', environment, const BuildSystemConfig()), throwsA(isInstanceOf<MissingInputException>()));
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

    test('Runs dependencies of targets', () => testbed.run(() async {
      await buildSystem.build('bar', environment, const BuildSystemConfig());

      expect(fs.file(fs.path.join(environment.buildDir.path, 'bar')).existsSync(), true);
      expect(fooInvocations, 1);
      expect(barInvocations, 1);
    }));

    test('Can describe itself with JSON output', () => testbed.run(() {
      expect(fooTarget.toJson(environment), <String, dynamic>{
        'inputs':  <Object>[
          '/foo.dart'
        ],
        'dependencies': <Object>[],
        'name':  'foo',
        'stamp': fs.path.join(environment.buildDir.path, 'foo.stamp'),
      });
    }));

    test('Compute update recognizes added files', () => testbed.run(() async {
      fs.directory('build').createSync();
      final FileCache fileCache = FileCache(environment);
      fileCache.initialize();
      final List<SourceFile> inputs = fooTarget.resolveInputs(environment);
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
      final FileCache fileCache = FileCache(environment);
      fileCache.initialize();
      fileCache.persist();

      expect(fs.file(fs.path.join('build', '.filecache')).existsSync(), true);
      expect(fs.file(fs.path.join('build', '.filecache')).readAsStringSync(), '');
      expect(fs.file(fs.path.join('build', '.filecache_version')).existsSync(), true);
      expect(fs.file(fs.path.join('build', '.filecache_version')).readAsStringSync(), '1');
    }));

    test('saves and restores to file cache', () => testbed.run(() {
      final SourceFile file = SourceFile(fs.file('foo.dart')
        ..createSync()
        ..writeAsStringSync('hello'));
      final FileCache fileCache = FileCache(environment);
      fileCache.initialize();
      fileCache.hashFiles(<SourceFile>[file]);
      fileCache.persist();

      final String currentHash =  fileCache.currentHashes[file.path];
      expect(fs.file(fs.path.join('build', '.filecache')).readAsStringSync(), '${fs.path.absolute('foo.dart')} : $currentHash');
      expect(fs.file(fs.path.join('build', '.filecache_version')).readAsStringSync(), '1');

      final FileCache newFileCache = FileCache(environment);
      newFileCache.initialize();
      expect(newFileCache.currentHashes, isEmpty);
      expect(newFileCache.previousHashes[fs.path.absolute('foo.dart')],  currentHash);
      newFileCache.persist();

      // Still persisted correctly.
      expect(fs.file(fs.path.join('build', '.filecache')).readAsStringSync(), '${fs.path.absolute('foo.dart')} : $currentHash');
      expect(fs.file(fs.path.join('build', '.filecache_version')).readAsStringSync(), '1');
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
            sharedTarget = Target(
              name: 'shared',
              inputs: const <Source>[
                Source.pattern('{PROJECT_DIR}/foo.dart'),
              ],
              outputs: const <Source>[],
              dependencies: <Target>[],
              invocation: (Map<String, ChangeType> updates, Environment environment) {
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
                invocation: (Map<String, ChangeType> updates, Environment environment) {
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
                invocation: (Map<String, ChangeType> updates, Environment environment) {
                  environment
                    .buildDir
                    .childFile('bar')
                    ..createSync(recursive: true)
                    ..writeAsStringSync('there');
                }
            );
            buildSystem = BuildSystem(<Target>[
              fooTarget,
              barTarget,
              sharedTarget,
            ]);
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

  group('SourceFile', () {
    MemoryFileSystem memoryFileSystem;

    setUp(() {
       memoryFileSystem = MemoryFileSystem();
    });

    test('exposes limited API from the underlying file', () {
      final File file = memoryFileSystem.file('test')
        ..createSync()
        ..writeAsBytesSync(<int>[1, 2, 3]);
      final SourceFile sourceFile = SourceFile(file);

      expect(sourceFile.existsSync(), true);
      expect(sourceFile.path, '/test');
      expect(sourceFile.bytesForVersion(), <int>[1, 2, 3]);
    });

    test('exposes limited API from the underlying directory', () {
      final Directory directory = memoryFileSystem.directory('test')
        ..createSync();
      final SourceFile sourceFile = SourceFile(directory);

      expect(sourceFile.existsSync(), true);
      expect(sourceFile.path, '/test');
      expect(sourceFile.bytesForVersion(), directory.statSync().modified.toIso8601String().codeUnits);
    });

    test('Allows separate versioning of file', () {
      final File file = memoryFileSystem.file('test')
        ..writeAsBytesSync(<int>[1, 2, 3])
        ..createSync();
      final File version = memoryFileSystem.file('version')
        ..createSync()
        ..writeAsBytesSync(<int>[4, 5, 6]);
      final SourceFile sourceFile = SourceFile(file, version);

      expect(sourceFile.existsSync(), true);
      expect(sourceFile.path, '/test');
      expect(sourceFile.bytesForVersion(), <int>[4, 5, 6]);
    });
  });

  group('Patterns', () {
    Testbed testbed;
    SourceVisitor visitor;
    Environment environment;

    setUp(() {
      testbed = Testbed(setup: () {
        fs.directory('cache').createSync();
        environment = Environment(
          projectDir: fs.currentDirectory,
          cacheDir: fs.directory('cache'),
          buildDir: fs.directory('build'),
          flutterRootDir: fs.currentDirectory,
        );
        visitor = SourceVisitor(environment);
        environment.buildDir.createSync(recursive: true);
      });
    });

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

    test('can substitute {CACHE_DIR}/fizz', () => testbed.run(() {
      final String path = fs.path.join('cache', 'fizz');
      fs.file(path).createSync();
      const Source fizzSource = Source.pattern('{CACHE_DIR}/fizz');
      fizzSource.accept(visitor);

      expect(visitor.sources.single.path, fs.path.absolute(path));
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
      invocation: null,
      dependencies: nonconst(<Target>[])
    );
    final Target fooTarget = Target(
      name: 'foo',
      inputs: <Source>[],
      outputs: <Source>[],
      invocation: null,
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