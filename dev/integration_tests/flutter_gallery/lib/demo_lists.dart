// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Demos for which timeline data will be collected using
// FlutterDriver.traceAction().
//
// Warning: The number of tests executed with timeline collection enabled
// significantly impacts heap size of the running app. When run with
// --trace-startup, as we do in this test, the VM stores trace events in an
// endless buffer instead of a ring buffer.
//
// These names must match GalleryItem titles from kAllGalleryDemos
// in dev/integration_tests/flutter_gallery/lib/gallery/demos.dart
const List<String> kProfiledDemos = <String>[
  'Shrine@Studies',
  'Contact profile@Studies',
  'Animation@Studies',
  'Bottom navigation@Material',
  'Buttons@Material',
  'Cards@Material',
  'Chips@Material',
  'Dialogs@Material',
  'Pickers@Material',
];

// There are 3 places where the Gallery demos are traversed.
// 1- In widget tests such as dev/integration_tests/flutter_gallery/test/smoke_test.dart
// 2- In driver tests such as dev/integration_tests/flutter_gallery/test_driver/transitions_perf_test.dart
// 3- In on-device instrumentation tests such as dev/integration_tests/flutter_gallery/test/live_smoketest.dart
//
// If you change navigation behavior in the Gallery or in the framework, make
// sure all 3 are covered.

// Demos that will be backed out of within FlutterDriver.runUnsynchronized();
//
// These names must match GalleryItem titles from kAllGalleryDemos
// in dev/integration_tests/flutter_gallery/lib/gallery/demos.dart
const List<String> kUnsynchronizedDemos = <String>[
  'Progress indicators@Material',
  'Activity Indicator@Cupertino',
  'Video@Media',
];
