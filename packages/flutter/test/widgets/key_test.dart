// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class TestValueKey<T> extends ValueKey<T> {
  const TestValueKey(super.value);
}

@immutable
class NotEquals {
  const NotEquals();
  @override
  bool operator ==(Object other) => false;
  @override
  int get hashCode => 0;
}

void main() {
  testWidgets('Keys', (WidgetTester tester) async {
    expect(ValueKey<int>(nonconst(3)) == ValueKey<int>(nonconst(3)), isTrue);
    expect(ValueKey<num>(nonconst(3)) == ValueKey<int>(nonconst(3)), isFalse);
    expect(ValueKey<int>(nonconst(3)) == ValueKey<int>(nonconst(2)), isFalse);
    expect(const ValueKey<double>(double.nan) == const ValueKey<double>(double.nan), isFalse);

    expect(Key(nonconst('')) == ValueKey<String>(nonconst('')), isTrue);
    expect(ValueKey<String>(nonconst('')) == ValueKey<String>(nonconst('')), isTrue);
    expect(TestValueKey<String>(nonconst('')) == ValueKey<String>(nonconst('')), isFalse);
    expect(TestValueKey<String>(nonconst('')) == TestValueKey<String>(nonconst('')), isTrue);

    expect(ValueKey<String>(nonconst('')) == ValueKey<dynamic>(nonconst('')), isFalse);
    expect(TestValueKey<String>(nonconst('')) == TestValueKey<dynamic>(nonconst('')), isFalse);

    expect(UniqueKey() == UniqueKey(), isFalse);
    final k = UniqueKey();
    expect(UniqueKey() == UniqueKey(), isFalse);
    expect(k == k, isTrue);

    expect(ValueKey<LocalKey>(k) == ValueKey<LocalKey>(k), isTrue);
    expect(ValueKey<LocalKey>(k) == ValueKey<UniqueKey>(k), isFalse);
    expect(ObjectKey(k) == ObjectKey(k), isTrue);

    final NotEquals constNotEquals = nonconst(const NotEquals());
    expect(ValueKey<NotEquals>(constNotEquals) == ValueKey<NotEquals>(constNotEquals), isFalse);
    expect(ObjectKey(constNotEquals) == ObjectKey(constNotEquals), isTrue);

    final Object constObject = nonconst(const Object());
    expect(ObjectKey(constObject) == ObjectKey(constObject), isTrue);
    expect(ObjectKey(nonconst(Object())) == ObjectKey(nonconst(Object())), isFalse);

    expect(const ValueKey<bool>(true), hasOneLineDescription);
    expect(UniqueKey(), hasOneLineDescription);
    expect(const ObjectKey(true), hasOneLineDescription);
    expect(GlobalKey(), hasOneLineDescription);
    expect(GlobalKey(debugLabel: 'hello'), hasOneLineDescription);
    expect(const GlobalObjectKey(true), hasOneLineDescription);
  });
}
