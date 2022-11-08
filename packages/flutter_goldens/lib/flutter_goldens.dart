// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// This library exposes functions that enhance the test with custom golden
/// configuration for the Flutter repository.

export 'package:flutter_goldens_client/skia_client.dart';
export 'src/flaky_goldens.dart' show expectFlakyGolden;
export 'src/flutter_goldens_io.dart' if (dart.library.js_util) 'src/flutter_goldens_web.dart'
  show processBrowserCommand, testExecutable;
