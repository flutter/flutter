// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:dev_tools/update_packages.dart';

void main(List<String> args) {
  CommandRunner<void>('update-packages', 'upgrade packages')
    ..addCommand(UpdatePackagesCommand())
    ..run(args);
}
