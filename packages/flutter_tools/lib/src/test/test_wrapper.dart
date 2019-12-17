// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:test_api/backend.dart'; // ignore: deprecated_member_use
import 'package:test_core/src/runner/platform.dart'; // ignore: implementation_imports
import 'package:test_core/src/executable.dart' as _test; // ignore: implementation_imports
import 'package:test_core/src/runner/hack_register_platform.dart' as _hack; // ignore: implementation_imports

import '../base/context.dart';

export 'package:test_api/backend.dart' show Runtime; // ignore: deprecated_member_use
export 'package:test_core/src/runner/platform.dart' show PlatformPlugin; // ignore: implementation_imports

TestWrapper get test => context.get<TestWrapper>() ?? const PackageTestTest();

abstract class TestWrapper {
  const TestWrapper();

  Future<void> main(List<String> args);
  void registerPlatformPlugin(Iterable<Runtime> runtimes, FutureOr<PlatformPlugin> Function() platforms);
}

class PackageTestTest implements TestWrapper {
  const PackageTestTest();

  @override
  Future<void> main(List<String> args) async {
    await _test.main(args);
  }

  @override
  void registerPlatformPlugin(Iterable<Runtime> runtimes, FutureOr<PlatformPlugin> Function() platforms) {
    _hack.registerPlatformPlugin(runtimes, platforms);
  }
}
