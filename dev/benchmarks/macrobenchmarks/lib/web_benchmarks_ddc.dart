// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'web_benchmarks.dart';

/// An entrypoint used by DDC for running macrobenchmarks.
///
/// DDC runs macrobenchmarks via 'flutter run', which hosts files from its own
/// local server. As a result, the macrobenchmarking orchestration server needs
/// to be hosted on a separate port. We split the entrypoint here because we
/// can't pass command line args to Dart apps on Flutter Web.
///
// TODO(markzipan): Use `main` in `'web_benchmarks.dart` when Flutter Web supports the `--dart-entrypoint-args` flag.
Future<void> main() async {
  // This is hard-coded and must be the same as `benchmarkServerPort` in `flutter/dev/devicelab/lib/tasks/web_benchmarks.dart`.
  await sharedMain(<String>['--port', '9999']);
}
