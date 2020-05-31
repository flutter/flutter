// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:dev_tools/src/update_packages.dart';

Future<void> main(List<String> args) async {
  final CommandRunner<void> commandRunner = CommandRunner<void>('repo_tools', 'tools for development on Flutter');
  commandRunner.addCommand(UpdatePackagesCommand());
  await commandRunner.run(args);
}
