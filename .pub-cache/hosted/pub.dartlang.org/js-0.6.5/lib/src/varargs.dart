// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Declarations for variable arguments support
/// (rest params and spread operator).
///
/// These are currently *not* supported by dart2js or Dartium.
library js.varargs;

class _Rest {
  const _Rest();
}

/// Annotation to tag ES6 rest parameters (https://goo.gl/r0bJ1K).
///
/// This is *not* supported by dart2js or Dartium (yet).
///
/// This is meant to be used by the Dart Dev Compiler
/// when compiling helper functions of its runtime to ES6.
///
/// The following function:
///
///     foo(a, b, @rest others) { ... }
///
/// Will be compiled to ES6 code like the following:
///
///     function foo(a, b, ...others) { ... }
///
/// Which is roughly equivalent to the following ES5 code:
///
///     function foo(a, b/*, ...others*/) {
///       var others = [].splice.call(arguments, 2);
///       ...
///     }
///
const _Rest rest = _Rest();

/// Intrinsic function that maps to the ES6 spread operator
/// (https://goo.gl/NedHKr).
///
/// This is *not* supported by dart2js or Dartium (yet),
/// and *cannot* be called at runtime.
///
/// This is meant to be used by the Dart Dev Compiler when
/// compiling its runtime to ES6.
///
/// The following expression:
///
///     foo(a, b, spread(others))
///
/// Will be compiled to ES6 code like the following:
///
///     foo(a, b, ...others)
///
/// Which is roughly equivalent to the following ES5 code:
///
///     foo.apply(null, [a, b].concat(others))
///
dynamic spread(args) {
  throw StateError('The spread function cannot be called, '
      'it should be compiled away.');
}
