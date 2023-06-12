// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/exception/exception.dart';

/// Exception that wraps another exception, and includes the content of
/// files that might be related to the exception, and help to identify the
/// issue and fix it.
class CaughtExceptionWithFiles extends CaughtException {
  final Map<String, String> fileContentMap;

  CaughtExceptionWithFiles(
    super.exception,
    super.stackTrace,
    this.fileContentMap,
  );
}
