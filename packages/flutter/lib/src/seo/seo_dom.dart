// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Conditional import that selects the appropriate implementation
/// based on the platform.
///
/// On web: Uses dart:html for actual DOM manipulation
/// On other platforms: Uses a no-op stub implementation
export 'seo_tree_stub.dart'
    if (dart.library.html) 'seo_tree_web.dart';
