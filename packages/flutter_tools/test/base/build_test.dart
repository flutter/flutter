// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show json;

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/base/build.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/ios/mac.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:mockito/mockito.dart';

import '../src/common.dart';
import '../src/context.dart';

class MockFlutterVersion extends Mock implements FlutterVersion {}
class MockAndroidSdk extends Mock implements AndroidSdk {}
class MockArtifacts extends Mock implements Artifacts {}
class MockXcode extends Mock implements Xcode {}

class _FakeGenSnapshot implements GenSnapshot {
  _FakeGenSnapshot({
    this.succeed = true,
  });

  final bool succeed;
  Map<String, String> outputs = <String, String>{};
  int _callCount = 0;
  SnapshotType _snapshotType;
  String _packagesPath;
  String _depfilePath;
  List<String> _additionalArgs;

  int get callCount => _callCount;

  SnapshotType get snapshotType => _snapshotType;

  String get packagesPath => _packagesPath;

  String get depfilePath => _depfilePath;

  List<String> get additionalArgs => _additionalArgs;

  @override
  Future<int> run({
    SnapshotType snapshotType,
    String packagesPath,
    String depfilePath,
    IOSArch iosArch,
    Iterable<String> additionalArgs,
  }) async {
    _callCount += 1;
    _snapshotType = snapshotType;
    _packagesPath = packagesPath;
    _depfilePath = depfilePath;
    _additionalArgs = additionalArgs.toList();

    if (!succeed)
      return 1;
    outputs.forEach((String filePath, String fileContent) {
      fs.file(filePath).writeAsString(fileContent);
    });
    return 0;
  }
}

void main() {
  group('SnapshotType', () {
    test('throws, if build mode is null', () {
      expect(
        () => new SnapshotType(TargetPlatform.android_x64, null),
        throwsA(anything),
      );
    });
    test('does not throw, if target platform is null', () {
      expect(new SnapshotType(null, BuildMode.release), isNotNull);
    });
  });

  group('Snapshotter - Script Snapshots', () {
    const String kVersion = '123456abcdef';
    const String kIsolateSnapshotData = 'isolate_snapshot.bin';
    const String kVmSnapshotData = 'vm_isolate_snapshot.bin';

    _FakeGenSnapshot genSnapshot;
    MemoryFileSystem fs;
    MockFlutterVersion mockVersion;
    ScriptSnapshotter snapshotter;
    MockArtifacts mockArtifacts;

    setUp(() {
      fs = new MemoryFileSystem();
      fs.file(kIsolateSnapshotData).writeAsStringSync('snapshot data');
      fs.file(kVmSnapshotData).writeAsStringSync('vm data');
      genSnapshot = new _FakeGenSnapshot();
      genSnapshot.outputs = <String, String>{
        'output.snapshot': '',
        'output.snapshot.d': 'output.snapshot.d : main.dart',
      };
      mockVersion = new MockFlutterVersion();
      when(mockVersion.frameworkRevision).thenReturn(kVersion);
      snapshotter = new ScriptSnapshotter();
      mockArtifacts = new MockArtifacts();
      when(mockArtifacts.getArtifactPath(Artifact.isolateSnapshotData)).thenReturn(kIsolateSnapshotData);
      when(mockArtifacts.getArtifactPath(Artifact.vmSnapshotData)).thenReturn(kVmSnapshotData);
    });

    final Map<Type, Generator> contextOverrides = <Type, Generator>{
      Artifacts: () => mockArtifacts,
      FileSystem: () => fs,
      FlutterVersion: () => mockVersion,
      GenSnapshot: () => genSnapshot,
    };

    Future<void> writeFingerprint({ Map<String, String> files = const <String, String>{} }) {
      return fs.file('output.snapshot.d.fingerprint').writeAsString(json.encode(<String, dynamic>{
        'version': kVersion,
        'properties': <String, String>{
          'buildMode': BuildMode.debug.toString(),
          'targetPlatform': '',
          'entryPoint': 'main.dart',
        },
        'files': <String, dynamic>{
          kVmSnapshotData: '2ec34912477a46c03ddef07e8b909b46',
          kIsolateSnapshotData: '621b3844bb7d4d17d2cfc5edf9a91c4c',
        }..addAll(files),
      }));
    }

    void expectFingerprintHas({
      String entryPoint = 'main.dart',
      Map<String, String> checksums = const <String, String>{},
    }) {
      final Map<String, dynamic> jsonObject = json.decode(fs.file('output.snapshot.d.fingerprint').readAsStringSync());
      expect(jsonObject['properties']['entryPoint'], entryPoint);
      expect(jsonObject['files'], hasLength(checksums.length + 2));
      checksums.forEach((String filePath, String checksum) {
        expect(jsonObject['files'][filePath], checksum);
      });
      expect(jsonObject['files'][kVmSnapshotData], '2ec34912477a46c03ddef07e8b909b46');
      expect(jsonObject['files'][kIsolateSnapshotData], '621b3844bb7d4d17d2cfc5edf9a91c4c');
    }

    testUsingContext('builds snapshot and fingerprint when no fingerprint is present', () async {
      await fs.file('main.dart').writeAsString('void main() {}');
      await fs.file('output.snapshot').create();
      await fs.file('output.snapshot.d').writeAsString('snapshot : main.dart');
      await snapshotter.build(
        mainPath: 'main.dart',
        snapshotPath: 'output.snapshot',
        depfilePath: 'output.snapshot.d',
        packagesPath: '.packages',
      );

      expect(genSnapshot.callCount, 1);
      expect(genSnapshot.snapshotType.platform, isNull);
      expect(genSnapshot.snapshotType.mode, BuildMode.debug);
      expect(genSnapshot.packagesPath, '.packages');
      expect(genSnapshot.additionalArgs, <String>[
        '--snapshot_kind=script',
        '--script_snapshot=output.snapshot',
        '--vm_snapshot_data=vm_isolate_snapshot.bin',
        '--isolate_snapshot_data=isolate_snapshot.bin',
        '--enable-mirrors=false',
        'main.dart',
      ]);
      expectFingerprintHas(checksums: <String, String>{
        'main.dart': '27f5ebf0f8c559b2af9419d190299a5e',
        'output.snapshot': 'd41d8cd98f00b204e9800998ecf8427e',
      });
    }, overrides: contextOverrides);

    testUsingContext('builds snapshot and fingerprint when fingerprints differ', () async {
      await fs.file('main.dart').writeAsString('void main() {}');
      await fs.file('output.snapshot').create();
      await fs.file('output.snapshot.d').writeAsString('output.snapshot : main.dart');
      await writeFingerprint(files: <String, String>{
        'main.dart': '27f5ebf0f8c559b2af9419d190299a5e',
        'output.snapshot': 'deadbeef000b204e9800998ecaaaaa',
      });
      await snapshotter.build(
        mainPath: 'main.dart',
        snapshotPath: 'output.snapshot',
        depfilePath: 'output.snapshot.d',
        packagesPath: '.packages',
      );

      expect(genSnapshot.callCount, 1);
      expectFingerprintHas(checksums: <String, String>{
        'main.dart': '27f5ebf0f8c559b2af9419d190299a5e',
        'output.snapshot': 'd41d8cd98f00b204e9800998ecf8427e',
      });
    }, overrides: contextOverrides);

    testUsingContext('builds snapshot and fingerprint when fingerprints match but previous snapshot not present', () async {
      await fs.file('main.dart').writeAsString('void main() {}');
      await fs.file('output.snapshot.d').writeAsString('output.snapshot : main.dart');
      await writeFingerprint(files: <String, String>{
        'main.dart': '27f5ebf0f8c559b2af9419d190299a5e',
        'output.snapshot': 'd41d8cd98f00b204e9800998ecf8427e',
      });
      await snapshotter.build(
        mainPath: 'main.dart',
        snapshotPath: 'output.snapshot',
        depfilePath: 'output.snapshot.d',
        packagesPath: '.packages',
      );

      expect(genSnapshot.callCount, 1);
      expectFingerprintHas(checksums: <String, String>{
        'main.dart': '27f5ebf0f8c559b2af9419d190299a5e',
        'output.snapshot': 'd41d8cd98f00b204e9800998ecf8427e',
      });
    }, overrides: contextOverrides);

    testUsingContext('builds snapshot and fingerprint when main entry point changes to other dependency', () async {
      await fs.file('main.dart').writeAsString('import "other.dart";\nvoid main() {}');
      await fs.file('other.dart').writeAsString('import "main.dart";\nvoid main() {}');
      await fs.file('output.snapshot').create();
      await fs.file('output.snapshot.d').writeAsString('output.snapshot : main.dart');
      await writeFingerprint(files: <String, String>{
        'main.dart': 'bc096b33f14dde5e0ffaf93a1d03395c',
        'other.dart': 'e0c35f083f0ad76b2d87100ec678b516',
        'output.snapshot': 'd41d8cd98f00b204e9800998ecf8427e',
      });
      genSnapshot.outputs = <String, String>{
        'output.snapshot': '',
        'output.snapshot.d': 'output.snapshot : main.dart other.dart',
      };

      await snapshotter.build(
        mainPath: 'other.dart',
        snapshotPath: 'output.snapshot',
        depfilePath: 'output.snapshot.d',
        packagesPath: '.packages',
      );

      expect(genSnapshot.callCount, 1);
      expectFingerprintHas(
        entryPoint: 'other.dart',
        checksums: <String, String>{
          'main.dart': 'bc096b33f14dde5e0ffaf93a1d03395c',
          'other.dart': 'e0c35f083f0ad76b2d87100ec678b516',
          'output.snapshot': 'd41d8cd98f00b204e9800998ecf8427e',
        },
      );
    }, overrides: contextOverrides);

    testUsingContext('skips snapshot when fingerprints match and previous snapshot is present', () async {
      await fs.file('main.dart').writeAsString('void main() {}');
      await fs.file('output.snapshot').create();
      await fs.file('output.snapshot.d').writeAsString('output.snapshot : main.dart');
      await writeFingerprint(files: <String, String>{
        'main.dart': '27f5ebf0f8c559b2af9419d190299a5e',
        'output.snapshot': 'd41d8cd98f00b204e9800998ecf8427e',
      });
      await snapshotter.build(
        mainPath: 'main.dart',
        snapshotPath: 'output.snapshot',
        depfilePath: 'output.snapshot.d',
        packagesPath: '.packages',
      );

      expect(genSnapshot.callCount, 0);
      expectFingerprintHas(checksums: <String, String>{
        'main.dart': '27f5ebf0f8c559b2af9419d190299a5e',
        'output.snapshot': 'd41d8cd98f00b204e9800998ecf8427e',
      });
    }, overrides: contextOverrides);
  });

  group('Snapshotter - iOS AOT', () {
    const String kVmEntrypoints = 'dart_vm_entry_points.txt';
    const String kIoEntries = 'dart_io_entries.txt';
    const String kSnapshotDart = 'snapshot.dart';
    const String kEntrypointsJson = 'entry_points.json';
    const String kEntrypointsExtraJson = 'entry_points_extra.json';
    String skyEnginePath;

    _FakeGenSnapshot genSnapshot;
    MemoryFileSystem fs;
    AOTSnapshotter snapshotter;
    MockAndroidSdk mockAndroidSdk;
    MockArtifacts mockArtifacts;
    MockXcode mockXcode;

    setUp(() async {
      fs = new MemoryFileSystem();
      fs.file(kVmEntrypoints).createSync();
      fs.file(kIoEntries).createSync();
      fs.file(kSnapshotDart).createSync();
      fs.file(kEntrypointsJson).createSync();
      fs.file(kEntrypointsExtraJson).createSync();
      fs.file('.packages').writeAsStringSync('sky_engine:file:///flutter/bin/cache/pkg/sky_engine/lib/');

      skyEnginePath = fs.path.fromUri(new Uri.file('/flutter/bin/cache/pkg/sky_engine'));
      fs.directory(fs.path.join(skyEnginePath, 'lib', 'ui')).createSync(recursive: true);
      fs.directory(fs.path.join(skyEnginePath, 'sdk_ext')).createSync(recursive: true);
      fs.file(fs.path.join(skyEnginePath, '.packages')).createSync();
      fs.file(fs.path.join(skyEnginePath, 'lib', 'ui', 'ui.dart')).createSync();
      fs.file(fs.path.join(skyEnginePath, 'sdk_ext', 'vmservice_io.dart')).createSync();

      genSnapshot = new _FakeGenSnapshot();
      snapshotter = new AOTSnapshotter();
      mockAndroidSdk = new MockAndroidSdk();
      mockArtifacts = new MockArtifacts();
      mockXcode = new MockXcode();
      for (BuildMode mode in BuildMode.values) {
        when(mockArtifacts.getArtifactPath(Artifact.dartVmEntryPointsTxt, any, mode)).thenReturn(kVmEntrypoints);
        when(mockArtifacts.getArtifactPath(Artifact.dartIoEntriesTxt, any, mode)).thenReturn(kIoEntries);
        when(mockArtifacts.getArtifactPath(Artifact.snapshotDart, any, mode)).thenReturn(kSnapshotDart);
        when(mockArtifacts.getArtifactPath(Artifact.entryPointsJson, any, mode)).thenReturn(kEntrypointsJson);
        when(mockArtifacts.getArtifactPath(Artifact.entryPointsExtraJson, any, mode)).thenReturn(kEntrypointsExtraJson);
      }
    });

    final Map<Type, Generator> contextOverrides = <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      Artifacts: () => mockArtifacts,
      FileSystem: () => fs,
      GenSnapshot: () => genSnapshot,
      Xcode: () => mockXcode,
    };

    testUsingContext('iOS debug AOT snapshot is invalid', () async {
      final String outputPath = fs.path.join('build', 'foo');
      expect(await snapshotter.build(
        platform: TargetPlatform.ios,
        buildMode: BuildMode.debug,
        mainPath: 'main.dill',
        packagesPath: '.packages',
        outputPath: outputPath,
        buildSharedLibrary: false,
        previewDart2: true,
      ), isNot(equals(0)));
    }, overrides: contextOverrides);

    testUsingContext('Android arm debug AOT snapshot is invalid', () async {
      final String outputPath = fs.path.join('build', 'foo');
      expect(await snapshotter.build(
        platform: TargetPlatform.android_arm,
        buildMode: BuildMode.debug,
        mainPath: 'main.dill',
        packagesPath: '.packages',
        outputPath: outputPath,
        buildSharedLibrary: false,
        previewDart2: true,
      ), isNot(0));
    }, overrides: contextOverrides);

    testUsingContext('Android arm64 debug AOT snapshot is invalid', () async {
      final String outputPath = fs.path.join('build', 'foo');
      expect(await snapshotter.build(
        platform: TargetPlatform.android_arm64,
        buildMode: BuildMode.debug,
        mainPath: 'main.dill',
        packagesPath: '.packages',
        outputPath: outputPath,
        buildSharedLibrary: false,
        previewDart2: true,
      ), isNot(0));
    }, overrides: contextOverrides);

    testUsingContext('builds iOS armv7 profile AOT snapshot', () async {
      fs.file('main.dill').writeAsStringSync('binary magic');

      final String outputPath = fs.path.join('build', 'foo');
      fs.directory(outputPath).createSync(recursive: true);

      genSnapshot.outputs = <String, String>{
        fs.path.join(outputPath, 'snapshot_assembly.S'): '',
        fs.path.join(outputPath, 'snapshot.d'): '${fs.path.join(outputPath, 'snapshot_assembly.S')} : ',
      };

      final RunResult successResult = new RunResult(new ProcessResult(1, 0, '', ''), <String>['command name', 'arguments...']);
      when(xcode.cc(any)).thenAnswer((_) => new Future<RunResult>.value(successResult));
      when(xcode.clang(any)).thenAnswer((_) => new Future<RunResult>.value(successResult));

      final int genSnapshotExitCode = await snapshotter.build(
        platform: TargetPlatform.ios,
        buildMode: BuildMode.profile,
        mainPath: 'main.dill',
        packagesPath: '.packages',
        outputPath: outputPath,
        buildSharedLibrary: false,
        previewDart2: true,
        iosArch: IOSArch.armv7,
      );

      expect(genSnapshotExitCode, 0);
      expect(genSnapshot.callCount, 1);
      expect(genSnapshot.snapshotType.platform, TargetPlatform.ios);
      expect(genSnapshot.snapshotType.mode, BuildMode.profile);
      expect(genSnapshot.packagesPath, '.packages');
      expect(genSnapshot.additionalArgs, <String>[
        '--url_mapping=dart:ui,${fs.path.join(skyEnginePath, 'lib', 'ui', 'ui.dart')}',
        '--url_mapping=dart:vmservice_io,${fs.path.join(skyEnginePath, 'sdk_ext', 'vmservice_io.dart')}',
        '--embedder_entry_points_manifest=$kVmEntrypoints',
        '--embedder_entry_points_manifest=$kIoEntries',
        '--reify-generic-functions',
        '--strong',
        '--sync-async',
        '--snapshot_kind=app-aot-assembly',
        '--assembly=${fs.path.join(outputPath, 'snapshot_assembly.S')}',
        '--no-sim-use-hardfp',
        '--no-use-integer-division',
        'main.dill',
      ]);
    }, overrides: contextOverrides);

    testUsingContext('builds iOS arm64 profile AOT snapshot', () async {
      fs.file('main.dill').writeAsStringSync('binary magic');

      final String outputPath = fs.path.join('build', 'foo');
      fs.directory(outputPath).createSync(recursive: true);

      genSnapshot.outputs = <String, String>{
        fs.path.join(outputPath, 'snapshot_assembly.S'): '',
        fs.path.join(outputPath, 'snapshot.d'): '${fs.path.join(outputPath, 'snapshot_assembly.S')} : ',
      };

      final RunResult successResult = new RunResult(new ProcessResult(1, 0, '', ''), <String>['command name', 'arguments...']);
      when(xcode.cc(any)).thenAnswer((_) => new Future<RunResult>.value(successResult));
      when(xcode.clang(any)).thenAnswer((_) => new Future<RunResult>.value(successResult));

      final int genSnapshotExitCode = await snapshotter.build(
        platform: TargetPlatform.ios,
        buildMode: BuildMode.profile,
        mainPath: 'main.dill',
        packagesPath: '.packages',
        outputPath: outputPath,
        buildSharedLibrary: false,
        previewDart2: true,
        iosArch: IOSArch.arm64,
      );

      expect(genSnapshotExitCode, 0);
      expect(genSnapshot.callCount, 1);
      expect(genSnapshot.snapshotType.platform, TargetPlatform.ios);
      expect(genSnapshot.snapshotType.mode, BuildMode.profile);
      expect(genSnapshot.packagesPath, '.packages');
      expect(genSnapshot.additionalArgs, <String>[
        '--url_mapping=dart:ui,${fs.path.join(skyEnginePath, 'lib', 'ui', 'ui.dart')}',
        '--url_mapping=dart:vmservice_io,${fs.path.join(skyEnginePath, 'sdk_ext', 'vmservice_io.dart')}',
        '--embedder_entry_points_manifest=$kVmEntrypoints',
        '--embedder_entry_points_manifest=$kIoEntries',
        '--reify-generic-functions',
        '--strong',
        '--sync-async',
        '--snapshot_kind=app-aot-assembly',
        '--assembly=${fs.path.join(outputPath, 'snapshot_assembly.S')}',
        'main.dill',
      ]);
    }, overrides: contextOverrides);

    testUsingContext('builds Android arm profile AOT snapshot', () async {
      fs.file('main.dill').writeAsStringSync('binary magic');

      final String outputPath = fs.path.join('build', 'foo');
      fs.directory(outputPath).createSync(recursive: true);

      genSnapshot.outputs = <String, String>{
        fs.path.join(outputPath, 'vm_snapshot_data'): '',
        fs.path.join(outputPath, 'isolate_snapshot_data'): '',
        fs.path.join(outputPath, 'vm_snapshot_instr'): '',
        fs.path.join(outputPath, 'isolate_snapshot_instr'): '',
        fs.path.join(outputPath, 'snapshot.d'): '${fs.path.join(outputPath, 'vm_snapshot_data')} : ',
      };

      final RunResult successResult = new RunResult(new ProcessResult(1, 0, '', ''), <String>['command name', 'arguments...']);
      when(xcode.cc(any)).thenAnswer((_) => new Future<RunResult>.value(successResult));
      when(xcode.clang(any)).thenAnswer((_) => new Future<RunResult>.value(successResult));

      final int genSnapshotExitCode = await snapshotter.build(
        platform: TargetPlatform.android_arm,
        buildMode: BuildMode.profile,
        mainPath: 'main.dill',
        packagesPath: '.packages',
        outputPath: outputPath,
        buildSharedLibrary: false,
        previewDart2: true,
      );

      expect(genSnapshotExitCode, 0);
      expect(genSnapshot.callCount, 1);
      expect(genSnapshot.snapshotType.platform, TargetPlatform.android_arm);
      expect(genSnapshot.snapshotType.mode, BuildMode.profile);
      expect(genSnapshot.packagesPath, '.packages');
      expect(genSnapshot.additionalArgs, <String>[
        '--url_mapping=dart:ui,${fs.path.join(skyEnginePath, 'lib', 'ui', 'ui.dart')}',
        '--url_mapping=dart:vmservice_io,${fs.path.join(skyEnginePath, 'sdk_ext', 'vmservice_io.dart')}',
        '--embedder_entry_points_manifest=$kVmEntrypoints',
        '--embedder_entry_points_manifest=$kIoEntries',
        '--reify-generic-functions',
        '--strong',
        '--sync-async',
        '--snapshot_kind=app-aot-blobs',
        '--vm_snapshot_data=build/foo/vm_snapshot_data',
        '--isolate_snapshot_data=build/foo/isolate_snapshot_data',
        '--vm_snapshot_instructions=build/foo/vm_snapshot_instr',
        '--isolate_snapshot_instructions=build/foo/isolate_snapshot_instr',
        '--no-sim-use-hardfp',
        '--no-use-integer-division',
        'main.dill',
      ]);
    }, overrides: contextOverrides);

    testUsingContext('builds Android arm64 profile AOT snapshot', () async {
      fs.file('main.dill').writeAsStringSync('binary magic');

      final String outputPath = fs.path.join('build', 'foo');
      fs.directory(outputPath).createSync(recursive: true);

      genSnapshot.outputs = <String, String>{
        fs.path.join(outputPath, 'vm_snapshot_data'): '',
        fs.path.join(outputPath, 'isolate_snapshot_data'): '',
        fs.path.join(outputPath, 'vm_snapshot_instr'): '',
        fs.path.join(outputPath, 'isolate_snapshot_instr'): '',
        fs.path.join(outputPath, 'snapshot.d'): '${fs.path.join(outputPath, 'vm_snapshot_data')} : ',
      };

      final RunResult successResult = new RunResult(new ProcessResult(1, 0, '', ''), <String>['command name', 'arguments...']);
      when(xcode.cc(any)).thenAnswer((_) => new Future<RunResult>.value(successResult));
      when(xcode.clang(any)).thenAnswer((_) => new Future<RunResult>.value(successResult));

      final int genSnapshotExitCode = await snapshotter.build(
        platform: TargetPlatform.android_arm64,
        buildMode: BuildMode.profile,
        mainPath: 'main.dill',
        packagesPath: '.packages',
        outputPath: outputPath,
        buildSharedLibrary: false,
        previewDart2: true,
      );

      expect(genSnapshotExitCode, 0);
      expect(genSnapshot.callCount, 1);
      expect(genSnapshot.snapshotType.platform, TargetPlatform.android_arm64);
      expect(genSnapshot.snapshotType.mode, BuildMode.profile);
      expect(genSnapshot.packagesPath, '.packages');
      expect(genSnapshot.additionalArgs, <String>[
        '--url_mapping=dart:ui,${fs.path.join(skyEnginePath, 'lib', 'ui', 'ui.dart')}',
        '--url_mapping=dart:vmservice_io,${fs.path.join(skyEnginePath, 'sdk_ext', 'vmservice_io.dart')}',
        '--embedder_entry_points_manifest=$kVmEntrypoints',
        '--embedder_entry_points_manifest=$kIoEntries',
        '--reify-generic-functions',
        '--strong',
        '--sync-async',
        '--snapshot_kind=app-aot-blobs',
        '--vm_snapshot_data=build/foo/vm_snapshot_data',
        '--isolate_snapshot_data=build/foo/isolate_snapshot_data',
        '--vm_snapshot_instructions=build/foo/vm_snapshot_instr',
        '--isolate_snapshot_instructions=build/foo/isolate_snapshot_instr',
        'main.dill',
      ]);
    }, overrides: contextOverrides);

    testUsingContext('builds iOS release armv7 AOT snapshot', () async {
      fs.file('main.dill').writeAsStringSync('binary magic');

      final String outputPath = fs.path.join('build', 'foo');
      fs.directory(outputPath).createSync(recursive: true);

      genSnapshot.outputs = <String, String>{
        fs.path.join(outputPath, 'snapshot_assembly.S'): '',
        fs.path.join(outputPath, 'snapshot.d'): '${fs.path.join(outputPath, 'snapshot_assembly.S')} : ',
      };

      final RunResult successResult = new RunResult(new ProcessResult(1, 0, '', ''), <String>['command name', 'arguments...']);
      when(xcode.cc(any)).thenAnswer((_) => new Future<RunResult>.value(successResult));
      when(xcode.clang(any)).thenAnswer((_) => new Future<RunResult>.value(successResult));

      final int genSnapshotExitCode = await snapshotter.build(
        platform: TargetPlatform.ios,
        buildMode: BuildMode.release,
        mainPath: 'main.dill',
        packagesPath: '.packages',
        outputPath: outputPath,
        buildSharedLibrary: false,
        previewDart2: true,
        iosArch: IOSArch.armv7,
      );

      expect(genSnapshotExitCode, 0);
      expect(genSnapshot.callCount, 1);
      expect(genSnapshot.snapshotType.platform, TargetPlatform.ios);
      expect(genSnapshot.snapshotType.mode, BuildMode.release);
      expect(genSnapshot.packagesPath, '.packages');
      expect(genSnapshot.additionalArgs, <String>[
        '--url_mapping=dart:ui,${fs.path.join(skyEnginePath, 'lib', 'ui', 'ui.dart')}',
        '--url_mapping=dart:vmservice_io,${fs.path.join(skyEnginePath, 'sdk_ext', 'vmservice_io.dart')}',
        '--embedder_entry_points_manifest=$kVmEntrypoints',
        '--embedder_entry_points_manifest=$kIoEntries',
        '--reify-generic-functions',
        '--strong',
        '--sync-async',
        '--snapshot_kind=app-aot-assembly',
        '--assembly=${fs.path.join(outputPath, 'snapshot_assembly.S')}',
        '--no-sim-use-hardfp',
        '--no-use-integer-division',
        'main.dill',
      ]);
    }, overrides: contextOverrides);

    testUsingContext('builds iOS release arm64 AOT snapshot', () async {
      fs.file('main.dill').writeAsStringSync('binary magic');

      final String outputPath = fs.path.join('build', 'foo');
      fs.directory(outputPath).createSync(recursive: true);

      genSnapshot.outputs = <String, String>{
        fs.path.join(outputPath, 'snapshot_assembly.S'): '',
        fs.path.join(outputPath, 'snapshot.d'): '${fs.path.join(outputPath, 'snapshot_assembly.S')} : ',
      };

      final RunResult successResult = new RunResult(new ProcessResult(1, 0, '', ''), <String>['command name', 'arguments...']);
      when(xcode.cc(any)).thenAnswer((_) => new Future<RunResult>.value(successResult));
      when(xcode.clang(any)).thenAnswer((_) => new Future<RunResult>.value(successResult));

      final int genSnapshotExitCode = await snapshotter.build(
        platform: TargetPlatform.ios,
        buildMode: BuildMode.release,
        mainPath: 'main.dill',
        packagesPath: '.packages',
        outputPath: outputPath,
        buildSharedLibrary: false,
        previewDart2: true,
        iosArch: IOSArch.arm64,
      );

      expect(genSnapshotExitCode, 0);
      expect(genSnapshot.callCount, 1);
      expect(genSnapshot.snapshotType.platform, TargetPlatform.ios);
      expect(genSnapshot.snapshotType.mode, BuildMode.release);
      expect(genSnapshot.packagesPath, '.packages');
      expect(genSnapshot.additionalArgs, <String>[
        '--url_mapping=dart:ui,${fs.path.join(skyEnginePath, 'lib', 'ui', 'ui.dart')}',
        '--url_mapping=dart:vmservice_io,${fs.path.join(skyEnginePath, 'sdk_ext', 'vmservice_io.dart')}',
        '--embedder_entry_points_manifest=$kVmEntrypoints',
        '--embedder_entry_points_manifest=$kIoEntries',
        '--reify-generic-functions',
        '--strong',
        '--sync-async',
        '--snapshot_kind=app-aot-assembly',
        '--assembly=${fs.path.join(outputPath, 'snapshot_assembly.S')}',
        'main.dill',
      ]);
    }, overrides: contextOverrides);

    testUsingContext('returns failure if buildSharedLibrary is true but no NDK is found', () async {
      final String outputPath = fs.path.join('build', 'foo');

      when(mockAndroidSdk.ndk).thenReturn(null);

      final int genSnapshotExitCode = await snapshotter.build(
        platform: TargetPlatform.android_arm,
        buildMode: BuildMode.release,
        mainPath: 'main.dill',
        packagesPath: '.packages',
        outputPath: outputPath,
        buildSharedLibrary: true,
        previewDart2: true,
      );

      expect(genSnapshotExitCode, isNot(0));
      expect(genSnapshot.callCount, 0);
    }, overrides: contextOverrides);

    testUsingContext('builds Android arm release AOT snapshot', () async {
      fs.file('main.dill').writeAsStringSync('binary magic');

      final String outputPath = fs.path.join('build', 'foo');
      fs.directory(outputPath).createSync(recursive: true);

      genSnapshot.outputs = <String, String>{
        fs.path.join(outputPath, 'vm_snapshot_data'): '',
        fs.path.join(outputPath, 'isolate_snapshot_data'): '',
        fs.path.join(outputPath, 'vm_snapshot_instr'): '',
        fs.path.join(outputPath, 'isolate_snapshot_instr'): '',
        fs.path.join(outputPath, 'snapshot.d'): '${fs.path.join(outputPath, 'vm_snapshot_data')} : ',
      };

      final RunResult successResult = new RunResult(new ProcessResult(1, 0, '', ''), <String>['command name', 'arguments...']);
      when(xcode.cc(any)).thenAnswer((_) => new Future<RunResult>.value(successResult));
      when(xcode.clang(any)).thenAnswer((_) => new Future<RunResult>.value(successResult));

      final int genSnapshotExitCode = await snapshotter.build(
        platform: TargetPlatform.android_arm,
        buildMode: BuildMode.release,
        mainPath: 'main.dill',
        packagesPath: '.packages',
        outputPath: outputPath,
        buildSharedLibrary: false,
        previewDart2: true,
      );

      expect(genSnapshotExitCode, 0);
      expect(genSnapshot.callCount, 1);
      expect(genSnapshot.snapshotType.platform, TargetPlatform.android_arm);
      expect(genSnapshot.snapshotType.mode, BuildMode.release);
      expect(genSnapshot.packagesPath, '.packages');
      expect(genSnapshot.additionalArgs, <String>[
        '--url_mapping=dart:ui,${fs.path.join(skyEnginePath, 'lib', 'ui', 'ui.dart')}',
        '--url_mapping=dart:vmservice_io,${fs.path.join(skyEnginePath, 'sdk_ext', 'vmservice_io.dart')}',
        '--embedder_entry_points_manifest=$kVmEntrypoints',
        '--embedder_entry_points_manifest=$kIoEntries',
        '--reify-generic-functions',
        '--strong',
        '--sync-async',
        '--snapshot_kind=app-aot-blobs',
        '--vm_snapshot_data=build/foo/vm_snapshot_data',
        '--isolate_snapshot_data=build/foo/isolate_snapshot_data',
        '--vm_snapshot_instructions=build/foo/vm_snapshot_instr',
        '--isolate_snapshot_instructions=build/foo/isolate_snapshot_instr',
        '--no-sim-use-hardfp',
        '--no-use-integer-division',
        'main.dill',
      ]);
    }, overrides: contextOverrides);

    testUsingContext('builds Android arm64 release AOT snapshot', () async {
      fs.file('main.dill').writeAsStringSync('binary magic');

      final String outputPath = fs.path.join('build', 'foo');
      fs.directory(outputPath).createSync(recursive: true);

      genSnapshot.outputs = <String, String>{
        fs.path.join(outputPath, 'vm_snapshot_data'): '',
        fs.path.join(outputPath, 'isolate_snapshot_data'): '',
        fs.path.join(outputPath, 'vm_snapshot_instr'): '',
        fs.path.join(outputPath, 'isolate_snapshot_instr'): '',
        fs.path.join(outputPath, 'snapshot.d'): '${fs.path.join(outputPath, 'vm_snapshot_data')} : ',
      };

      final RunResult successResult = new RunResult(new ProcessResult(1, 0, '', ''), <String>['command name', 'arguments...']);
      when(xcode.cc(any)).thenAnswer((_) => new Future<RunResult>.value(successResult));
      when(xcode.clang(any)).thenAnswer((_) => new Future<RunResult>.value(successResult));

      final int genSnapshotExitCode = await snapshotter.build(
        platform: TargetPlatform.android_arm64,
        buildMode: BuildMode.release,
        mainPath: 'main.dill',
        packagesPath: '.packages',
        outputPath: outputPath,
        buildSharedLibrary: false,
        previewDart2: true,
      );

      expect(genSnapshotExitCode, 0);
      expect(genSnapshot.callCount, 1);
      expect(genSnapshot.snapshotType.platform, TargetPlatform.android_arm64);
      expect(genSnapshot.snapshotType.mode, BuildMode.release);
      expect(genSnapshot.packagesPath, '.packages');
      expect(genSnapshot.additionalArgs, <String>[
        '--url_mapping=dart:ui,${fs.path.join(skyEnginePath, 'lib', 'ui', 'ui.dart')}',
        '--url_mapping=dart:vmservice_io,${fs.path.join(skyEnginePath, 'sdk_ext', 'vmservice_io.dart')}',
        '--embedder_entry_points_manifest=$kVmEntrypoints',
        '--embedder_entry_points_manifest=$kIoEntries',
        '--reify-generic-functions',
        '--strong',
        '--sync-async',
        '--snapshot_kind=app-aot-blobs',
        '--vm_snapshot_data=build/foo/vm_snapshot_data',
        '--isolate_snapshot_data=build/foo/isolate_snapshot_data',
        '--vm_snapshot_instructions=build/foo/vm_snapshot_instr',
        '--isolate_snapshot_instructions=build/foo/isolate_snapshot_instr',
        'main.dill',
      ]);
    }, overrides: contextOverrides);

  });

  group('Snapshotter - Core JIT', () {
    const String kTrace = 'trace.txt';

    _FakeGenSnapshot genSnapshot;
    MemoryFileSystem fs;
    CoreJITSnapshotter snapshotter;
    MockAndroidSdk mockAndroidSdk;
    MockArtifacts mockArtifacts;

    setUp(() async {
      fs = new MemoryFileSystem();
      fs.file(kTrace).createSync();

      genSnapshot = new _FakeGenSnapshot();
      snapshotter = new CoreJITSnapshotter();
      mockAndroidSdk = new MockAndroidSdk();
      mockArtifacts = new MockArtifacts();
    });

    final Map<Type, Generator> contextOverrides = <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      Artifacts: () => mockArtifacts,
      FileSystem: () => fs,
      GenSnapshot: () => genSnapshot,
    };

    testUsingContext('iOS debug Core JIT snapshot is invalid', () async {
      final String outputPath = fs.path.join('build', 'foo');
      expect(await snapshotter.build(
        platform: TargetPlatform.ios,
        buildMode: BuildMode.debug,
        mainPath: 'main.dill',
        packagesPath: '.packages',
        outputPath: outputPath,
        compilationTraceFilePath: kTrace,
      ), isNot(equals(0)));
    }, overrides: contextOverrides);

    testUsingContext('builds Android arm debug Core JIT snapshot', () async {
      fs.file('main.dill').writeAsStringSync('binary magic');

      final String outputPath = fs.path.join('build', 'foo');
      fs.directory(outputPath).createSync(recursive: true);

      genSnapshot.outputs = <String, String>{
        fs.path.join(outputPath, 'vm_snapshot_data'): '',
        fs.path.join(outputPath, 'isolate_snapshot_data'): '',
        fs.path.join(outputPath, 'vm_snapshot_instr'): '',
        fs.path.join(outputPath, 'isolate_snapshot_instr'): '',
        fs.path.join(outputPath, 'snapshot.d'): '${fs.path.join(outputPath, 'vm_snapshot_data')} : ',
      };

      final int genSnapshotExitCode = await snapshotter.build(
        platform: TargetPlatform.android_arm,
        buildMode: BuildMode.debug,
        mainPath: 'main.dill',
        packagesPath: '.packages',
        outputPath: outputPath,
        compilationTraceFilePath: kTrace,
      );

      expect(genSnapshotExitCode, 0);
      expect(genSnapshot.callCount, 1);
      expect(genSnapshot.snapshotType.platform, TargetPlatform.android_arm);
      expect(genSnapshot.snapshotType.mode, BuildMode.debug);
      expect(genSnapshot.packagesPath, '.packages');
      expect(genSnapshot.additionalArgs, <String>[
        '--reify-generic-functions',
        '--strong',
        '--sync-async',
        '--enable_asserts',
        '--snapshot_kind=core-jit',
        '--vm_snapshot_data=build/foo/vm_snapshot_data',
        '--isolate_snapshot_data=build/foo/isolate_snapshot_data',
        '--vm_snapshot_instructions=build/foo/vm_snapshot_instr',
        '--isolate_snapshot_instructions=build/foo/isolate_snapshot_instr',
        '--load_compilation_trace=trace.txt',
        '--no-sim-use-hardfp',
        '--no-use-integer-division',
        'main.dill',
      ]);
    }, overrides: contextOverrides);

    testUsingContext('builds Android arm64 debug Core JIT snapshot', () async {
      fs.file('main.dill').writeAsStringSync('binary magic');

      final String outputPath = fs.path.join('build', 'foo');
      fs.directory(outputPath).createSync(recursive: true);

      genSnapshot.outputs = <String, String>{
        fs.path.join(outputPath, 'vm_snapshot_data'): '',
        fs.path.join(outputPath, 'isolate_snapshot_data'): '',
        fs.path.join(outputPath, 'vm_snapshot_instr'): '',
        fs.path.join(outputPath, 'isolate_snapshot_instr'): '',
        fs.path.join(outputPath, 'snapshot.d'): '${fs.path.join(outputPath, 'vm_snapshot_data')} : ',
      };

      final int genSnapshotExitCode = await snapshotter.build(
        platform: TargetPlatform.android_arm64,
        buildMode: BuildMode.debug,
        mainPath: 'main.dill',
        packagesPath: '.packages',
        outputPath: outputPath,
        compilationTraceFilePath: kTrace,
      );

      expect(genSnapshotExitCode, 0);
      expect(genSnapshot.callCount, 1);
      expect(genSnapshot.snapshotType.platform, TargetPlatform.android_arm64);
      expect(genSnapshot.snapshotType.mode, BuildMode.debug);
      expect(genSnapshot.packagesPath, '.packages');
      expect(genSnapshot.additionalArgs, <String>[
        '--reify-generic-functions',
        '--strong',
        '--sync-async',
        '--enable_asserts',
        '--snapshot_kind=core-jit',
        '--vm_snapshot_data=build/foo/vm_snapshot_data',
        '--isolate_snapshot_data=build/foo/isolate_snapshot_data',
        '--vm_snapshot_instructions=build/foo/vm_snapshot_instr',
        '--isolate_snapshot_instructions=build/foo/isolate_snapshot_instr',
        '--load_compilation_trace=trace.txt',
        'main.dill',
      ]);
    }, overrides: contextOverrides);

    testUsingContext('iOS release Core JIT snapshot is invalid', () async {
      final String outputPath = fs.path.join('build', 'foo');
      expect(await snapshotter.build(
        platform: TargetPlatform.ios,
        buildMode: BuildMode.profile,
        mainPath: 'main.dill',
        packagesPath: '.packages',
        outputPath: outputPath,
        compilationTraceFilePath: kTrace,
      ), isNot(equals(0)));
    }, overrides: contextOverrides);

    testUsingContext('builds Android arm profile Core JIT snapshot', () async {
      fs.file('main.dill').writeAsStringSync('binary magic');

      final String outputPath = fs.path.join('build', 'foo');
      fs.directory(outputPath).createSync(recursive: true);

      genSnapshot.outputs = <String, String>{
        fs.path.join(outputPath, 'vm_snapshot_data'): '',
        fs.path.join(outputPath, 'isolate_snapshot_data'): '',
        fs.path.join(outputPath, 'vm_snapshot_instr'): '',
        fs.path.join(outputPath, 'isolate_snapshot_instr'): '',
        fs.path.join(outputPath, 'snapshot.d'): '${fs.path.join(outputPath, 'vm_snapshot_data')} : ',
      };

      final int genSnapshotExitCode = await snapshotter.build(
        platform: TargetPlatform.android_arm,
        buildMode: BuildMode.profile,
        mainPath: 'main.dill',
        packagesPath: '.packages',
        outputPath: outputPath,
        compilationTraceFilePath: kTrace,
      );

      expect(genSnapshotExitCode, 0);
      expect(genSnapshot.callCount, 1);
      expect(genSnapshot.snapshotType.platform, TargetPlatform.android_arm);
      expect(genSnapshot.snapshotType.mode, BuildMode.profile);
      expect(genSnapshot.packagesPath, '.packages');
      expect(genSnapshot.additionalArgs, <String>[
        '--reify-generic-functions',
        '--strong',
        '--sync-async',
        '--snapshot_kind=core-jit',
        '--vm_snapshot_data=build/foo/vm_snapshot_data',
        '--isolate_snapshot_data=build/foo/isolate_snapshot_data',
        '--vm_snapshot_instructions=build/foo/vm_snapshot_instr',
        '--isolate_snapshot_instructions=build/foo/isolate_snapshot_instr',
        '--load_compilation_trace=trace.txt',
        '--no-sim-use-hardfp',
        '--no-use-integer-division',
        'main.dill',
      ]);
    }, overrides: contextOverrides);

    testUsingContext('builds Android arm64 profile Core JIT snapshot', () async {
      fs.file('main.dill').writeAsStringSync('binary magic');

      final String outputPath = fs.path.join('build', 'foo');
      fs.directory(outputPath).createSync(recursive: true);

      genSnapshot.outputs = <String, String>{
        fs.path.join(outputPath, 'vm_snapshot_data'): '',
        fs.path.join(outputPath, 'isolate_snapshot_data'): '',
        fs.path.join(outputPath, 'vm_snapshot_instr'): '',
        fs.path.join(outputPath, 'isolate_snapshot_instr'): '',
        fs.path.join(outputPath, 'snapshot.d'): '${fs.path.join(outputPath, 'vm_snapshot_data')} : ',
      };

      final int genSnapshotExitCode = await snapshotter.build(
        platform: TargetPlatform.android_arm64,
        buildMode: BuildMode.profile,
        mainPath: 'main.dill',
        packagesPath: '.packages',
        outputPath: outputPath,
        compilationTraceFilePath: kTrace,
      );

      expect(genSnapshotExitCode, 0);
      expect(genSnapshot.callCount, 1);
      expect(genSnapshot.snapshotType.platform, TargetPlatform.android_arm64);
      expect(genSnapshot.snapshotType.mode, BuildMode.profile);
      expect(genSnapshot.packagesPath, '.packages');
      expect(genSnapshot.additionalArgs, <String>[
        '--reify-generic-functions',
        '--strong',
        '--sync-async',
        '--snapshot_kind=core-jit',
        '--vm_snapshot_data=build/foo/vm_snapshot_data',
        '--isolate_snapshot_data=build/foo/isolate_snapshot_data',
        '--vm_snapshot_instructions=build/foo/vm_snapshot_instr',
        '--isolate_snapshot_instructions=build/foo/isolate_snapshot_instr',
        '--load_compilation_trace=trace.txt',
        'main.dill',
      ]);
    }, overrides: contextOverrides);

    testUsingContext('iOS release Core JIT snapshot is invalid', () async {
      final String outputPath = fs.path.join('build', 'foo');
      expect(await snapshotter.build(
        platform: TargetPlatform.ios,
        buildMode: BuildMode.release,
        mainPath: 'main.dill',
        packagesPath: '.packages',
        outputPath: outputPath,
        compilationTraceFilePath: kTrace,
      ), isNot(equals(0)));
    }, overrides: contextOverrides);

    testUsingContext('builds Android arm release Core JIT snapshot', () async {
      fs.file('main.dill').writeAsStringSync('binary magic');

      final String outputPath = fs.path.join('build', 'foo');
      fs.directory(outputPath).createSync(recursive: true);

      genSnapshot.outputs = <String, String>{
        fs.path.join(outputPath, 'vm_snapshot_data'): '',
        fs.path.join(outputPath, 'isolate_snapshot_data'): '',
        fs.path.join(outputPath, 'vm_snapshot_instr'): '',
        fs.path.join(outputPath, 'isolate_snapshot_instr'): '',
        fs.path.join(outputPath, 'snapshot.d'): '${fs.path.join(outputPath, 'vm_snapshot_data')} : ',
      };

      final int genSnapshotExitCode = await snapshotter.build(
        platform: TargetPlatform.android_arm,
        buildMode: BuildMode.release,
        mainPath: 'main.dill',
        packagesPath: '.packages',
        outputPath: outputPath,
        compilationTraceFilePath: kTrace,
      );

      expect(genSnapshotExitCode, 0);
      expect(genSnapshot.callCount, 1);
      expect(genSnapshot.snapshotType.platform, TargetPlatform.android_arm);
      expect(genSnapshot.snapshotType.mode, BuildMode.release);
      expect(genSnapshot.packagesPath, '.packages');
      expect(genSnapshot.additionalArgs, <String>[
        '--reify-generic-functions',
        '--strong',
        '--sync-async',
        '--snapshot_kind=core-jit',
        '--vm_snapshot_data=build/foo/vm_snapshot_data',
        '--isolate_snapshot_data=build/foo/isolate_snapshot_data',
        '--vm_snapshot_instructions=build/foo/vm_snapshot_instr',
        '--isolate_snapshot_instructions=build/foo/isolate_snapshot_instr',
        '--load_compilation_trace=trace.txt',
        '--no-sim-use-hardfp',
        '--no-use-integer-division',
        'main.dill',
      ]);
    }, overrides: contextOverrides);

    testUsingContext('builds Android arm64 release Core JIT snapshot', () async {
      fs.file('main.dill').writeAsStringSync('binary magic');

      final String outputPath = fs.path.join('build', 'foo');
      fs.directory(outputPath).createSync(recursive: true);

      genSnapshot.outputs = <String, String>{
        fs.path.join(outputPath, 'vm_snapshot_data'): '',
        fs.path.join(outputPath, 'isolate_snapshot_data'): '',
        fs.path.join(outputPath, 'vm_snapshot_instr'): '',
        fs.path.join(outputPath, 'isolate_snapshot_instr'): '',
        fs.path.join(outputPath, 'snapshot.d'): '${fs.path.join(outputPath, 'vm_snapshot_data')} : ',
      };

      final int genSnapshotExitCode = await snapshotter.build(
        platform: TargetPlatform.android_arm64,
        buildMode: BuildMode.release,
        mainPath: 'main.dill',
        packagesPath: '.packages',
        outputPath: outputPath,
        compilationTraceFilePath: kTrace,
      );

      expect(genSnapshotExitCode, 0);
      expect(genSnapshot.callCount, 1);
      expect(genSnapshot.snapshotType.platform, TargetPlatform.android_arm64);
      expect(genSnapshot.snapshotType.mode, BuildMode.release);
      expect(genSnapshot.packagesPath, '.packages');
      expect(genSnapshot.additionalArgs, <String>[
        '--reify-generic-functions',
        '--strong',
        '--sync-async',
        '--snapshot_kind=core-jit',
        '--vm_snapshot_data=build/foo/vm_snapshot_data',
        '--isolate_snapshot_data=build/foo/isolate_snapshot_data',
        '--vm_snapshot_instructions=build/foo/vm_snapshot_instr',
        '--isolate_snapshot_instructions=build/foo/isolate_snapshot_instr',
        '--load_compilation_trace=trace.txt',
        'main.dill',
      ]);
    }, overrides: contextOverrides);

  });
}
