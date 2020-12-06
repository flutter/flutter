// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'base/config.dart';
import 'base/context.dart';
import 'base/file_system.dart';
import 'base/logger.dart';
import 'base/platform.dart';
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
  String lastActiveVersion(Channel channel);

  /// Update the last active version for a given [channel].
  void updateLastActiveVersion(String fullGitHash, Channel channel);

  /// Whether this client was already determined to be or not be a bot.
  bool isRunningOnBot;
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
  static const Map<Channel, String> _lastActiveVersionKeys = <Channel,String>{
    Channel.master: 'last-active-master-version',
    Channel.dev: 'last-active-dev-version',
    Channel.beta: 'last-active-beta-version',
    Channel.stable: 'last-active-stable-version'
  };
  static const String _kBotKey = 'is-bot';

  final Config _config;

  @override
  bool get redisplayWelcomeMessage {
    return _config.getValue(_kRedisplayWelcomeMessage) as bool;
  }

  @override
  String lastActiveVersion(Channel channel) {
    final String versionKey = _versionKeyFor(channel);
    assert(versionKey != null);
    return _config.getValue(versionKey) as String;
  }

  @override
  set redisplayWelcomeMessage(bool value) {
    _config.setValue(_kRedisplayWelcomeMessage, value);
  }

  @override
  void updateLastActiveVersion(String fullGitHash, Channel channel) {
    final String versionKey = _versionKeyFor(channel);
    assert(versionKey != null);
    _config.setValue(versionKey, fullGitHash);
  }

  String _versionKeyFor(Channel channel) {
    return _lastActiveVersionKeys[channel];
  }

  @override
  bool get isRunningOnBot => _config.getValue(_kBotKey) as bool;

  @override
  set isRunningOnBot(bool value) => _config.setValue(_kBotKey, value);
}
