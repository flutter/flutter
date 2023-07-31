// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/diagnostic/diagnostic.dart';

/// A concrete implementation of a diagnostic message.
class DiagnosticMessageImpl implements DiagnosticMessage {
  @override
  final String filePath;

  @override
  final int length;

  final String _message;

  @override
  final int offset;

  @override
  final String? url;

  /// Initialize a newly created message to represent a [message] reported in
  /// the file at the given [filePath] at the given [offset] and with the given
  /// [length].
  DiagnosticMessageImpl(
      {required this.filePath,
      required this.length,
      required String message,
      required this.offset,
      required this.url})
      : _message = message;

  @override
  String messageText({required bool includeUrl}) {
    if (includeUrl && url != null) {
      var result = StringBuffer(_message);
      if (!_message.endsWith('.')) {
        result.write('.');
      }
      result.write('  See $url');
      return result.toString();
    }
    return _message;
  }
}
