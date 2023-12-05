// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'html.dart';
import 'mediacapture_streams.dart';

@JS('CanvasCaptureMediaStreamTrack')
@staticInterop
class CanvasCaptureMediaStreamTrack implements MediaStreamTrack {}

extension CanvasCaptureMediaStreamTrackExtension
    on CanvasCaptureMediaStreamTrack {
  external void requestFrame();
  external HTMLCanvasElement get canvas;
}
