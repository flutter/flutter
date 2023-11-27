// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:litetest/litetest.dart';

void main() {
  test('ViewConstraints.tight', () {
    final ViewConstraints tightConstraints = ViewConstraints.tight(const Size(200, 300));
    expect(tightConstraints.minWidth, 200);
    expect(tightConstraints.maxWidth, 200);
    expect(tightConstraints.minHeight, 300);
    expect(tightConstraints.maxHeight, 300);

    expect(tightConstraints.isTight, true);
    expect(tightConstraints.isSatisfiedBy(const Size(200, 300)), true);
    expect(tightConstraints.isSatisfiedBy(const Size(400, 500)), false);
    expect(tightConstraints / 2, ViewConstraints.tight(const Size(100, 150)));
  });

  test('ViewConstraints unconstrained', () {
    const ViewConstraints defaultValues = ViewConstraints();
    expect(defaultValues.minWidth, 0);
    expect(defaultValues.maxWidth, double.infinity);
    expect(defaultValues.minHeight, 0);
    expect(defaultValues.maxHeight, double.infinity);

    expect(defaultValues.isTight, false);
    expect(defaultValues.isSatisfiedBy(const Size(200, 300)), true);
    expect(defaultValues.isSatisfiedBy(const Size(400, 500)), true);
    expect(defaultValues / 2, const ViewConstraints());
  });


  test('ViewConstraints', () {
    const ViewConstraints constraints = ViewConstraints(minWidth: 100, maxWidth: 200, minHeight: 300, maxHeight: 400);
    expect(constraints.minWidth, 100);
    expect(constraints.maxWidth, 200);
    expect(constraints.minHeight, 300);
    expect(constraints.maxHeight, 400);

    expect(constraints.isTight, false);
    expect(constraints.isSatisfiedBy(const Size(200, 300)), true);
    expect(constraints.isSatisfiedBy(const Size(400, 500)), false);
    expect(constraints / 2, const ViewConstraints(minWidth: 50, maxWidth: 100, minHeight: 150, maxHeight: 200));
  });
}
