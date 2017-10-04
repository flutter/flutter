// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SemanticsEvent.toString', () {
    expect(
      new TestSemanticsEvent().toString(),
      'TestSemanticsEvent()',
    );
    expect(
      new TestSemanticsEvent(number: 10).toString(),
      'TestSemanticsEvent(number: 10)',
    );
    expect(
      new TestSemanticsEvent(text: 'hello').toString(),
      'TestSemanticsEvent(text: hello)',
    );
    expect(
      new TestSemanticsEvent(text: 'hello', number: 10).toString(),
      'TestSemanticsEvent(number: 10, text: hello)',
    );
  });
}

class TestSemanticsEvent extends SemanticsEvent {
  TestSemanticsEvent({ this.text, this.number }) : super('TestEvent');

  final String text;
  final int number;

  @override
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> result = <String, dynamic>{};
    if (text != null)
      result['text'] = text;
    if (number != null)
      result['number'] = number;
    return result;
  }
}
