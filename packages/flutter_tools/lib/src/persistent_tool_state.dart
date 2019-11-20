// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'base/config.dart';
import 'base/context.dart';
import 'base/file_system.dart';

PersistentToolState get persistentToolState => PersistentToolState.instance;

/// A class that represents global (non-project-specific) internal state that
/// must persist across tool invocations.
abstract class PersistentToolState {
  factory PersistentToolState([File configFile]) =>
    _DefaultPersistentToolState(configFile);

  static PersistentToolState get instance => context.get<PersistentToolState>();

  /// Whether the welcome message should be redisplayed.
  ///
  /// May give null if the value has not been set.
  bool redisplayWelcomeMessage;
}

class _DefaultPersistentToolState implements PersistentToolState {
  _DefaultPersistentToolState([File configFile]) :
    _config = Config(configFile ?? fs.file(fs.path.join(userHomePath(), _kFileName)));

  static const String _kFileName = '.flutter_tool_state';
  static const String _kRedisplayWelcomeMessage = 'redisplay-welcome-message';

  final Config _config;

  @override
  bool get redisplayWelcomeMessage => _config.getValue(_kRedisplayWelcomeMessage) as bool;

  @override
  set redisplayWelcomeMessage(bool value) {
    _config.setValue(_kRedisplayWelcomeMessage, value);
  }
}
