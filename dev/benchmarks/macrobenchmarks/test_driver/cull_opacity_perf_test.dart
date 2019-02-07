// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

import 'package:macrobenchmarks/common.dart';

void main() {
  macroPerfTest('cull_opacity_perf', kCullOpacityRouteName, pageDelay: Duration(seconds: 1), duration: Duration(seconds: 10));
}
