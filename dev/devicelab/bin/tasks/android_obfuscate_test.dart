// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/task_result.dart';

Future<void> main() async {
  // This test has moved to packages/flutter_tools/test/integration.shard/android_obfuscate_test.dart.
  // TODO(jmagman): Remove this file once the infra repo no longer contains "Linux_pixel_7pro android_obfuscate_test".
  // https://flutter.googlesource.com/infra/+/main/config/generated/ci_yaml/flutter_config.json
  await task(() async {
    return TaskResult.success(null);
  });
}
