// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'test_library.dart';

int normalFunction() {
  return 123;
}

abstract class BaseClass {
  int abstractMethod();
}

class SomeClass extends BaseClass {
  SomeClass() : x = 123;

  // Creates an implicit getter and setter that should be ignored.
  int x;

  int normalMethod() {
    return 123;
  }

  static int staticMethod() {
    return 123;
  }

  @override
  int abstractMethod() {
    return 123;
  }
}

extension SomeExtension on SomeClass {
  int extensionMethod() {
    return 123;
  }
}

class OtherClass {
  int otherMethod() {
    return 123;
  }
}

void main() {
  print(normalFunction());
  print(SomeClass().normalMethod());
  print(SomeClass.staticMethod());
  print(SomeClass().extensionMethod());
  print(SomeClass().abstractMethod());
  print(OtherClass().otherMethod());
  print(libraryFunction());
  print(otherLibraryFunction());
}
