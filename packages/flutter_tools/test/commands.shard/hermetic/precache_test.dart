// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/precache.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';
import '../../src/testbed.dart';

void main() {
  MockCache cache;
  Set<DevelopmentArtifact> artifacts;
  MockFlutterVersion flutterVersion;
  MockFlutterVersion masterFlutterVersion;

  setUp(() {
    cache = MockCache();
    // Release lock between test cases.
    Cache.releaseLockEarly();

    when(cache.isUpToDate()).thenReturn(false);
    when(cache.updateAll(any)).thenAnswer((Invocation invocation) {
      artifacts = invocation.positionalArguments.first as Set<DevelopmentArtifact>;
      return Future<void>.value(null);
    });
    flutterVersion = MockFlutterVersion();
    when(flutterVersion.isMaster).thenReturn(false);
    masterFlutterVersion = MockFlutterVersion();
    when(masterFlutterVersion.isMaster).thenReturn(true);
  });

  testUsingContext('precache downloads web artifacts on dev branch when feature is enabled.', () async {
    final PrecacheCommand command = PrecacheCommand();
    applyMocksToCommand(command);
    await createTestCommandRunner(command).run(const <String>['precache', '--web', '--no-android', '--no-ios']);

    expect(artifacts, unorderedEquals(<DevelopmentArtifact>{
      DevelopmentArtifact.universal,
      DevelopmentArtifact.web,
    }));
  }, overrides: <Type, Generator>{
    Cache: () => cache,
    FeatureFlags: () => TestFeatureFlags(isWebEnabled: true),
  });

  testUsingContext('precache does not download web artifacts on dev branch when feature is enabled.', () async {
    final PrecacheCommand command = PrecacheCommand();
    applyMocksToCommand(command);
    await createTestCommandRunner(command).run(const <String>['precache', '--web', '--no-android', '--no-ios']);

    expect(artifacts, unorderedEquals(<DevelopmentArtifact>{
      DevelopmentArtifact.universal,
    }));
  }, overrides: <Type, Generator>{
    Cache: () => cache,
    FeatureFlags: () => TestFeatureFlags(isWebEnabled: false),
  });

  testUsingContext('precache exits if requesting mismatched artifacts.', () async {
    final PrecacheCommand command = PrecacheCommand();
    applyMocksToCommand(command);

    expect(createTestCommandRunner(command).run(const <String>['precache',
      '--no-android',
      '--android_gen_snapshot',
    ]), throwsToolExit(message: '--android_gen_snapshot requires --android'));
  }, overrides: <Type, Generator>{
    Cache: () => cache,
    FeatureFlags: () => TestFeatureFlags(isWebEnabled: false),
  });

  testUsingContext('precache adds artifact flags to requested artifacts', () async {
    final PrecacheCommand command = PrecacheCommand();
    applyMocksToCommand(command);
    await createTestCommandRunner(command).run(
      const <String>[
        'precache',
        '--ios',
        '--android',
        '--web',
        '--macos',
        '--linux',
        '--windows',
        '--fuchsia',
        '--flutter_runner',
      ],
    );
    expect(artifacts, unorderedEquals(<DevelopmentArtifact>{
      DevelopmentArtifact.universal,
      DevelopmentArtifact.iOS,
      DevelopmentArtifact.androidGenSnapshot,
      DevelopmentArtifact.androidMaven,
      DevelopmentArtifact.androidInternalBuild,
      DevelopmentArtifact.web,
      DevelopmentArtifact.macOS,
      DevelopmentArtifact.linux,
      DevelopmentArtifact.windows,
      DevelopmentArtifact.fuchsia,
      DevelopmentArtifact.flutterRunner,
    }));
  }, overrides: <Type, Generator>{
    Cache: () => cache,
    FeatureFlags: () => TestFeatureFlags(isWebEnabled: true),
    FlutterVersion: () => masterFlutterVersion,
  });

  testUsingContext('precache expands android artifacts when the android flag is used', () async {
    final PrecacheCommand command = PrecacheCommand();
    applyMocksToCommand(command);
    await createTestCommandRunner(command).run(
      const <String>[
        'precache',
        '--no-ios',
        '--android',
      ],
    );
    expect(artifacts, unorderedEquals(<DevelopmentArtifact>{
      DevelopmentArtifact.universal,
      DevelopmentArtifact.androidGenSnapshot,
      DevelopmentArtifact.androidMaven,
      DevelopmentArtifact.androidInternalBuild,
    }));
  }, overrides: <Type, Generator>{
    Cache: () => cache,
  });

  testUsingContext('precache adds artifact flags to requested android artifacts', () async {
    final PrecacheCommand command = PrecacheCommand();
    applyMocksToCommand(command);
    await createTestCommandRunner(command).run(
      const <String>[
        'precache',
        '--no-ios',
        '--android_gen_snapshot',
        '--android_maven',
        '--android_internal_build',
      ],
    );
    expect(artifacts, unorderedEquals(<DevelopmentArtifact>{
      DevelopmentArtifact.universal,
      DevelopmentArtifact.androidGenSnapshot,
      DevelopmentArtifact.androidMaven,
      DevelopmentArtifact.androidInternalBuild,
    }));
  }, overrides: <Type, Generator>{
    Cache: () => cache,
  });

  testUsingContext('precache adds artifact flags to requested artifacts on stable', () async {
    final PrecacheCommand command = PrecacheCommand();
    applyMocksToCommand(command);
    await createTestCommandRunner(command).run(
      const <String>[
        'precache',
        '--ios',
        '--android_gen_snapshot',
        '--android_maven',
        '--android_internal_build',
        '--web',
        '--macos',
        '--linux',
        '--windows',
        '--fuchsia',
        '--flutter_runner',
      ],
    );
    expect(artifacts, unorderedEquals(<DevelopmentArtifact>{
      DevelopmentArtifact.universal,
      DevelopmentArtifact.iOS,
      DevelopmentArtifact.androidGenSnapshot,
      DevelopmentArtifact.androidMaven,
      DevelopmentArtifact.androidInternalBuild,
    }));
  }, overrides: <Type, Generator>{
    Cache: () => cache,
    FlutterVersion: () => flutterVersion,
    FeatureFlags: () => TestFeatureFlags(isWebEnabled: false),
  });

  testUsingContext('precache downloads artifacts when --force is provided', () async {
    when(cache.isUpToDate()).thenReturn(true);
    final PrecacheCommand command = PrecacheCommand();
    applyMocksToCommand(command);
    await createTestCommandRunner(command).run(const <String>['precache', '--force']);
    expect(artifacts, unorderedEquals(<DevelopmentArtifact>{
      DevelopmentArtifact.universal,
      DevelopmentArtifact.iOS,
      DevelopmentArtifact.androidGenSnapshot,
      DevelopmentArtifact.androidMaven,
      DevelopmentArtifact.androidInternalBuild,
    }));
  }, overrides: <Type, Generator>{
    Cache: () => cache,
    FlutterVersion: () => flutterVersion,
  });
}

class MockFlutterVersion extends Mock implements FlutterVersion {}
class MockCache extends Mock implements Cache {}
