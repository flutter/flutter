// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/platform.dart';
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
    Cache.releaseLock();

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

  testUsingContext('precache should acquire lock', () async {
    final PrecacheCommand command = PrecacheCommand();
    applyMocksToCommand(command);
    await createTestCommandRunner(command).run(const <String>['precache']);

    expect(Cache.isLocked(), isTrue);
    // Do not throw StateError, lock is acquired.
    Cache.checkLockAcquired();
  }, overrides: <Type, Generator>{
    Cache: () => cache,
  });

  testUsingContext('precache should not re-entrantly acquire lock', () async {
    final PrecacheCommand command = PrecacheCommand();
    applyMocksToCommand(command);
    await createTestCommandRunner(command).run(const <String>['precache']);

    expect(Cache.isLocked(), isFalse);
    // Do not throw StateError, acquired reentrantly with FLUTTER_ALREADY_LOCKED.
    Cache.checkLockAcquired();
  }, overrides: <Type, Generator>{
    Cache: () => cache,
    Platform: () => FakePlatform(
      operatingSystem: 'windows',
      environment: <String, String>{
        'FLUTTER_ROOT': 'flutter',
        'FLUTTER_ALREADY_LOCKED': 'true',
      },
    ),
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

  testUsingContext('precache downloads macOS artifacts on dev branch when macOS is enabled.', () async {
    final PrecacheCommand command = PrecacheCommand();
    applyMocksToCommand(command);
    await createTestCommandRunner(command).run(const <String>['precache', '--macos', '--no-android', '--no-ios']);

    expect(artifacts, unorderedEquals(<DevelopmentArtifact>{
      DevelopmentArtifact.universal,
      DevelopmentArtifact.macOS,
    }));
  }, overrides: <Type, Generator>{
    Cache: () => cache,
    FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: true),
  });

  testUsingContext('precache does not download macOS artifacts on dev branch when feature is enabled.', () async {
    final PrecacheCommand command = PrecacheCommand();
    applyMocksToCommand(command);
    await createTestCommandRunner(command).run(const <String>['precache', '--macos', '--no-android', '--no-ios']);

    expect(artifacts, unorderedEquals(<DevelopmentArtifact>{
      DevelopmentArtifact.universal,
    }));
  }, overrides: <Type, Generator>{
    Cache: () => cache,
    FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: false),
  });

  testUsingContext('precache downloads Windows artifacts on dev branch when feature is enabled.', () async {
    final PrecacheCommand command = PrecacheCommand();
    applyMocksToCommand(command);
    await createTestCommandRunner(command).run(const <String>['precache', '--windows', '--no-android', '--no-ios']);

    expect(artifacts, unorderedEquals(<DevelopmentArtifact>{
      DevelopmentArtifact.universal,
      DevelopmentArtifact.windows,
    }));
  }, overrides: <Type, Generator>{
    Cache: () => cache,
    FeatureFlags: () => TestFeatureFlags(isWindowsEnabled: true),
  });

  testUsingContext('precache does not download Windows artifacts on dev branch when feature is enabled.', () async {
    final PrecacheCommand command = PrecacheCommand();
    applyMocksToCommand(command);
    await createTestCommandRunner(command).run(const <String>['precache', '--windows', '--no-android', '--no-ios']);

    expect(artifacts, unorderedEquals(<DevelopmentArtifact>{
      DevelopmentArtifact.universal,
    }));
  }, overrides: <Type, Generator>{
    Cache: () => cache,
    FeatureFlags: () => TestFeatureFlags(isWindowsEnabled: false),
  });

  testUsingContext('precache downloads Linux artifacts on dev branch when feature is enabled.', () async {
    final PrecacheCommand command = PrecacheCommand();
    applyMocksToCommand(command);
    await createTestCommandRunner(command).run(const <String>['precache', '--linux', '--no-android', '--no-ios']);

    expect(artifacts, unorderedEquals(<DevelopmentArtifact>{
      DevelopmentArtifact.universal,
      DevelopmentArtifact.linux,
    }));
  }, overrides: <Type, Generator>{
    Cache: () => cache,
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: true),
  });

  testUsingContext('precache does not download Linux artifacts on dev branch when feature is enabled.', () async {
    final PrecacheCommand command = PrecacheCommand();
    applyMocksToCommand(command);
    await createTestCommandRunner(command).run(const <String>['precache', '--linux', '--no-android', '--no-ios']);

    expect(artifacts, unorderedEquals(<DevelopmentArtifact>{
      DevelopmentArtifact.universal,
    }));
  }, overrides: <Type, Generator>{
    Cache: () => cache,
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: false),
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
    FeatureFlags: () => TestFeatureFlags(
      isWebEnabled: true,
      isLinuxEnabled: true,
      isMacOSEnabled: true,
      isWindowsEnabled: true,
    ),
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

  testUsingContext('precache downloads iOS and Android artifacts by default', () async {
    final PrecacheCommand command = PrecacheCommand();
    applyMocksToCommand(command);

    await createTestCommandRunner(command).run(
      const <String>[
        'precache',
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
  });

  testUsingContext('precache --all-platforms gets all artifacts', () async {
    final PrecacheCommand command = PrecacheCommand();
    applyMocksToCommand(command);

    await createTestCommandRunner(command).run(
      const <String>[
        'precache',
        '--all-platforms',
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
    FeatureFlags: () => TestFeatureFlags(
      isWebEnabled: true,
      isLinuxEnabled: true,
      isMacOSEnabled: true,
      isWindowsEnabled: true,
    ),
    FlutterVersion: () => masterFlutterVersion,
  });

  testUsingContext('precache with default artifacts does not override platform filtering', () async {
    final PrecacheCommand command = PrecacheCommand();
    applyMocksToCommand(command);

    await createTestCommandRunner(command).run(
      const <String>[
        'precache',
      ],
    );

    verify(cache.platformOverrideArtifacts = <String>{});
  }, overrides: <Type, Generator>{
    Cache: () => cache,
    FlutterVersion: () => masterFlutterVersion,
  });

  testUsingContext('precache with explicit artifact options overrides platform filtering', () async {
    final PrecacheCommand command = PrecacheCommand();
    applyMocksToCommand(command);

    await createTestCommandRunner(command).run(
      const <String>[
        'precache',
        '--no-ios',
        '--no-android',
        '--macos',
      ],
    );

    expect(artifacts, unorderedEquals(<DevelopmentArtifact>{
      DevelopmentArtifact.universal,
      DevelopmentArtifact.macOS,
    }));
    verify(cache.platformOverrideArtifacts = <String>{'macos'});
  }, overrides: <Type, Generator>{
    Cache: () => cache,
    FlutterVersion: () => masterFlutterVersion,
    FeatureFlags: () => TestFeatureFlags(
      isMacOSEnabled: true,
    ),
    Platform: () => FakePlatform(
      operatingSystem: 'windows',
      environment: <String, String>{
        'FLUTTER_ROOT': 'flutter',
        'FLUTTER_ALREADY_LOCKED': 'true',
      },
    ),
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
    FeatureFlags: () => TestFeatureFlags(
      isMacOSEnabled: true,
    ),
  });
}

class MockFlutterVersion extends Mock implements FlutterVersion {}
class MockCache extends Mock implements Cache {}
