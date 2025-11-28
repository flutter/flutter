// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/task_result.dart';

Future<void> main() async {
  // Empty so that version minimum can land before removal of java 11 tests ci config.
  await task(() async {
    return TaskResult.success(null);
  });
}
