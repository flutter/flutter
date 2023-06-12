// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:coverage/src/run_and_collect.dart';

Future<void> main(List<String> args) async {
  final Map results = await runAndCollect(args[0]);
  print(results);
}
