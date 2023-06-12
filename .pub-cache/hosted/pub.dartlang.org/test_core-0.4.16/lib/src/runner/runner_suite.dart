// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:async/async.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test_api/src/backend/group.dart'; // ignore: implementation_imports
import 'package:test_api/src/backend/suite.dart'; // ignore: implementation_imports
import 'package:test_api/src/backend/suite_platform.dart'; // ignore: implementation_imports
import 'package:test_api/src/backend/test.dart'; // ignore: implementation_imports

import 'environment.dart';
import 'suite.dart';

/// A suite produced and consumed by the test runner that has runner-specific
/// logic and lifecycle management.
///
/// This is separated from [Suite] because the backend library (which will
/// eventually become its own package) is primarily for test code itself to use,
/// for which the [RunnerSuite] APIs don't make sense.
///
/// A [RunnerSuite] can be produced and controlled using a
/// [RunnerSuiteController].
class RunnerSuite extends Suite {
  final RunnerSuiteController _controller;

  /// The environment in which this suite runs.
  Environment get environment => _controller._environment;

  /// The configuration for this suite.
  SuiteConfiguration get config => _controller._config;

  /// Whether the suite is paused for debugging.
  ///
  /// When using a dev inspector, this may also mean that the entire browser is
  /// paused.
  bool get isDebugging => _controller._isDebugging;

  /// A broadcast stream that emits an event whenever the suite is paused for
  /// debugging or resumed afterwards.
  ///
  /// The event is `true` when debugging starts and `false` when it ends.
  Stream<bool> get onDebugging => _controller._onDebuggingController.stream;

  /// A shortcut constructor for creating a [RunnerSuite] that never goes into
  /// debugging mode and doesn't support suite channels.
  factory RunnerSuite(Environment environment, SuiteConfiguration config,
      Group group, SuitePlatform platform,
      {String? path, Function()? onClose}) {
    var controller =
        RunnerSuiteController._local(environment, config, onClose: onClose);
    var suite = RunnerSuite._(controller, group, platform, path: path);
    controller._suite = Future.value(suite);
    return suite;
  }

  RunnerSuite._(this._controller, Group group, SuitePlatform platform,
      {String? path})
      : super(group, platform,
            path: path, ignoreTimeouts: _controller._config.ignoreTimeouts);

  @override
  RunnerSuite filter(bool Function(Test) callback) {
    var filtered = group.filter(callback);
    filtered ??= Group.root([], metadata: metadata);
    return RunnerSuite._(_controller, filtered, platform, path: path);
  }

  /// Closes the suite and releases any resources associated with it.
  Future close() => _controller._close();

  /// Collects a hit-map containing merged coverage.
  ///
  /// Result is suitable for input to the coverage formatters provided by
  /// `package:coverage`.
  Future<Map<String, dynamic>> gatherCoverage() async =>
      (await _controller._gatherCoverage?.call()) ?? {};
}

/// A class that exposes and controls a [RunnerSuite].
class RunnerSuiteController {
  /// The suite controlled by this controller.
  Future<RunnerSuite> get suite => _suite;
  late final Future<RunnerSuite> _suite;

  /// The backing value for [suite.environment].
  final Environment _environment;

  /// The configuration for this suite.
  final SuiteConfiguration _config;

  /// A channel that communicates with the remote suite.
  final MultiChannel? _suiteChannel;

  /// The function to call when the suite is closed.
  final Function()? _onClose;

  /// The backing value for [suite.isDebugging].
  bool _isDebugging = false;

  /// The controller for [suite.onDebugging].
  final _onDebuggingController = StreamController<bool>.broadcast();

  /// The channel names that have already been used.
  final _channelNames = <String>{};

  /// Collects a hit-map containing merged coverage.
  final Future<Map<String, dynamic>> Function()? _gatherCoverage;

  RunnerSuiteController(this._environment, this._config, this._suiteChannel,
      Future<Group> groupFuture, SuitePlatform platform,
      {String? path,
      Function()? onClose,
      Future<Map<String, dynamic>> Function()? gatherCoverage})
      : _onClose = onClose,
        _gatherCoverage = gatherCoverage {
    _suite = groupFuture
        .then((group) => RunnerSuite._(this, group, platform, path: path));
  }

  /// Used by [RunnerSuite.new] to create a runner suite that's not loaded from
  /// an external source.
  RunnerSuiteController._local(this._environment, this._config,
      {Function()? onClose,
      Future<Map<String, dynamic>> Function()? gatherCoverage})
      : _suiteChannel = null,
        _onClose = onClose,
        _gatherCoverage = gatherCoverage;

  /// Sets whether the suite is paused for debugging.
  ///
  /// If this is different than [suite.isDebugging], this will automatically
  /// send out an event along [suite.onDebugging].
  void setDebugging(bool debugging) {
    if (debugging == _isDebugging) return;
    _isDebugging = debugging;
    _onDebuggingController.add(debugging);
  }

  /// Returns a channel that communicates with the remote suite.
  ///
  /// This connects to a channel created by code in the test worker calling the
  /// `suiteChannel` argument from a `beforeLoad` callback to `serializeSuite`
  /// with the same name.
  /// It can be used used to send and receive any JSON-serializable object.
  ///
  /// This is exposed on the [RunnerSuiteController] so that runner plugins can
  /// communicate with the workers they spawn before the associated [suite] is
  /// fully loaded.
  StreamChannel channel(String name) {
    if (!_channelNames.add(name)) {
      throw StateError('Duplicate RunnerSuite.channel() connection "$name".');
    }

    var suiteChannel = _suiteChannel;
    if (suiteChannel == null) {
      throw StateError('No suite channel set up but one was requested.');
    }

    var channel = suiteChannel.virtualChannel();
    suiteChannel.sink
        .add({'type': 'suiteChannel', 'name': name, 'id': channel.id});
    return channel;
  }

  /// The backing function for [suite.close].
  Future _close() => _closeMemo.runOnce(() async {
        await _onDebuggingController.close();
        var onClose = _onClose;
        if (onClose != null) await onClose();
      });
  final _closeMemo = AsyncMemoizer();
}
