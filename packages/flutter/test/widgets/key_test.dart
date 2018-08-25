// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

class TestValueKey<T> extends ValueKey<T> {
  const TestValueKey(T value) : super(value);
}

class NotEquals {
  const NotEquals();
  @override
  bool operator ==(dynamic other) => false;
  @override
  int get hashCode => 0;
}

void main() {
  testWidgets('Keys', (WidgetTester tester) async {
    expect(new ValueKey<int>(nonconst(3)) == new ValueKey<int>(nonconst(3)), isTrue);
    expect(new ValueKey<num>(nonconst(3)) == new ValueKey<int>(nonconst(3)), isFalse);
    expect(new ValueKey<int>(nonconst(3)) == new ValueKey<int>(nonconst(2)), isFalse);
    expect(const ValueKey<double>(double.nan) == const ValueKey<double>(double.nan), isFalse);

    expect(new Key(nonconst('')) == new ValueKey<String>(nonconst('')), isTrue);
    expect(new ValueKey<String>(nonconst('')) == new ValueKey<String>(nonconst('')), isTrue);
    expect(new TestValueKey<String>(nonconst('')) == new ValueKey<String>(nonconst('')), isFalse);
    expect(new TestValueKey<String>(nonconst('')) == new TestValueKey<String>(nonconst('')), isTrue);

    expect(new ValueKey<String>(nonconst('')) == new ValueKey<dynamic>(nonconst('')), isFalse);
    expect(new TestValueKey<String>(nonconst('')) == new TestValueKey<dynamic>(nonconst('')), isFalse);

    expect(new UniqueKey() == new UniqueKey(), isFalse);
    final LocalKey k = new UniqueKey();
    expect(new UniqueKey() == new UniqueKey(), isFalse);
    expect(k == k, isTrue);

    expect(new ValueKey<LocalKey>(k) == new ValueKey<LocalKey>(k), isTrue);
    expect(new ValueKey<LocalKey>(k) == new ValueKey<UniqueKey>(k), isFalse);
    expect(new ObjectKey(k) == new ObjectKey(k), isTrue);

    final NotEquals constNotEquals = nonconst(const NotEquals());
    expect(new ValueKey<NotEquals>(constNotEquals) == new ValueKey<NotEquals>(constNotEquals), isFalse);
    expect(new ObjectKey(constNotEquals) == new ObjectKey(constNotEquals), isTrue);

    final Object constObject = nonconst(const Object());
    expect(new ObjectKey(constObject) == new ObjectKey(constObject), isTrue);
    expect(new ObjectKey(new Object()) == new ObjectKey(new Object()), isFalse);

    expect(const ValueKey<bool>(true), hasOneLineDescription);
    expect(new UniqueKey(), hasOneLineDescription);
    expect(const ObjectKey(true), hasOneLineDescription);
    expect(new GlobalKey(), hasOneLineDescription);
    expect(new GlobalKey(debugLabel: 'hello'), hasOneLineDescription);
    expect(const GlobalObjectKey(true), hasOneLineDescription);
  });
}
