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
    expect(new ValueKey<int>(3) == new ValueKey<int>(3), isTrue); // ignore: prefer_const_constructors
    expect(new ValueKey<num>(3) == new ValueKey<int>(3), isFalse); // ignore: prefer_const_constructors
    expect(new ValueKey<int>(3) == new ValueKey<int>(2), isFalse); // ignore: prefer_const_constructors
    expect(const ValueKey<double>(double.NAN) == const ValueKey<double>(double.NAN), isFalse);
    
    expect(new Key('') == new ValueKey<String>(''), isTrue); // ignore: prefer_const_constructors
    expect(new ValueKey<String>('') == new ValueKey<String>(''), isTrue); // ignore: prefer_const_constructors
    expect(new TestValueKey<String>('') == new ValueKey<String>(''), isFalse); // ignore: prefer_const_constructors
    expect(new TestValueKey<String>('') == new TestValueKey<String>(''), isTrue); // ignore: prefer_const_constructors

    expect(new ValueKey<String>('') == new ValueKey<dynamic>(''), isFalse); // ignore: prefer_const_constructors
    expect(new TestValueKey<String>('') == new TestValueKey<dynamic>(''), isFalse); // ignore: prefer_const_constructors
    
    expect(new UniqueKey() == new UniqueKey(), isFalse);
    LocalKey k = new UniqueKey();
    expect(new UniqueKey() == new UniqueKey(), isFalse);
    expect(k == k, isTrue);
    
    expect(new ValueKey<LocalKey>(k) == new ValueKey<LocalKey>(k), isTrue);
    expect(new ValueKey<LocalKey>(k) == new ValueKey<UniqueKey>(k), isFalse);
    expect(new ObjectKey(k) == new ObjectKey(k), isTrue);

    expect(new ValueKey<NotEquals>(const NotEquals()) == new ValueKey<NotEquals>(const NotEquals()), isFalse); // ignore: prefer_const_constructors
    expect(new ObjectKey(const NotEquals()) == new ObjectKey(const NotEquals()), isTrue); // ignore: prefer_const_constructors
    
    expect(new ObjectKey(const Object()) == new ObjectKey(const Object()), isTrue); // ignore: prefer_const_constructors
    expect(new ObjectKey(new Object()) == new ObjectKey(new Object()), isFalse);

    expect(new ValueKey<bool>(true), hasOneLineDescription);
    expect(new UniqueKey(), hasOneLineDescription);
    expect(new ObjectKey(true), hasOneLineDescription);
    expect(new GlobalKey(), hasOneLineDescription);
    expect(new GlobalKey(debugLabel: 'hello'), hasOneLineDescription);
    expect(new GlobalObjectKey(true), hasOneLineDescription);
  });
}
