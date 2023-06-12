// Copyright 2013 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

library quiver.collection.delegates.list_test;

import 'package:quiver/src/collection/delegates/list.dart';
import 'package:test/test.dart';

class MyList<T> extends DelegatingList<T> {
  MyList(this._delegate);

  final List<T> _delegate;

  @override
  List<T> get delegate => _delegate;
}

void main() {
  group('DelegatingList', () {
    late DelegatingList<String> delegatingList;

    setUp(() {
      delegatingList = MyList<String>(['a', 'b', 'cc']);
    });

    test('[]', () {
      expect(delegatingList[0], equals('a'));
      expect(delegatingList[1], equals('b'));
      expect(delegatingList[2], equals('cc'));
      expect(() => delegatingList[3], throwsRangeError);
    });

    test('[]=', () {
      delegatingList[0] = 'd';
      expect(delegatingList, equals(['d', 'b', 'cc']));
    });

    test('+', () {
      var sum = delegatingList + ['d', 'e'];
      expect(sum, equals(['a', 'b', 'cc', 'd', 'e']));
    });

    test('add', () {
      delegatingList.add('d');
      expect(delegatingList, equals(['a', 'b', 'cc', 'd']));
    });

    test('addAll', () {
      delegatingList.addAll(['d', 'e']);
      expect(delegatingList, equals(['a', 'b', 'cc', 'd', 'e']));
    });

    test('asMap', () {
      expect(delegatingList.asMap(), equals({0: 'a', 1: 'b', 2: 'cc'}));
    });

    test('clear', () {
      delegatingList.clear();
      expect(delegatingList, equals([]));
    });

    test('fillRange', () {
      DelegatingList<String?> nullableDelegatingList =
          MyList<String?>(['a', 'b', 'cc']);
      nullableDelegatingList.fillRange(0, 2);
      expect(nullableDelegatingList, equals([null, null, 'cc']));

      delegatingList.fillRange(0, 2, 'd');
      expect(delegatingList, equals(['d', 'd', 'cc']));
    });

    test('getRange', () {
      expect(delegatingList.getRange(1, 2), equals(['b']));
      expect(delegatingList.getRange(1, 3), equals(['b', 'cc']));
    });

    test('indexOf', () {
      expect(delegatingList.indexOf('b'), equals(1));
      expect(delegatingList.indexOf('a', 1), equals(-1));
      expect(delegatingList.indexOf('cc', 1), equals(2));
    });

    test('indexWhere', () {
      delegatingList.add('bb');
      expect(delegatingList.indexWhere((e) => e.length > 1), equals(2));
    });

    test('insert', () {
      delegatingList.insert(1, 'd');
      expect(delegatingList, equals(['a', 'd', 'b', 'cc']));
    });

    test('insertAll', () {
      delegatingList.insertAll(1, ['d', 'e']);
      expect(delegatingList, equals(['a', 'd', 'e', 'b', 'cc']));
    });

    test('lastIndexOf', () {
      expect(delegatingList.lastIndexOf('b'), equals(1));
      expect(delegatingList.lastIndexOf('a', 1), equals(0));
      expect(delegatingList.lastIndexOf('cc', 1), equals(-1));
    });

    test('lastIndexWhere', () {
      delegatingList.add('bb');
      expect(delegatingList.lastIndexWhere((e) => e.length > 1), equals(3));
    });

    test('set length', () {
      delegatingList.length = 2;
      expect(delegatingList, equals(['a', 'b']));
    });

    test('remove', () {
      delegatingList.remove('b');
      expect(delegatingList, equals(['a', 'cc']));
    });

    test('removeAt', () {
      delegatingList.removeAt(1);
      expect(delegatingList, equals(['a', 'cc']));
    });

    test('removeLast', () {
      delegatingList.removeLast();
      expect(delegatingList, equals(['a', 'b']));
    });

    test('removeRange', () {
      delegatingList.removeRange(1, 2);
      expect(delegatingList, equals(['a', 'cc']));
    });

    test('removeWhere', () {
      delegatingList.removeWhere((e) => e.length == 1);
      expect(delegatingList, equals(['cc']));
    });

    test('replaceRange', () {
      delegatingList.replaceRange(1, 2, ['d', 'e']);
      expect(delegatingList, equals(['a', 'd', 'e', 'cc']));
    });

    test('retainWhere', () {
      delegatingList.retainWhere((e) => e.length == 1);
      expect(delegatingList, equals(['a', 'b']));
    });

    test('reversed', () {
      expect(delegatingList.reversed, equals(['cc', 'b', 'a']));
    });

    test('setAll', () {
      delegatingList.setAll(1, ['d', 'e']);
      expect(delegatingList, equals(['a', 'd', 'e']));
    });

    test('setRange', () {
      delegatingList.setRange(1, 3, ['d', 'e']);
      expect(delegatingList, equals(['a', 'd', 'e']));
    });

    test('sort', () {
      delegatingList.sort((a, b) => b.codeUnitAt(0) - a.codeUnitAt(0));
      expect(delegatingList, equals(['cc', 'b', 'a']));
    });

    test('sublist', () {
      expect(delegatingList.sublist(1), equals(['b', 'cc']));
      expect(delegatingList.sublist(1, 2), equals(['b']));
    });
  });
}
