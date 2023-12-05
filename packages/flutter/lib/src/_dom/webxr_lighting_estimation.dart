// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'dom.dart';
import 'geometry.dart';
import 'html.dart';
import 'webxr.dart';

typedef XRReflectionFormat = String;

@JS('XRLightProbe')
@staticInterop
class XRLightProbe implements EventTarget {}

extension XRLightProbeExtension on XRLightProbe {
  external XRSpace get probeSpace;
  external set onreflectionchange(EventHandler value);
  external EventHandler get onreflectionchange;
}

@JS('XRLightEstimate')
@staticInterop
class XRLightEstimate {}

extension XRLightEstimateExtension on XRLightEstimate {
  external JSFloat32Array get sphericalHarmonicsCoefficients;
  external DOMPointReadOnly get primaryLightDirection;
  external DOMPointReadOnly get primaryLightIntensity;
}

@JS()
@staticInterop
@anonymous
class XRLightProbeInit {
  external factory XRLightProbeInit({XRReflectionFormat reflectionFormat});
}

extension XRLightProbeInitExtension on XRLightProbeInit {
  external set reflectionFormat(XRReflectionFormat value);
  external XRReflectionFormat get reflectionFormat;
}
