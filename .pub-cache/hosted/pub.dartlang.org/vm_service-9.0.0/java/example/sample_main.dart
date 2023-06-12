// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main(List<String> args) {
  String local1 = 'abcd';
  int local2 = 2;
  var longList = [1, "hello", 3, 5, 7, 11, 13, 14, 15, 16, 17, 18, 19, 20];
  var deepList = [
    Bar(),
    [
      [
        [
          [
            [7]
          ]
        ],
        "end"
      ]
    ]
  ];

  print('hello from main');

  foo(1);
  foo(local2);
  foo(3);
  foo(local1.length);

  print(longList);
  print(deepList);

  print('exiting...');
}

void foo(int val) {
  print('val: ${val}');
}

class Bar extends FooBar {
  String field1 = "my string";
}

class FooBar {
  int field2 = 47;
}
