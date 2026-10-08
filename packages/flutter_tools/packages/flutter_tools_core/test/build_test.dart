// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:test/test.dart';

class _RecordingSourceVisitor implements SourceVisitor {
  final visitedPatterns = <(String, bool)>[];
  final visitedArtifacts = <(Artifact, String?, BuildMode?)>[];
  final visitedHostArtifacts = <HostArtifact>[];

  @override
  void visitPattern(String pattern, bool optional) {
    visitedPatterns.add((pattern, optional));
  }

  @override
  void visitArtifact(Artifact artifact, String? platform, BuildMode? mode) {
    visitedArtifacts.add((artifact, platform, mode));
  }

  @override
  void visitHostArtifact(HostArtifact artifact) {
    visitedHostArtifacts.add(artifact);
  }
}

void main() {
  group('BuildMode', () {
    test('fromCliName parses valid build modes and throws on invalid mode', () {
      expect(BuildMode.fromCliName('debug'), BuildMode.debug);
      expect(BuildMode.fromCliName('profile'), BuildMode.profile);
      expect(BuildMode.fromCliName('release'), BuildMode.release);
      expect(BuildMode.fromCliName('jit_release'), BuildMode.jitRelease);
      expect(() => BuildMode.fromCliName('invalid'), throwsArgumentError);
    });

    test('properties and formatting getters return expected values', () {
      expect(BuildMode.debug.isRelease, isFalse);
      expect(BuildMode.debug.isJit, isTrue);
      expect(BuildMode.debug.isPrecompiled, isFalse);
      expect(BuildMode.debug.cliName, 'debug');
      expect(BuildMode.debug.uppercaseName, 'Debug');
      expect(BuildMode.debug.friendlyName, 'debug');
      expect(BuildMode.debug.uppercaseFriendlyName, 'Debug');
      expect(BuildMode.debug.toString(), 'debug');

      expect(BuildMode.profile.isRelease, isFalse);
      expect(BuildMode.profile.isJit, isFalse);
      expect(BuildMode.profile.isPrecompiled, isTrue);
      expect(BuildMode.profile.cliName, 'profile');
      expect(BuildMode.profile.uppercaseName, 'Profile');

      expect(BuildMode.release.isRelease, isTrue);
      expect(BuildMode.release.isJit, isFalse);
      expect(BuildMode.release.isPrecompiled, isTrue);
      expect(BuildMode.release.cliName, 'release');
      expect(BuildMode.release.uppercaseName, 'Release');

      expect(BuildMode.jitRelease.isRelease, isTrue);
      expect(BuildMode.jitRelease.isJit, isTrue);
      expect(BuildMode.jitRelease.isPrecompiled, isFalse);
      expect(BuildMode.jitRelease.cliName, 'jit_release');
      expect(BuildMode.jitRelease.uppercaseName, 'Jit_release');
      expect(BuildMode.jitRelease.friendlyName, 'jit release');
      expect(BuildMode.jitRelease.uppercaseFriendlyName, 'Jit release');
      expect(BuildMode.jitRelease.toString(), 'jit_release');
    });
  });

  group('Artifact and HostArtifact', () {
    test('equality, hashCode, and toString work as expected', () {
      const artifact1 = Artifact('icuData');
      const artifact2 = Artifact('icuData');
      const artifact3 = Artifact('genSnapshot');

      expect(artifact1, equals(artifact2));
      expect(artifact1.hashCode, equals(artifact2.hashCode));
      expect(artifact1, isNot(equals(artifact3)));
      expect(artifact1.toString(), 'icuData');

      const hostArtifact1 = HostArtifact('impellerc');
      const hostArtifact2 = HostArtifact('impellerc');
      const hostArtifact3 = HostArtifact('libtessellator');

      expect(hostArtifact1, equals(hostArtifact2));
      expect(hostArtifact1.hashCode, equals(hostArtifact2.hashCode));
      expect(hostArtifact1, isNot(equals(hostArtifact3)));
      expect(hostArtifact1.toString(), 'impellerc');
    });

    test('built-in constants have expected names and metadata', () {
      expect(BuiltInArtifacts.icuData.name, 'icuData');
      expect(BuiltInArtifacts.genSnapshot.name, 'genSnapshot');
      expect(BuiltInArtifacts.flutterPatchedSdkPath.name, 'flutterPatchedSdkPath');
      expect(BuiltInHostArtifacts.impellerc.name, 'impellerc');
      expect(BuiltInHostArtifacts.libtessellator.name, 'libtessellator');
      expect(BuiltInTargets.kernelSnapshot.name, 'kernel_snapshot_program');
      expect(BuiltInTargets.copyAssets.name, 'copy_assets');
    });
  });

  group('Source', () {
    test('pattern, artifact, and hostArtifact serialize, deserialize, and visit', () {
      const patternSource = Source.pattern('{PROJECT_DIR}/pubspec.yaml', optional: true);
      expect(patternSource.implicit, isFalse);
      expect(const Source.pattern('{OUTPUT_DIR}/bundle/*').implicit, isTrue);
      expect(Source.fromJson(patternSource.toMap()), equals(patternSource));
      expect(patternSource.toString(), contains('{PROJECT_DIR}/pubspec.yaml'));

      const artifactSource = Source.artifact(
        BuiltInArtifacts.genSnapshot,
        mode: .release,
        platform: 'linux-x64',
      );
      expect(artifactSource.implicit, isFalse);
      expect(Source.fromJson(artifactSource.toMap()), equals(artifactSource));
      expect(artifactSource.toString(), contains('genSnapshot'));

      const hostArtifactSource = Source.hostArtifact(BuiltInHostArtifacts.impellerc);
      expect(hostArtifactSource.implicit, isFalse);
      expect(Source.fromJson(hostArtifactSource.toMap()), equals(hostArtifactSource));
      expect(hostArtifactSource.toString(), contains('impellerc'));

      final visitor = _RecordingSourceVisitor();
      patternSource.accept(visitor);
      artifactSource.accept(visitor);
      hostArtifactSource.accept(visitor);

      expect(
        visitor.visitedPatterns,
        equals(<(String, bool)>[('{PROJECT_DIR}/pubspec.yaml', true)]),
      );
      expect(
        visitor.visitedArtifacts,
        equals(<(Artifact, String?, BuildMode?)>[
          (BuiltInArtifacts.genSnapshot, 'linux-x64', .release),
        ]),
      );
      expect(visitor.visitedHostArtifacts, equals(<HostArtifact>[BuiltInHostArtifacts.impellerc]));
    });

    test('fromJson throws ArgumentError on invalid type or missing fields', () {
      expect(
        () => Source.fromJson(const <String, Object?>{'type': 'unknown'}),
        throwsArgumentError,
      );
      expect(
        () => Source.fromJson(const <String, Object?>{'type': 'pattern'}),
        throwsArgumentError,
      );
      expect(
        () => Source.fromJson(const <String, Object?>{'type': 'artifact'}),
        throwsArgumentError,
      );
      expect(
        () => Source.fromJson(const <String, Object?>{'type': 'host_artifact'}),
        throwsArgumentError,
      );
    });
  });

  group('SimpleTarget', () {
    test('exposes configured metadata', () {
      const target = SimpleTarget(
        name: 'custom_target',
        dependencies: <Target>[BuiltInTargets.copyAssets],
        depfiles: <String>['custom.d'],
        inputs: <Source>[Source.pattern('{PROJECT_DIR}/pubspec.yaml')],
        outputDir: '{PROJECT_DIR}/out',
        outputs: <Source>[Source.pattern('{OUTPUT_DIR}/out.bin')],
      );

      expect(target.name, 'custom_target');
      expect(target.dependencies, equals(const <Target>[BuiltInTargets.copyAssets]));
      expect(target.depfiles, equals(const <String>['custom.d']));
      expect(target.inputs, equals(const <Source>[Source.pattern('{PROJECT_DIR}/pubspec.yaml')]));
      expect(target.outputDir, '{PROJECT_DIR}/out');
      expect(target.outputs, equals(const <Source>[Source.pattern('{OUTPUT_DIR}/out.bin')]));
    });
  });

  group('ExtensionBuildTarget', () {
    test('serializes and deserializes correctly with all fields', () {
      const target = ExtensionBuildTarget(
        description: 'A custom Linux build target.',
        name: 'custom-linux-build',
        targetPlatform: 'linux-x64',
        dependencies: <String>['copy_assets'],
        inputs: <Source>[
          Source.pattern('{PROJECT_DIR}/pubspec.yaml'),
          Source.artifact(BuiltInArtifacts.icuData),
        ],
        isTopLevel: false,
        outputDir: '{PROJECT_DIR}/build/linux',
        outputs: <Source>[Source.pattern('{OUTPUT_DIR}/bundle/*')],
      );

      final Map<String, Object?> map = target.toMap();
      expect(map[ExtensionBuildTarget.nameKey], 'custom-linux-build');
      expect(map[ExtensionBuildTarget.targetPlatformKey], 'linux-x64');
      expect(map[ExtensionBuildTarget.descriptionKey], 'A custom Linux build target.');
      expect(map[ExtensionBuildTarget.isTopLevelKey], isFalse);
      expect(map[ExtensionBuildTarget.dependenciesKey], equals(<String>['copy_assets']));
      expect(map[ExtensionBuildTarget.outputDirKey], '{PROJECT_DIR}/build/linux');

      final parsed = ExtensionBuildTarget.fromJson(map);
      expect(parsed, equals(target));
      expect(parsed.hashCode, equals(target.hashCode));
      expect(parsed.toString(), contains('custom-linux-build'));
    });

    test('deserializes with defaults when fields are missing', () {
      final parsed = ExtensionBuildTarget.fromJson(const <String, Object?>{});
      expect(parsed.name, isEmpty);
      expect(parsed.targetPlatform, isEmpty);
      expect(parsed.description, isEmpty);
      expect(parsed.isTopLevel, isTrue);
      expect(parsed.dependencies, isEmpty);
      expect(parsed.inputs, isEmpty);
      expect(parsed.outputs, isEmpty);
      expect(parsed.outputDir, kBuildDirPlaceholder);
    });

    test('listFromJson handles valid and invalid lists', () {
      final validJson = <String, Object?>{
        'name': 'custom-linux-build',
        'targetPlatform': 'linux-x64',
        'description': 'A custom Linux build target.',
      };

      final List<ExtensionBuildTarget> targets = ExtensionBuildTarget.listFromJson(<Object?>[
        validJson,
      ]);
      expect(targets, hasLength(1));
      expect(targets.first.name, 'custom-linux-build');
      expect(targets.first.targetPlatform, 'linux-x64');
      expect(targets.first.description, 'A custom Linux build target.');

      expect(ExtensionBuildTarget.listFromJson(null), isEmpty);
      expect(ExtensionBuildTarget.listFromJson('invalid'), isEmpty);
    });

    test('equality and hashCode distinguish different targets', () {
      const target1 = ExtensionBuildTarget(
        description: 'Target 1',
        name: 'target-1',
        targetPlatform: 'linux-x64',
      );
      const target2 = ExtensionBuildTarget(
        description: 'Target 2',
        name: 'target-2',
        targetPlatform: 'linux-x64',
      );

      expect(target1, isNot(equals(target2)));
      expect(target1.hashCode, isNot(equals(target2.hashCode)));
    });
  });

  group('ExtensionBuildResult', () {
    test('serializes and deserializes successful result without errorMessage', () {
      const result = ExtensionBuildResult.success();

      final Map<String, Object?> map = result.toMap();
      expect(map[ExtensionBuildResult.successKey], isTrue);
      expect(map.containsKey(ExtensionBuildResult.errorMessageKey), isFalse);

      final parsed = ExtensionBuildResult.fromJson(map);
      expect(parsed, equals(result));
      expect(parsed.hashCode, equals(result.hashCode));
      expect(parsed.toString(), contains('success: true'));
    });

    test('serializes and deserializes failed result with errorMessage', () {
      const result = ExtensionBuildResult.failure(message: 'Compilation failed.');

      final Map<String, Object?> map = result.toMap();
      expect(map[ExtensionBuildResult.successKey], isFalse);
      expect(map[ExtensionBuildResult.errorMessageKey], 'Compilation failed.');

      final parsed = ExtensionBuildResult.fromJson(map);
      expect(parsed, equals(result));
      expect(parsed.hashCode, equals(result.hashCode));
      expect(parsed.toString(), contains('Compilation failed.'));
    });

    test('equality and hashCode distinguish different results', () {
      const result1 = ExtensionBuildResult(success: true);
      const result2 = ExtensionBuildResult(success: false, errorMessage: 'Failed');

      expect(result1, isNot(equals(result2)));
      expect(result1.hashCode, isNot(equals(result2.hashCode)));
    });
  });
}
