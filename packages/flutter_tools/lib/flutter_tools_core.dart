// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Core interfaces and data structures for Flutter tool extensions.
///
/// This library defines the contract between the Flutter host tool and
/// external extension isolates (tool extensions). It is imported by both the host
/// tool and the extension isolates to share service definitions (build, device,
/// diagnostics, templates, etc.) and serialization logic.
library flutter_tools_core;

export 'src/flutter_tools_core/artifacts.dart';
export 'src/flutter_tools_core/build.dart';
export 'src/flutter_tools_core/configuration.dart';
export 'src/flutter_tools_core/device.dart';
export 'src/flutter_tools_core/diagnostics.dart';
export 'src/flutter_tools_core/logger.dart';
export 'src/flutter_tools_core/plugins.dart';
export 'src/flutter_tools_core/templates.dart';
