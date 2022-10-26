// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// This library exposes the [matchesFlutterGolden] function that's similar to
/// [matchesGoldenFile] but supports flaky goldens.

export 'src/flutter_goldens_io.dart' if (dart.library.js_util) 'src/flutter_goldens_web.dart'
  show matchesFlutterGolden;
