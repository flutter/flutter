// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._js_helper;

// Obsolete in dart dev compiler. Added only so that the same version of
// dart:html can be used in dart2js an dev compiler.
F convertDartClosureToJS<F>(F closure, int arity) {
  return closure;
}

// Warning: calls to these methods need to be removed before custom elements
// and cross-frame dom objects behave correctly in ddc
// https://github.com/dart-lang/sdk/issues/28326
setNativeSubclassDispatchRecord(proto, interceptor) {}
findDispatchTagForInterceptorClass(interceptorClassConstructor) {}
makeLeafDispatchRecord(interceptor) {}
