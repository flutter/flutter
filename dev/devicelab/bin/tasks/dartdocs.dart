// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/task_result.dart';

Future<void> main() async {
  await task(() async {
    // TODO(jmagman): Remove once dartdocs builder can be deleted
    // when https://github.com/flutter/flutter/issues/79798 rolls to stable.
    return TaskResult.success(null);
  });
}
