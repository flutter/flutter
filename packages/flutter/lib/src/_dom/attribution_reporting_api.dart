// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

@JS()
@staticInterop
@anonymous
class AttributionReportingRequestOptions {
  external factory AttributionReportingRequestOptions({
    required bool eventSourceEligible,
    required bool triggerEligible,
  });
}

extension AttributionReportingRequestOptionsExtension
    on AttributionReportingRequestOptions {
  external set eventSourceEligible(bool value);
  external bool get eventSourceEligible;
  external set triggerEligible(bool value);
  external bool get triggerEligible;
}
