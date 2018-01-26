// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Provides an API to test Flutter applications on Fuchsia devices and
/// emulators.
///
/// The application runs in a separate process from the actual test.

library flutter_fuchsia;

export 'src/flutter_views.dart' show getFlutterViews;
