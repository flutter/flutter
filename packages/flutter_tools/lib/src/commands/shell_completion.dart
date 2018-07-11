// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:completion/completion.dart';
import '../runner/flutter_command.dart';

class ShellCompletionCommand extends FlutterCommand {
  ShellCompletionCommand({ bool verboseHelp = false });

  @override
  final String name = 'bash-completion';

  @override
  final String description =
    'Output command line shell completion setup scripts.\n\n'
    'This command prints the flutter command line completion script for Bash and Zsh. To use it,\n'
    'redirect the output into a file and follow the instructions in the output to install it in\n'
    'your shell environment. Once added, your shell will be able to complete flutter commands and\n'
    'options.\n\n'
    'The Flutter tool anonymously reports feature usage statistics and basic crash reports to help improve\n'
    'Flutter tools over time. See Google\'s privacy policy: https://www.google.com/intl/en/policies/privacy/';

  @override
  final List<String> aliases = <String>['zsh-completion'];

  @override
  bool get shouldUpdateCache => false;

  /// Return null to disable tracking of the `bash-completion` command.
  @override
  Future<String> get usagePath => null;

  @override
  Future<Null> runCommand() async {
    print(generateCompletionScript(<String>['flutter']));
  }
}
