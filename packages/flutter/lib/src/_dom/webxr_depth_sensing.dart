// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'webgl1.dart';
import 'webxr.dart';

typedef XRDepthUsage = String;
typedef XRDepthDataFormat = String;

@JS()
@staticInterop
@anonymous
class XRDepthStateInit {
  external factory XRDepthStateInit({
    required JSArray usagePreference,
    required JSArray dataFormatPreference,
  });
}

extension XRDepthStateInitExtension on XRDepthStateInit {
  external set usagePreference(JSArray value);
  external JSArray get usagePreference;
  external set dataFormatPreference(JSArray value);
  external JSArray get dataFormatPreference;
}

@JS('XRDepthInformation')
@staticInterop
class XRDepthInformation {}

extension XRDepthInformationExtension on XRDepthInformation {
  external int get width;
  external int get height;
  external XRRigidTransform get normDepthBufferFromNormView;
  external num get rawValueToMeters;
}

@JS('XRCPUDepthInformation')
@staticInterop
class XRCPUDepthInformation implements XRDepthInformation {}

extension XRCPUDepthInformationExtension on XRCPUDepthInformation {
  external num getDepthInMeters(
    num x,
    num y,
  );
  external JSArrayBuffer get data;
}

@JS('XRWebGLDepthInformation')
@staticInterop
class XRWebGLDepthInformation implements XRDepthInformation {}

extension XRWebGLDepthInformationExtension on XRWebGLDepthInformation {
  external WebGLTexture get texture;
}
