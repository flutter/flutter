// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// System services exposed to Flutter apps.
///
/// For example, this library includes [fetch], which fetches data from the
/// network.
///
/// This library depends only on core Dart libraries as well as the `mojo`,
/// `mojo_services`, and `sky_services` and packages.
library services;

export 'src/services/activity.dart';
export 'src/services/asset_bundle.dart';
export 'src/services/binding.dart';
export 'src/services/fetch.dart';
export 'src/services/image_cache.dart';
export 'src/services/image_decoder.dart';
export 'src/services/image_resource.dart';
export 'src/services/keyboard.dart';
export 'src/services/service_registry.dart';
export 'src/services/shell.dart';
