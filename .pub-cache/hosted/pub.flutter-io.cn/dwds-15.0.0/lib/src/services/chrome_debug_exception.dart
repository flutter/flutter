// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

class ChromeDebugException extends ExceptionDetails implements Exception {
  /// Optional, additional information about the exception.
  final Object? additionalDetails;

  /// Optional, the exact contents of the eval that was attempted.
  final String? evalContents;

  ChromeDebugException(Map<String, dynamic> exceptionDetails,
      {this.additionalDetails, this.evalContents})
      : super(exceptionDetails);

  @override
  String toString() {
    final description = StringBuffer()
      ..writeln('Unexpected error from chrome devtools:');
    description.writeln('text: $text');
    if (exception != null) {
      description.writeln('exception:');
      description.writeln('  description: ${exception?.description}');
      description.writeln('  type: ${exception?.type}');
      description.writeln('  value: ${exception?.value}');
    }
    if (evalContents != null) {
      description.writeln('attempted JS eval: `$evalContents`');
    }
    if (additionalDetails != null) {
      description.writeln('additional details:\n  $additionalDetails');
    }
    return description.toString();
  }
}
