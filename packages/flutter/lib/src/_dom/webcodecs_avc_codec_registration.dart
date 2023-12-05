// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

typedef AvcBitstreamFormat = String;

@JS()
@staticInterop
@anonymous
class AvcEncoderConfig {
  external factory AvcEncoderConfig({AvcBitstreamFormat format});
}

extension AvcEncoderConfigExtension on AvcEncoderConfig {
  external set format(AvcBitstreamFormat value);
  external AvcBitstreamFormat get format;
}

@JS()
@staticInterop
@anonymous
class VideoEncoderEncodeOptionsForAvc {
  external factory VideoEncoderEncodeOptionsForAvc({int? quantizer});
}

extension VideoEncoderEncodeOptionsForAvcExtension
    on VideoEncoderEncodeOptionsForAvc {
  external set quantizer(int? value);
  external int? get quantizer;
}
