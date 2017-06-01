// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/logger.dart';
import 'package:test/test.dart';

void main() {
  group('AppContext', () {
    test('error', () async {
      final BufferLogger mockLogger = new BufferLogger();
      final VerboseLogger verboseLogger = new VerboseLogger(mockLogger);
      verboseLogger.supportsColor = false;

      verboseLogger.printStatus('Hey Hey Hey Hey');
      verboseLogger.printTrace('Oooh, I do I do I do');
      verboseLogger.printError('Helpless!');

      expect(mockLogger.statusText, matches(r'^\[     (?: {0,2}\+[0-9]{1,3} ms|       )\] Hey Hey Hey Hey\n'
                                            r'\[     (?: {0,2}\+[0-9]{1,3} ms|       )\] Oooh, I do I do I do\n$'));
      expect(mockLogger.traceText, '');
      expect(mockLogger.errorText, matches(r'^\[     (?: {0,2}\+[0-9]{1,3} ms|       )\] Helpless!\n$'));
    });
  });
}
