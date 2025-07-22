// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'package:_macros/src/executor/cast.dart';

void main() {
  test("dynamic casts", () {
    expect(Cast<dynamic>().cast(3), 3);
    expect(Cast<dynamic>().cast("hello"), "hello");
  });

  test("int casts", () {
    expect(Cast<int>().cast(3), 3);
    expect(
        () => Cast<int>().cast("hello"),
        throwsA(isA<FailedCast>().having((e) => e.toString(), 'toString()',
            'Failed cast: expected type int but got type String for: hello')));
  });

  test("double casts", () {
    expect(Cast<double>().cast(3.1), 3.1);
    expect(
        () => Cast<double>().cast("hello"),
        throwsA(isA<FailedCast>().having(
            (e) => e.toString(),
            'toString()',
            'Failed cast: '
                'expected type double but got type String for: hello')));
  });

  test("String casts", () {
    expect(Cast<String>().cast("hello"), "hello");
    expect(
        () => Cast<String>().cast(3),
        throwsA(isA<FailedCast>().having((e) => e.toString(), 'toString()',
            'Failed cast: expected type String but got type int for: 3')));
  });

  test("bool casts", () {
    expect(Cast<bool>().cast(true), true);
    expect(
        () => Cast<bool>().cast(3),
        throwsA(isA<FailedCast>().having((e) => e.toString(), 'toString()',
            'Failed cast: expected type bool but got type int for: 3')));
  });

  test("Casting empty lists", () {
    var listOfInt = ListCast.from(Cast<int>());
    var listOfString = ListCast.from(Cast<String>());

    expect(listOfInt.cast(<dynamic>[]) is List<int>, isTrue);
    expect(listOfInt.cast(<dynamic>[]), <int>[]);

    expect(
        () => listOfString.cast({}),
        throwsA(isA<FailedCast>().having(
            (e) => e.toString(),
            'toString()',
            'Failed cast: expected type List<String> but got '
                'type _Map<dynamic, dynamic> for: {}')));
  });

  test("Casting non-empty lists", () {
    var listOfInt = ListCast.from(Cast<int>());
    var listOfString = ListCast.from(Cast<String>());

    expect(listOfInt.cast(<num>[3]) is List<int>, isTrue);
    expect(listOfInt.cast(<num>[3]), <int>[3]);
    expect(
        () => listOfString.cast(<num>[3]),
        throwsA(isA<FailedCast>().having((e) => e.toString(), 'toString()',
            'Failed cast: expected type String but got type int for: 3')));
  });

  test("Casting nested lists", () {
    var listOfInt = ListCast.from(Cast<int>());
    var listOfString = ListCast.from(Cast<String>());
    var listOfListOfInt = ListCast.from(listOfInt);
    var listOfListOfString = ListCast.from(listOfString);

    expect(
        listOfListOfInt.cast(<dynamic>[
          <dynamic>[3]
        ]) is List<List<int>>,
        isTrue);
    expect(
        listOfListOfInt.cast(<dynamic>[
          <dynamic>[3]
        ]),
        <List<int>>[
          <int>[3]
        ]);
    expect(
        () => listOfListOfString.cast(<dynamic>[
              <dynamic>[3]
            ]),
        throwsA(isA<FailedCast>().having((e) => e.toString(), 'toString()',
            'Failed cast: expected type String but got type int for: 3')));
  });

  test("Casting non-empty sets", () {
    var setOfInt = SetCast.from(Cast<int>());
    var setOfString = SetCast.from(Cast<String>());

    expect(setOfInt.cast(<num>{3}) is Set<int>, isTrue);
    expect(setOfInt.cast(<num>{3}), <int>{3});
    expect(
        () => setOfString.cast(<num>{3}),
        throwsA(isA<FailedCast>().having((e) => e.toString(), 'toString()',
            'Failed cast: expected type String but got type int for: 3')));
  });

  test("Casting nested sets", () {
    var setOfInt = SetCast.from(Cast<int>());
    var setOfString = SetCast.from(Cast<String>());
    var setOfSetOfInt = SetCast.from(setOfInt);
    var setOfSetOfString = SetCast.from(setOfString);

    expect(
        setOfSetOfInt.cast(<dynamic>{
          <dynamic>{3}
        }) is Set<Set<int>>,
        isTrue);
    expect(
        setOfSetOfInt.cast(<dynamic>{
          <dynamic>{3}
        }),
        <Set<int>>{
          <int>{3}
        });
    expect(
        () => setOfSetOfString.cast(<dynamic>{
              <dynamic>{3}
            }),
        throwsA(isA<FailedCast>().having((e) => e.toString(), 'toString()',
            'Failed cast: expected type String but got type int for: 3')));
  });

  test("Casting empty maps", () {
    var mapOfStringToInt = MapCast.from(Cast<String>(), Cast<int>());
    var mapOfStringToString = MapCast.from(Cast<String>(), Cast<String>());

    expect(mapOfStringToInt.cast(<dynamic, dynamic>{}) is Map<String, int>,
        isTrue);
    expect(mapOfStringToInt.cast(<dynamic, dynamic>{}), <String, int>{});

    expect(
        () => mapOfStringToString.cast(<dynamic>[]),
        throwsA(isA<FailedCast>().having(
            (e) => e.toString(),
            'toString()',
            'Failed cast: expected type Map<String, String> but got type '
                'List<dynamic> for: []')));
  });

  test("Casting non-empty maps", () {
    var mapOfStringToInt = MapCast.from(Cast<String>(), Cast<int>());
    var mapOfStringToString = MapCast.from(Cast<String>(), Cast<String>());

    expect(
        mapOfStringToInt.cast(<dynamic, dynamic>{"hello": 3})
            is Map<String, int>,
        isTrue);
    expect(mapOfStringToInt.cast(<dynamic, dynamic>{"hello": 3}),
        <String, int>{"hello": 3});

    expect(() => mapOfStringToString.cast(<dynamic, dynamic>{"hello": 3}),
        throwsA(isA<FailedCast>()));
    expect(
        () => mapOfStringToString.cast(<dynamic, dynamic>{3: "world"}),
        throwsA(isA<FailedCast>().having((e) => e.toString(), 'toString()',
            'Failed cast: expected type String but got type int for: 3')));
  });

  test("Casting nested maps", () {
    var schema =
        MapCast.from(Cast<String>(), MapCast.from(Cast<String>(), Cast<int>()));

    expect(
        schema.cast(<dynamic, dynamic>{
          "hello": <dynamic, dynamic>{"hello": 3}
        }) is Map<String, Map<String, int>>,
        isTrue);
    expect(
        schema.cast(<dynamic, dynamic>{
          "hello": <dynamic, dynamic>{"hello": 3}
        }),
        <String, Map<String, int>>{
          "hello": <String, int>{"hello": 3}
        });

    expect(
        () => schema.cast(<dynamic, dynamic>{
              "hello": <dynamic, dynamic>{3: "hello"}
            }),
        throwsA(isA<FailedCast>().having((e) => e.toString(), 'toString()',
            'Failed cast: expected type String but got type int for: 3')));
  });

  test("Casting nested list/maps/sets", () {
    var schema =
        MapCast.from(Cast<String>(), ListCast.from(SetCast.from(Cast<int>())));

    expect(
        schema.cast(<dynamic, dynamic>{
          "hello": <dynamic>[
            {3}
          ]
        }) is Map<String, List<Set<int>>>,
        isTrue);
    expect(
        schema.cast(<dynamic, dynamic>{
          "hello": <dynamic>[
            {3}
          ]
        }),
        <String, List<Set<int>>>{
          "hello": <Set<int>>[
            {3}
          ]
        });
  });

  test("nullable cast", () {
    expect(Cast<int>().nullable.cast(null), null);
    expect(Cast<int>().nullable.cast(3), 3);
    expect(ListCast.from(Cast<int>()).nullable.cast(<num>[3]), <int>[3]);
    expect(ListCast.from(Cast<int>().nullable).cast(<num?>[3, null]),
        <int?>[3, null]);
    expect(
        () => Cast<int>().nullable.cast(2.0),
        throwsA(isA<FailedCast>().having((e) => e.toString(), 'toString()',
            'Failed cast: expected type int but got type double for: 2.0')));
    expect(
        () => ListCast.from(Cast<int>()).nullable.cast([2.0]),
        throwsA(isA<FailedCast>().having((e) => e.toString(), 'toString()',
            'Failed cast: expected type int but got type double for: 2.0')));
  });
}
