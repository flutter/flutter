// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:test_api/backend.dart'; // ignore: deprecated_member_use
import 'package:test_core/src/runner/platform.dart'; // ignore: implementation_imports
import 'package:test_core/src/executable.dart' as _test; // ignore: implementation_imports
import 'package:test_core/src/runner/hack_register_platform.dart' as _hack; // ignore: implementation_imports

import '../base/context.dart';

export 'package:test_api/backend.dart' show Runtime; // ignore: deprecated_member_use

Test get test => context.get<Test>() ?? const PackageTestTest();
Hack get hack => context.get<Hack>() ?? const PackageTestHack();

abstract class Hack {
  const Hack();

  void registerPlatformPlugin(Iterable<Runtime> runtimes, FutureOr<PlatformPlugin> Function() platforms);
}

abstract class Test {
  const Test();

  Future<void> main(List<String> args);
}

class PackageTestHack implements Hack {
  const PackageTestHack();

  @override
  void registerPlatformPlugin(Iterable<Runtime> runtimes, FutureOr<PlatformPlugin> Function() platforms) {
    _hack.registerPlatformPlugin(runtimes, platforms);
  }
}

class PackageTestTest implements Test {
  const PackageTestTest();

  @override
  Future<void> main(List<String> args) async {
    await _test.main(args);
  }
}
