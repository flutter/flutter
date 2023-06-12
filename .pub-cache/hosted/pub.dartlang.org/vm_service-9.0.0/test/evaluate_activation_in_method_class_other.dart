// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

var topLevel = "OtherLibrary";

class Superclass2 {
  var _instVar = 'Superclass2';
  var instVar = 'Superclass2';
  method() => 'Superclass2';
  static staticMethod() => 'Superclass2';
  suppress_warning() => _instVar;
}

class Superclass1 extends Superclass2 {
  var _instVar = 'Superclass1';
  var instVar = 'Superclass1';
  method() => 'Superclass1';
  static staticMethod() => 'Superclass1';

  test() {
    var _local = 'Superclass1';
    debugger();
    // Suppress unused variable warning.
    print(_local);
  }
}
