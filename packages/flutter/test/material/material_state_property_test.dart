// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';


void main() {
  test('MaterialStateProperty.resolveWith()', () {
    final MaterialStateProperty<MaterialState> value = MaterialStateProperty.resolveWith<MaterialState>(
      (Set<MaterialState> states) => states.first,
    );
    expect(value.resolve(<MaterialState>{MaterialState.hovered}), MaterialState.hovered);
    expect(value.resolve(<MaterialState>{MaterialState.focused}), MaterialState.focused);
    expect(value.resolve(<MaterialState>{MaterialState.pressed}), MaterialState.pressed);
    expect(value.resolve(<MaterialState>{MaterialState.dragged}), MaterialState.dragged);
    expect(value.resolve(<MaterialState>{MaterialState.selected}), MaterialState.selected);
    expect(value.resolve(<MaterialState>{MaterialState.disabled}), MaterialState.disabled);
    expect(value.resolve(<MaterialState>{MaterialState.error}), MaterialState.error);
  });

  test('MaterialStateProperty.all()', () {
    final MaterialStateProperty<int> value = MaterialStateProperty.all<int>(123);
    expect(value.resolve(<MaterialState>{MaterialState.hovered}), 123);
    expect(value.resolve(<MaterialState>{MaterialState.focused}), 123);
    expect(value.resolve(<MaterialState>{MaterialState.pressed}), 123);
    expect(value.resolve(<MaterialState>{MaterialState.dragged}), 123);
    expect(value.resolve(<MaterialState>{MaterialState.selected}), 123);
    expect(value.resolve(<MaterialState>{MaterialState.disabled}), 123);
    expect(value.resolve(<MaterialState>{MaterialState.error}), 123);
  });
}
