// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Provides an API to test Flutter applications on Fuchsia devices and
/// emulators.
///
/// The tested application typically runs in a separate process from the actual
/// test, wherein the user can supply the process with various events to test
/// the behavior of said application.

library flutter_fuchsia;

export 'src/flutter_views.dart' show getFlutterViews;
