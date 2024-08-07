// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SuggestionSpan.toString', () {
    const SuggestionSpan suggestionSpan = SuggestionSpan(
      TextRange(start: 0, end: 1),
      <String>[
        'receive',
        'weird',
      ],
    );

    expect(suggestionSpan.toString(), 'SuggestionSpan(range: TextRange(start: 0, end: 1), suggestions: [receive, weird])');
  });
}
