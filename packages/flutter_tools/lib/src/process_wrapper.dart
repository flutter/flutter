// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library sky_tools.process_wrapper;

import 'dart:io';
import 'package:logging/logging.dart';

final Logger _logging = new Logger('sky_tools.process_wrapper');
String runCheckedSync(List<String> cmd) {
  _logging.info(cmd.join(' '));
  ProcessResult results =
      Process.runSync(cmd[0], cmd.getRange(1, cmd.length).toList());
  if (results.exitCode != 0) {
    throw 'Error code ' +
        results.exitCode.toString() +
        ' returned when attempting to run command: ' +
        cmd.join(' ');
  }
  return results.stdout;
}
