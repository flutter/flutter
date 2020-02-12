// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:platform/platform.dart';

import 'base/config.dart';
import 'base/context.dart';
import 'base/file_system.dart';
import 'base/logger.dart';

/// A class that represents global (non-project-specific) internal state that
/// must persist across tool invocations.
abstract class PersistentToolState {
  factory PersistentToolState({
    @required FileSystem fileSystem,
    @required Logger logger,
    @required Platform platform,
  }) => _DefaultPersistentToolState(
    fileSystem: fileSystem,
    logger: logger,
    platform: platform,
  );

  factory PersistentToolState.test({
    @required Directory directory,
    @required Logger logger,
  }) => _DefaultPersistentToolState.test(
    directory: directory,
    logger: logger,
  );

  static PersistentToolState get instance => context.get<PersistentToolState>();

  /// Whether the welcome message should be redisplayed.
  ///
  /// May give null if the value has not been set.
  bool redisplayWelcomeMessage;
}

class _DefaultPersistentToolState implements PersistentToolState {
  _DefaultPersistentToolState({
    @required FileSystem fileSystem,
    @required Logger logger,
    @required Platform platform,
  }) : _config = Config(
      _kFileName,
      fileSystem: fileSystem,
      logger: logger,
      platform: platform,
    );

  @visibleForTesting
  _DefaultPersistentToolState.test({
    @required Directory directory,
    @required Logger logger,
  }) : _config = Config.test(
      _kFileName,
      directory: directory,
      logger: logger,
    );

  static const String _kFileName = '.flutter_tool_state';
  static const String _kRedisplayWelcomeMessage = 'redisplay-welcome-message';

  final Config _config;

  @override
  bool get redisplayWelcomeMessage {
    return _config.getValue(_kRedisplayWelcomeMessage) as bool;
  }

  @override
  set redisplayWelcomeMessage(bool value) {
    _config.setValue(_kRedisplayWelcomeMessage, value);
  }
}
