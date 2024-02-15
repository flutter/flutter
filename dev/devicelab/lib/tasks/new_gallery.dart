// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'perf_tests.dart';

class NewGalleryPerfTest extends PerfTest {
  NewGalleryPerfTest({
    String timelineFileName = 'transitions',
    String dartDefine = '',
    super.enableImpeller,
    super.timeoutSeconds,
    super.forceOpenGLES,
  }) : super(
    'dev/integration_tests/new_gallery',
    'test_driver/transitions_perf.dart',
    timelineFileName,
    dartDefine: dartDefine,
    createPlatforms: ['android', 'ios', 'web']
  );
}
