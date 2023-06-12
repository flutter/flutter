// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_runner_core/build_runner_core.dart';
import 'package:logging/logging.dart';

import 'package:build_runner_core/src/environment/io_environment.dart';

void main() async {
  var env = IOEnvironment(await PackageGraph.forThisPackage(), assumeTty: true);
  var result = await env.prompt('Select an option!', ['a', 'b', 'c']);
  Logger.root.onRecord.listen(env.onLog);
  Logger('Simple Logger').info(result);
}
