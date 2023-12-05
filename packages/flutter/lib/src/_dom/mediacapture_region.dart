// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'dom.dart';
import 'element_capture.dart';
import 'mediacapture_streams.dart';

@JS('CropTarget')
@staticInterop
class CropTarget {
  external static JSPromise fromElement(Element element);
}

@JS('BrowserCaptureMediaStreamTrack')
@staticInterop
class BrowserCaptureMediaStreamTrack implements MediaStreamTrack {}

extension BrowserCaptureMediaStreamTrackExtension
    on BrowserCaptureMediaStreamTrack {
  external JSPromise restrictTo(RestrictionTarget? RestrictionTarget);
  external JSPromise cropTo(CropTarget? cropTarget);
  external BrowserCaptureMediaStreamTrack clone();
}
