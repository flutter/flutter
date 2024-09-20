// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// dart2js "primitives", that is, features that cannot be implemented without
/// access to JavaScript features.
library dart2js._js_primitives;

import 'dart:_foreign_helper' show JS;

/// This is the low-level method that is used to implement [print].  It is
/// possible to override this function from JavaScript by defining a function in
/// JavaScript called "dartPrint".
///
/// Notice that it is also possible to intercept calls to [print] from within a
/// Dart program using zones. This means that there is no guarantee that a call
/// to print ends in this method.
void printString(String string) {
  if (JS('bool', r'typeof dartPrint == "function"')) {
    // Support overriding print from JavaScript.
    JS('void', r'dartPrint(#)', string);
    return;
  }

  // Inside browser or nodejs.
  if (JS('bool', r'typeof console == "object"') &&
      JS('bool', r'typeof console.log != "undefined"')) {
    JS('void', r'console.log(#)', string);
    return;
  }

  // Running in d8, the V8 developer shell, or in Firefox' js-shell.
  if (JS('bool', r'typeof print == "function"')) {
    JS('void', r'print(#)', string);
    return;
  }

  // This is somewhat nasty, but we don't want to drag in a bunch of
  // dependencies to handle a situation that cannot happen. So we
  // avoid using Dart [:throw:] and Dart [toString].
  JS('void', 'throw "Unable to print message: " + String(#)', string);
}
