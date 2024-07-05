// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'build_info.dart';

/// An interface to enable overriding native assets build logic in other
/// build systems.
abstract class TestCompilerNativeAssetsBuilder {
  Future<Uri?> build(BuildInfo buildInfo);
}
