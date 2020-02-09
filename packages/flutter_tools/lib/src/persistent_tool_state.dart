// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:platform/platform.dart';

import 'base/config.dart';
import 'base/context.dart';
import 'base/file_system.dart';
import 'base/logger.dart';
import 'version.dart';

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

  /// Returns the last active version for a given [channel].
  ///
  /// If there was no active prior version, returns `null` instead.
  GitTagVersion lastActiveVersion(Channel channel);
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

  static const String _kLastActiveMasterChannel = 'last-active-master-version';
  static const String _kLastActiveDevVersion = 'last-active-dev-version';
  static const String _kLastActiveBetaChannel = 'last-active-beta-version';
  static const String _kLastActiveStableChannel = 'last-active-stable-version';

  final Config _config;

  @override
  bool get redisplayWelcomeMessage {
    return _config.getValue(_kRedisplayWelcomeMessage) as bool;
  }

  @override
  GitTagVersion lastActiveVersion(Channel channel) {
    String versionKey;
    switch (channel) {
      case Channel.master:
        versionKey = _kLastActiveMasterChannel;
        break;
      case Channel.dev:
        versionKey = _kLastActiveDevVersion;
        break;
      case Channel.beta:
        versionKey = _kLastActiveBetaChannel;
        break;
      case Channel.stable:
        versionKey = _kLastActiveStableChannel;
        break;
    }
    assert(versionKey != null);
    final String rawValue = _config.getValue(versionKey) as String;
    if (rawValue == null) {
      return null;
    }
    // Note: if Version.parse fails it will also return null.
    return GitTagVersion.parse(rawValue);
  }

  @override
  set redisplayWelcomeMessage(bool value) {
    _config.setValue(_kRedisplayWelcomeMessage, value);
  }
}
