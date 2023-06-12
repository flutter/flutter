// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:source_span/source_span.dart';

import '../util/errors.dart';

class LoadException implements Exception {
  final String path;

  final Object innerError;

  LoadException(this.path, this.innerError);

  @override
  String toString({bool color = false}) {
    var buffer = StringBuffer();
    if (color) buffer.write('\u001b[31m'); // red
    buffer.write('Failed to load "$path":');
    if (color) buffer.write('\u001b[0m'); // no color

    var innerString = getErrorMessage(innerError);
    if (innerError is SourceSpanException) {
      innerString = (innerError as SourceSpanException)
          .toString(color: color)
          .replaceFirst(' of $path', '');
    }

    buffer.write(innerString.contains('\n') ? '\n' : ' ');
    buffer.write(innerString);
    return buffer.toString();
  }
}
