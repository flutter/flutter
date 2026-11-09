// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/exceptions.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/context/tool_context.dart';
import 'package:flutter_tools/src/project.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart';
import '../../src/testbed.dart';

final Platform windowsPlatform = FakePlatform(operatingSystem: 'windows');

void main() {
  late TestBed testbed;
  late SourceVisitor visitor;
  late Environment environment;
  late FileSystem fileSystem;
  late Cache cache;

  setUp(() {
    testbed = TestBed(
      setup: () {
        final ToolContext(
          :Artifacts artifacts,
          cache: Cache contextCache,
          :FileSystem fs,
          :Logger logger,
        ) = const DelegatingToolContext();
        cache = contextCache;
        fileSystem = fs;
        fileSystem.directory('cache').createSync();
        final Directory outputs = fileSystem.directory('outputs')..createSync();
        environment = Environment.test(
          fileSystem.currentDirectory,
          outputDir: outputs,
          artifacts: artifacts, // using real artifacts
          processManager: FakeProcessManager.any(),
          fileSystem: fileSystem,
          // engineVersion being null simulates a local engine.
          logger: logger,
        );
        visitor = SourceVisitor(environment);
        environment.buildDir.createSync(recursive: true);
      },
    );
  });

  test(
    'configures implicit vs explicit correctly',
    () => testbed.run(() {
      expect(const Source.pattern('{PROJECT_DIR}/foo').implicit, false);
      expect(const Source.pattern('{PROJECT_DIR}/*foo').implicit, true);
    }),
  );

  test(
    'can substitute {PROJECT_DIR}/foo',
    () => testbed.run(() {
      fileSystem.file('foo').createSync();
      const fooSource = Source.pattern('{PROJECT_DIR}/foo');
      fooSource.accept(visitor);

      expect(visitor.sources.single.path, fileSystem.path.absolute('foo'));
    }),
  );

  test(
    'can substitute {OUTPUT_DIR}/foo',
    () => testbed.run(() {
      fileSystem.file('foo').createSync();
      const fooSource = Source.pattern('{OUTPUT_DIR}/foo');
      fooSource.accept(visitor);

      expect(
        visitor.sources.single.path,
        fileSystem.path.absolute(fileSystem.path.join('outputs', 'foo')),
      );
    }),
  );

  test(
    'can substitute {BUILD_DIR}/bar',
    () => testbed.run(() {
      final String path = fileSystem.path.join(environment.buildDir.path, 'bar');
      fileSystem.file(path).createSync();
      const barSource = Source.pattern('{BUILD_DIR}/bar');
      barSource.accept(visitor);

      expect(visitor.sources.single.path, fileSystem.path.absolute(path));
    }),
  );

  test(
    'can substitute {FLUTTER_ROOT}/foo',
    () => testbed.run(() {
      final String path = fileSystem.path.join(environment.flutterRootDir.path, 'foo');
      fileSystem.file(path).createSync();
      const barSource = Source.pattern('{FLUTTER_ROOT}/foo');
      barSource.accept(visitor);

      expect(visitor.sources.single.path, fileSystem.path.absolute(path));
    }),
  );

  test(
    'can substitute Artifact',
    () => testbed.run(() {
      final String path = fileSystem.path.join(
        cache.getArtifactDirectory('engine').path,
        'windows-x64',
        'foo',
      );
      fileSystem.file(path).createSync(recursive: true);
      const fizzSource = Source.artifact(
        Artifact.windowsDesktopPath,
        platform: TargetPlatform.windows_x64,
      );
      fizzSource.accept(visitor);

      expect(visitor.sources.single.resolveSymbolicLinksSync(), fileSystem.path.absolute(path));
    }),
  );

  test(
    'can substitute {PROJECT_DIR}/*.fizz',
    () => testbed.run(() {
      const fizzSource = Source.pattern('{PROJECT_DIR}/*.fizz');
      fizzSource.accept(visitor);

      expect(visitor.sources, isEmpty);

      fileSystem.file('foo.fizz').createSync();
      fileSystem.file('foofizz').createSync();

      fizzSource.accept(visitor);

      expect(visitor.sources.single.path, fileSystem.path.absolute('foo.fizz'));
    }),
  );

  test(
    'can substitute {PROJECT_DIR}/fizz.*',
    () => testbed.run(() {
      const fizzSource = Source.pattern('{PROJECT_DIR}/fizz.*');
      fizzSource.accept(visitor);

      expect(visitor.sources, isEmpty);

      fileSystem.file('fizz.foo').createSync();
      fileSystem.file('fizz').createSync();

      fizzSource.accept(visitor);

      expect(visitor.sources.single.path, fileSystem.path.absolute('fizz.foo'));
    }),
  );

  test(
    'can substitute {PROJECT_DIR}/a*bc',
    () => testbed.run(() {
      const fizzSource = Source.pattern('{PROJECT_DIR}/bc*bc');
      fizzSource.accept(visitor);

      expect(visitor.sources, isEmpty);

      fileSystem.file('bcbc').createSync();
      fileSystem.file('bc').createSync();

      fizzSource.accept(visitor);

      expect(visitor.sources.single.path, fileSystem.path.absolute('bcbc'));
    }),
  );

  test(
    'crashes on bad substitute of two **',
    () => testbed.run(() {
      const fizzSource = Source.pattern('{PROJECT_DIR}/*.*bar');

      fileSystem.file('abcd.bar').createSync();

      expect(() => fizzSource.accept(visitor), throwsA(isA<InvalidPatternException>()));
    }),
  );

  test(
    "can't substitute foo",
    () => testbed.run(() {
      const invalidBase = Source.pattern('foo');

      expect(() => invalidBase.accept(visitor), throwsA(isA<InvalidPatternException>()));
    }),
  );

  test(
    'can substitute optional files',
    () => testbed.run(() {
      const missingSource = Source.pattern('{PROJECT_DIR}/foo', optional: true);

      expect(fileSystem.file('foo').existsSync(), false);
      missingSource.accept(visitor);
      expect(visitor.sources, isEmpty);
    }),
  );

  test(
    'can resolve a missing depfile',
    () => testbed.run(() {
      visitor.visitDepfile('foo.d');

      expect(visitor.sources, isEmpty);
      expect(visitor.containsNewDepfile, true);
    }),
  );

  test(
    'can resolve a populated depfile',
    () => testbed.run(() {
      environment.buildDir.childFile('foo.d').writeAsStringSync('a.dart : c.dart');

      visitor.visitDepfile('foo.d');
      expect(visitor.sources.single.path, 'c.dart');
      expect(visitor.containsNewDepfile, false);

      final outputVisitor = SourceVisitor(environment, false);
      outputVisitor.visitDepfile('foo.d');

      expect(outputVisitor.sources.single.path, 'a.dart');
      expect(outputVisitor.containsNewDepfile, false);
    }),
  );

  test(
    'does not crash on completely invalid depfile',
    () => testbed.run(() {
      environment.buildDir.childFile('foo.d').writeAsStringSync('hello, world');

      visitor.visitDepfile('foo.d');
      expect(visitor.sources, isEmpty);
      expect(visitor.containsNewDepfile, false);
    }),
  );

  test(
    'can parse depfile with windows paths',
    () => testbed.run(() {
      environment.buildDir.childFile('foo.d').writeAsStringSync(r'a.dart: C:\\foo\\bar.txt');

      visitor.visitDepfile('foo.d');
      expect(visitor.sources.single.path, r'C:\foo\bar.txt');
      expect(visitor.containsNewDepfile, false);
    }, overrides: <Type, Generator>{Platform: () => windowsPlatform}),
  );

  test(
    'can parse depfile with spaces in paths',
    () => testbed.run(() {
      environment.buildDir.childFile('foo.d').writeAsStringSync(r'a.dart: foo\ bar.txt');

      visitor.visitDepfile('foo.d');
      expect(visitor.sources.single.path, r'foo bar.txt');
      expect(visitor.containsNewDepfile, false);
    }),
  );

  test(
    'Non-local engine builds use the engine.stamp file as an Artifact dependency',
    () => testbed.run(() {
      final artifacts = Artifacts.test();
      final versionedEnvironment = Environment.test(
        fileSystem.currentDirectory,
        artifacts: artifacts,
        processManager: FakeProcessManager.any(),
        fileSystem: fileSystem,
        logger: environment.logger,
        engineVersion: 'abcdefghijklmon', // Use a versioned engine.
      );
      visitor = SourceVisitor(versionedEnvironment);

      const fizzSource = Source.artifact(
        Artifact.windowsDesktopPath,
        platform: TargetPlatform.windows_x64,
      );
      fizzSource.accept(visitor);

      expect(visitor.sources.single.path, contains('engine.stamp'));
    }),
  );

  test(
    'can substitute project file',
    () => testbed.run(() {
      final String path = fileSystem.file('.flutter-plugins-dependencies').absolute.path;
      fileSystem.file(path).createSync(recursive: true);
      final pluginsSource = Source.fromProject(
        (FlutterProject project) => project.flutterPluginsDependenciesFile,
      );
      pluginsSource.accept(visitor);

      expect(visitor.sources.single.absolute.path, path);
      expect(visitor.sources.single, exists);
    }),
  );

  test(
    'can substitute nonexistent project file',
    () => testbed.run(() {
      final String path = fileSystem.file('.flutter-plugins-dependencies').absolute.path;
      final pluginsSource = Source.fromProject(
        (FlutterProject project) => project.flutterPluginsDependenciesFile,
      );
      pluginsSource.accept(visitor);

      expect(visitor.sources.single.absolute.path, path);
      expect(visitor.sources.single, isNot(exists));
    }),
  );

  test(
    'can substitute optional project file',
    () => testbed.run(() {
      final String path = fileSystem.file('.flutter-plugins-dependencies').absolute.path;
      fileSystem.file(path).createSync(recursive: true);
      final pluginsSource = Source.fromProject(
        (FlutterProject project) => project.flutterPluginsDependenciesFile,
        optional: true,
      );
      pluginsSource.accept(visitor);

      expect(visitor.sources.single.absolute.path, path);
      expect(visitor.sources.single, exists);
    }),
  );

  test(
    'skips nonexistent optional project file',
    () => testbed.run(() {
      final pluginsSource = Source.fromProject(
        (FlutterProject project) => project.flutterPluginsDependenciesFile,
        optional: true,
      );
      pluginsSource.accept(visitor);

      expect(visitor.sources.isEmpty, isTrue);
    }),
  );
}
