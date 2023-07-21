// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The contents of the asset manifest generated at build time.
///
/// For most web apps, the generated entry point code includes code that writes
/// the asset manifest's contents to a JS global as a base64-encoded string.
///
/// This implementation, for non-web apps, is null since loading the asset
/// manifest has a higher probability of working.
// We want to use the same signature as the web counterpart, so we
// declare this as final rather than const.
// ignore: prefer_const_declarations
final List<int>? assetManifestContents = null;
