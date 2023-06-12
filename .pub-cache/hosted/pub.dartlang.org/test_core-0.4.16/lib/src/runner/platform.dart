// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_api/src/backend/suite_platform.dart'; // ignore: implementation_imports

import 'environment.dart';
import 'runner_suite.dart';
import 'suite.dart';

/// A class that defines a platform for which test suites can be loaded.
///
/// A minimal plugin must define [loadChannel], which connects to a client in
/// which the tests are defined. This is enough to support most of the test
/// runner's functionality.
///
/// In order to support interactive debugging, a plugin must override [load] as
/// well, which returns a [RunnerSuite] that can contain a custom [Environment]
/// and control debugging metadata such as [RunnerSuite.isDebugging] and
/// [RunnerSuite.onDebugging]. The plugin must create this suite by calling the
/// [deserializeSuite] helper function.
///
/// A platform plugin can be registered by passing it to [Loader.new]'s
/// `plugins` parameter.
abstract class PlatformPlugin {
  /// Loads the runner suite for the test file at [path] using [platform], with
  /// [suiteConfig] encoding the suite-specific configuration.
  ///
  /// By default, this just calls [loadChannel] and passes its result to
  /// [deserializeSuite]. However, it can be overridden to provide more
  /// fine-grained control over the [RunnerSuite], including providing a custom
  /// implementation of [Environment].
  ///
  /// Subclasses overriding this method must call [deserializeSuite] in
  /// `platform_helpers.dart` to obtain a [RunnerSuiteController]. They must
  /// pass the opaque [message] parameter to the [deserializeSuite] call.
  Future<RunnerSuite?> load(String path, SuitePlatform platform,
      SuiteConfiguration suiteConfig, Map<String, Object?> message);

  Future closeEphemeral() async {}

  Future close() async {}
}
