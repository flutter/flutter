// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

const String kWasmMoreInfo = 'See https://flutter.dev/to/wasm for more information.';
const String kWasmErrorsMoreInfo =
    'See https://flutter.dev/to/wasm-errors for diagnostic and migration guidance.';

/// Legacy web libraries unsupported in WebAssembly compilation.
const Set<String> kLegacyWebLibraries = <String>{
  'dart:html',
  'dart:indexed_db',
  'dart:js',
  'dart:js_util',
  'dart:svg',
  'dart:web_audio',
  'dart:web_gl',
  'dart:web_sql',
  'package:js',
};

/// Headers required to run Wasm-compiled applications with multi-threading.
///
/// See https://developer.chrome.com/blog/coep-credentialless-origin-trial
/// for more information.
const kCrossOriginIsolationHeaders = <String, String>{
  'Cross-Origin-Opener-Policy': 'same-origin',
  'Cross-Origin-Embedder-Policy': 'credentialless',
};
