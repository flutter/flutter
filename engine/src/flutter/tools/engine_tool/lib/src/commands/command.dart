// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';

import '../environment.dart';

/// The base class that all commands and subcommands should inherit from.
abstract base class CommandBase extends Command<int> {
  /// Constructs the base command.
  CommandBase({
    required this.environment
  });

  /// The host system environment.
  final Environment environment;
}
