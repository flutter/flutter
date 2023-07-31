// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:test_api/src/backend/runtime.dart'; // ignore: implementation_imports
import 'platform.dart';

/// The functions to use to load [_platformPlugins] in all loaders.
///
/// **Do not access this outside the test package**.
final platformCallbacks =
    UnmodifiableMapView<Runtime, FutureOr<PlatformPlugin> Function()>(
        _platformCallbacks);
final _platformCallbacks = <Runtime, FutureOr<PlatformPlugin> Function()>{};

/// **Do not call this function without express permission from the test package
/// authors**.
///
/// Registers a [PlatformPlugin] for [runtimes].
///
/// This globally registers a plugin for all [Loader]s. When the runner first
/// requests that a suite be loaded for one of the given runtimes, this will
/// call [plugin] to load the platform plugin. It may return either a
/// [PlatformPlugin] or a [Future<PlatformPlugin>]. That plugin is then
/// preserved and used to load all suites for all matching runtimes.
///
/// This overwrites the default plugins for those runtimes.
void registerPlatformPlugin(
    Iterable<Runtime> runtimes, FutureOr<PlatformPlugin> Function() plugin) {
  for (var runtime in runtimes) {
    _platformCallbacks[runtime] = plugin;
  }
}
