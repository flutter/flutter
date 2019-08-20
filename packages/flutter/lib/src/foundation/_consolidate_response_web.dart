// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'consolidate_response.dart' as consolidate_response;

/// The dart:html implementation of [consolidate_response.consolidateHttpClientResponseBytes].
///
/// This implementation is unsupported and throws when invoked.
Future<Uint8List> consolidateHttpClientResponseBytes(
  Object response, {
  bool autoUncompress = true,
  consolidate_response.BytesReceivedCallback onBytesReceived,
}) {
  throw UnsupportedError('consolidateHttpClientResponseBytes is not supported on the web.');
}
