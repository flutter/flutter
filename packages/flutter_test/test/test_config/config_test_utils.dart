// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

void testConfig(
  final String description,
  final String? expectedStringValue, {
  final Map<Type, dynamic> otherExpectedValues = const <Type, dynamic>{int: isNull},
}) {
  final String? actualStringValue = Zone.current[String] as String?;
  final Map<Type, dynamic> otherActualValues = otherExpectedValues.map<Type, dynamic>(
    (final Type key, final dynamic value) {
      return MapEntry<Type, dynamic>(key, Zone.current[key]);
    },
  );

  test(description, () {
    expect(actualStringValue, expectedStringValue);
    for (final Type key in otherExpectedValues.keys) {
      expect(otherActualValues[key], otherExpectedValues[key]);
    }
  });
}
