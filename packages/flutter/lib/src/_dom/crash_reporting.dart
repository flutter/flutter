// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'reporting.dart';

@JS('CrashReportBody')
@staticInterop
class CrashReportBody implements ReportBody {}

extension CrashReportBodyExtension on CrashReportBody {
  external JSObject toJSON();
  external String? get reason;
}
