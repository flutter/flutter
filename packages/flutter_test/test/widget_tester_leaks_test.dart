// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';
import 'package:matcher/expect.dart' as matcher;
import 'package:matcher/src/expect/async_matcher.dart';

import 'utils/leaking_classes.dart'; // ignore: implementation_imports

void main() {
  late final Leaks reportedLeaks;
  experimentalCollectedLeaksReporter = (Leaks leaks) => reportedLeaks = leaks;
  LeakTesting.settings = LeakTesting.settings.copyWith(ignoredLeaks: const IgnoredLeaks(), ignore: false);

  group('gr1', () {
    testWidgets('test11', (_) async {
    });
  });

  group('gr2', () {
    testWidgets('test11', (_) async {
      StatelessLeakingWidget();
    });
  });

  tearDownAll(() {
    print(reportedLeaks.total);
  });
}
