// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/task_result.dart';

Future<void> main() async {
  await task(() async {
    // TODO(jmagman): Remove once gradle_non_android_plugin_test builder can be deleted
    // when https://github.com/flutter/flutter/pull/80161 rolls to stable.
    return TaskResult.success(null);
  });
}
