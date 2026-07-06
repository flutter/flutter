// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Library for developing Flutter tool extensions.
///
/// This library exports the core interfaces (`flutter_tools_core`), the
/// tool extension protocol (`generic_extension_protocol`), and the base
/// extension class ([FlutterToolsExtension]). Extension implementations should
/// import this library.
///
/// @docImport 'flutter_tools_core.dart';
/// @docImport 'generic_extension_protocol.dart';
/// @docImport 'src/flutter_tools_extension/extension.dart';
library flutter_tools_extension;

export 'flutter_tools_core.dart';
export 'generic_extension_protocol.dart';
export 'src/flutter_tools_extension/extension.dart';
