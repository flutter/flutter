// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'reporting.dart';

@JS('PermissionsPolicy')
@staticInterop
class PermissionsPolicy {}

extension PermissionsPolicyExtension on PermissionsPolicy {
  external bool allowsFeature(
    String feature, [
    String origin,
  ]);
  external JSArray features();
  external JSArray allowedFeatures();
  external JSArray getAllowlistForFeature(String feature);
}

@JS('PermissionsPolicyViolationReportBody')
@staticInterop
class PermissionsPolicyViolationReportBody implements ReportBody {}

extension PermissionsPolicyViolationReportBodyExtension
    on PermissionsPolicyViolationReportBody {
  external String get featureId;
  external String? get sourceFile;
  external int? get lineNumber;
  external int? get columnNumber;
  external String get disposition;
}
