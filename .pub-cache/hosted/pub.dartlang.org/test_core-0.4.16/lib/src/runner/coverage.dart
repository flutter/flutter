// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'live_suite_controller.dart';

/// Collects coverage and outputs to the [coveragePath] path.
Future<void> writeCoverage(
    String coveragePath, LiveSuiteController controller) async {
  var suite = controller.liveSuite.suite;
  var coverage = await controller.liveSuite.suite.gatherCoverage();
  final outfile = File(p.join(coveragePath,
      '${suite.path}.${suite.platform.runtime.name.toLowerCase()}.json'))
    ..createSync(recursive: true);
  final out = outfile.openWrite();
  out.write(json.encode(coverage));
  await out.flush();
  await out.close();
}
