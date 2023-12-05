// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

@JS()
@staticInterop
@anonymous
class AV1EncoderConfig {
  external factory AV1EncoderConfig({bool forceScreenContentTools});
}

extension AV1EncoderConfigExtension on AV1EncoderConfig {
  external set forceScreenContentTools(bool value);
  external bool get forceScreenContentTools;
}

@JS()
@staticInterop
@anonymous
class VideoEncoderEncodeOptionsForAv1 {
  external factory VideoEncoderEncodeOptionsForAv1({int? quantizer});
}

extension VideoEncoderEncodeOptionsForAv1Extension
    on VideoEncoderEncodeOptionsForAv1 {
  external set quantizer(int? value);
  external int? get quantizer;
}
