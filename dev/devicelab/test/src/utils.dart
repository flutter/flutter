// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart' show ListEquality, MapEquality;
import 'package:meta/meta.dart';

CommandArgs cmd({
  String command,
  List<String> arguments,
  Map<String, String> environment,
}) {
  return CommandArgs(
    command: command,
    arguments: arguments,
    environment: environment,
  );
}

typedef ExitErrorFactory = dynamic Function();

@immutable
class CommandArgs {
  const CommandArgs({ this.command, this.arguments, this.environment });

  final String command;
  final List<String> arguments;
  final Map<String, String> environment;

  @override
  String toString() => 'CommandArgs(command: $command, arguments: $arguments, environment: $environment)';

  @override
  bool operator==(Object other) {
    if (other.runtimeType != CommandArgs)
      return false;
    return other is CommandArgs
        && other.command == command
        && const ListEquality<String>().equals(other.arguments, arguments)
        && const MapEquality<String, String>().equals(other.environment, environment);
  }

  @override
  int get hashCode => 17 * (17 * command.hashCode + _hashArguments) + _hashEnvironment;

  int get _hashArguments => arguments != null
    ? const ListEquality<String>().hash(arguments)
    : null.hashCode;

  int get _hashEnvironment => environment != null
    ? const MapEquality<String, String>().hash(environment)
    : null.hashCode;
}
