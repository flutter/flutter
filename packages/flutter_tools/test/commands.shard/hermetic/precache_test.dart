// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/precache.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';

void main() {
  group('precache', () {
    final MockCache cache = MockCache();
    Set<DevelopmentArtifact> artifacts;

    when(cache.isUpToDate()).thenReturn(false);
    when(cache.updateAll(any)).thenAnswer((Invocation invocation) {
      artifacts = invocation.positionalArguments.first;
      return Future<void>.value(null);
    });

    testUsingContext('Adds artifact flags to requested artifacts', () async {
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
    });

    testUsingContext('Expands android artifacts when the android flag is used', () async {
      // Release lock between test cases.
      Cache.releaseLockEarly();

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

    testUsingContext('Adds artifact flags to requested android artifacts', () async {
      // Release lock between test cases.
      Cache.releaseLockEarly();

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

    final MockFlutterVersion flutterVersion = MockFlutterVersion();
    when(flutterVersion.isMaster).thenReturn(false);

    testUsingContext('Adds artifact flags to requested artifacts on stable', () async {
      // Release lock between test cases.
      Cache.releaseLockEarly();
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
    });
    testUsingContext('Downloads artifacts when --force is provided', () async {
      when(cache.isUpToDate()).thenReturn(true);
      // Release lock between test cases.
      Cache.releaseLockEarly();
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
  });
}

class MockFlutterVersion extends Mock implements FlutterVersion {}
class MockCache extends Mock implements Cache {}
