// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  test('TypedDictionary set and get', () {
    final TypedDictionary dict = TypedDictionary();

    dict.set<String>('hello');
    dict.set<int>(52);

    expect(dict.get<String>(), 'hello');
    expect(dict.get<int>(), 52);

    dict.set<String>('flutter');
    dict.set<int>(44);

    expect(dict.get<String>(), 'flutter');
    expect(dict.get<int>(), 44);
    expect(dict.get<double>(), isNull);
  });

  test('TypedDictionary.toString', () {
    final TypedDictionary dict = TypedDictionary();

    expect(dict.toString(), '{}');

    dict.set<String>('hello');
    dict.set<int>(52);

    expect(dict.toString(), '{String: hello, int: 52}');
  });

  test('TypedDictionary.empty', () {
    const TypedDictionary dict = TypedDictionary.empty;
    expect(dict.toString(), '{}');
    expect(dict.get<String>(), isNull);
    expect(dict.isEmpty, isTrue);

   expect(() => dict.set<String>('hello'), throwsUnsupportedError);
  });

  test('TypedDictionary.unmodifiable', () {
    final TypedDictionary dict = TypedDictionary();
    dict.set<String>('hello');
    dict.set<int>(52);

    final TypedDictionary unmodifiable = TypedDictionary.unmodifiable(dict);
    expect(unmodifiable.get<String>(), 'hello');
    expect(unmodifiable.get<int>(), 52);

    expect(() => unmodifiable.set<String>('flutter'), throwsUnsupportedError);
    expect(unmodifiable.get<String>(), 'hello');
  });

  test('TypedDictionary..isEmpty..isNotEmpty', () {
    final TypedDictionary dict = TypedDictionary();
    expect(dict.isEmpty, isTrue);
    expect(dict.isNotEmpty, isFalse);

    dict.set<String>('hello');
    expect(dict.isEmpty, isFalse);
    expect(dict.isNotEmpty, isTrue);
  });

  test('TypedDictionary.length', () {
    final TypedDictionary dict = TypedDictionary();
    expect(dict.length, 0);

    dict.set<String>('hello');
    expect(dict.length, 1);

    dict.set<int>(52);
    expect(dict.length, 2);

    dict.set<String>('flutter');
    expect(dict.length, 2);
  });
}
