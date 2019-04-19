// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/fuchsia/fuchsia_workflow.dart';
import 'package:mockito/mockito.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  group('Fuchsia workflow', () {
    final MockPlatform linux = MockPlatform();
    final MockCache cacheWithFuchsia = MockCache();
    final MockCache cacheWithoutFuchsia = MockCache();
    final MockDirectory fuchsiaArtifacts = MockDirectory();
    final MockDirectory missingFuchsiaArtifacts = MockDirectory();
    when(cacheWithFuchsia.getArtifactDirectory('fuchsia')).thenReturn(fuchsiaArtifacts);
    when(cacheWithoutFuchsia.getArtifactDirectory('fuchsia')).thenReturn(missingFuchsiaArtifacts);
    when(fuchsiaArtifacts.existsSync()).thenReturn(true);
    when(missingFuchsiaArtifacts.existsSync()).thenReturn(false);
    when(linux.isLinux).thenReturn(true);

    testUsingContext('can not list and launch devices if the fuchsia artifacts are not cached', () {
      expect(fuchsiaWorkflow.canLaunchDevices, false);
      expect(fuchsiaWorkflow.canListDevices, false);
      expect(fuchsiaWorkflow.canListEmulators, false);
    }, overrides: <Type, Generator>{
      Cache: () => cacheWithoutFuchsia,
      Platform: () => linux,
    });

    testUsingContext('can list and launch devices if the fuchsia artifacts are cached', () {
      expect(fuchsiaWorkflow.canLaunchDevices, true);
      expect(fuchsiaWorkflow.canListDevices, true);
      expect(fuchsiaWorkflow.canListEmulators, false);
    }, overrides: <Type, Generator>{
      Cache: () => cacheWithFuchsia,
      Platform: () => linux,
    });
  });
}

class MockCache extends Mock implements Cache {}
class MockDirectory extends Mock implements Directory {}
class MockPlatform extends Mock implements Platform {}