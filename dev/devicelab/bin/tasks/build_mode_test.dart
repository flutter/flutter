// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/task_result.dart';

const String buildMode = String.fromEnvironment('buildMode');

Future<void> main() async {
  await task(() async {
    print('buildMode: $buildMode');
    return TaskResult.success(null);
  });
}
