// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js' as js;

/// The contents of the asset manifest generated at build time.
///
/// For most web apps, the generated entry point code includes code that writes
/// the asset manifest's contents to a JS global as a base64-encoded string.
/// This implementation reads that global.
final List<int>? assetManifestContents =
  js.context['_flutter_assetManifestAsByteList'] as List<int>?;
