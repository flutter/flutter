// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io" show Platform;

import 'package:analyzer_utilities/tools.dart';
import 'package:path/path.dart';

import 'generate.dart';

/// Check that all targets have been code generated.  If they haven't tell the
/// user to run `generate.dart`.
main() async {
  String script = Platform.script.toFilePath(windows: Platform.isWindows);
  List<String> components = split(script);
  int index = components.indexOf('analyzer');
  String pkgPath = joinAll(components.sublist(0, index + 1));
  await GeneratedContent.checkAll(pkgPath,
      join(pkgPath, 'tool', 'experiments', 'generate.dart'), allTargets);
}
