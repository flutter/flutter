// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter_driver/src/common/find.dart';

import '../common.dart';

void main() {
  test('Ancestor finder serialize', () {
    final SerializableFinder of = ByType('Text');
    final SerializableFinder matching = ByValueKey('hello');

    final Ancestor a = Ancestor(
      of: of,
      matching: matching,
      matchRoot: true,
    );
    expect(a.serialize(), <String, String>{
      'finderType': 'Ancestor',
      'of': json.encode(of.serialize()),
      'matching': json.encode(matching.serialize()),
      'matchRoot': 'true'
    });
  });

  test('Ancestor finder deserialize', () {
    final SerializableFinder of = ByType('Text');
    final SerializableFinder matching = ByValueKey('hello');

    final Map<String, String> serialized = <String, String>{
      'finderType': 'Ancestor',
      'of': json.encode(of.serialize()),
      'matching': json.encode(matching.serialize()),
      'matchRoot': 'true'
    };

    final Ancestor a = Ancestor.deserialize(serialized);
    expect(a.of, isA<ByType>());
    expect(a.matching, isA<ByValueKey>());
    expect(a.matchRoot, isTrue);
  });

  test('Descendant finder serialize', () {
    final SerializableFinder of = ByType('Text');
    final SerializableFinder matching = ByValueKey('hello');

    final Descendant a = Descendant(
      of: of,
      matching: matching,
      matchRoot: true,
    );
    expect(a.serialize(), <String, String>{
      'finderType': 'Descendant',
      'of': json.encode(of.serialize()),
      'matching': json.encode(matching.serialize()),
      'matchRoot': 'true'
    });
  });

  test('Descendant finder deserialize', () {
    final SerializableFinder of = ByType('Text');
    final SerializableFinder matching = ByValueKey('hello');

    final Map<String, String> serialized = <String, String>{
      'finderType': 'Descendant',
      'of': json.encode(of.serialize()),
      'matching': json.encode(matching.serialize()),
      'matchRoot': 'true'
    };

    final Descendant a = Descendant.deserialize(serialized);
    expect(a.of, isA<ByType>());
    expect(a.matching, isA<ByValueKey>());
    expect(a.matchRoot, isTrue);
  });
}
