// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

Future<void> main() async {
  print('>>> Release: $kReleaseMode <<<');
  print('>>> FINISHED <<<');
  stdout.flush();
  runApp(const Text('Hello, world!', textDirection: TextDirection.ltr));
}
