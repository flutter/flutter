// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_devicelab/framework/framework.dart';

/// Smoke test of a task that fails with an exception.
Future<void> main() async {
  await task(() async {
    throw 'failed';
  });
}
