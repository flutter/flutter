// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';

Future<void> main() async {
  final FileSystem fs = MemoryFileSystem();
  final Directory tmp = await fs.systemTempDirectory.createTemp('example_');
  final File outputFile = tmp.childFile('output');
  await outputFile.writeAsString('Hello world!');
  print(outputFile.readAsStringSync());
}
