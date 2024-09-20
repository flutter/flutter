// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal' show patch;
import 'dart:_foreign_helper' show JS;
import 'dart:js_interop' hide JS;
import 'dart:js_util' as js_util;

@patch
extension JSObjectUnsafeUtilExtension on JSObject {
  @patch
  @pragma('dart2js:prefer-inline')
  JSBoolean hasProperty(JSAny property) =>
      JS<bool>('bool', '# in #', property, this).toJS;

  @patch
  @pragma('dart2js:prefer-inline')
  T getProperty<T extends JSAny?>(JSAny property) =>
      JS<dynamic>('Object|Null', '#[#]', this, property);

  @patch
  @pragma('dart2js:prefer-inline')
  void setProperty(JSAny property, JSAny? value) =>
      JS<void>('', '#[#] = #', this, property, value);

  @patch
  @pragma('dart2js:prefer-inline')
  JSAny? _callMethod(JSAny method,
      [JSAny? arg1, JSAny? arg2, JSAny? arg3, JSAny? arg4]) {
    if (arg1 == null) {
      return JS<dynamic>('Object|Null', '#[#]()', this, method);
    } else if (arg2 == null) {
      return JS<dynamic>('Object|Null', '#[#](#)', this, method, arg1);
    } else if (arg3 == null) {
      return JS<dynamic>('Object|Null', '#[#](#, #)', this, method, arg1, arg2);
    } else if (arg4 == null) {
      return JS<dynamic>(
          'Object|Null', '#[#](#, #, #)', this, method, arg1, arg2, arg3);
    } else {
      return JS<dynamic>('Object|Null', '#[#](#, #, #, #)', this, method, arg1,
          arg2, arg3, arg4);
    }
  }

  @patch
  @pragma('dart2js:prefer-inline')
  JSAny? _callMethodVarArgs(JSAny method, [List<JSAny?>? arguments]) =>
      JS<dynamic>(
          'Object|Null', '#[#].apply(#, #)', this, method, this, arguments);

  @patch
  @pragma('dart2js:prefer-inline')
  JSBoolean delete(JSAny property) =>
      JS<bool>('bool', 'delete #[#]', this, property).toJS;
}

@patch
extension JSFunctionUnsafeUtilExtension on JSFunction {
  // TODO(joshualitt): Specialize `callAsConstructor`.
  @patch
  @pragma('dart2js:prefer-inline')
  JSObject _callAsConstructor(
          [JSAny? arg1, JSAny? arg2, JSAny? arg3, JSAny? arg4]) =>
      js_util.callConstructor<JSObject>(
          this,
          arg1 == null
              ? null
              : [
                  arg1,
                  if (arg2 != null) arg2,
                  if (arg3 != null) arg3,
                  if (arg4 != null) arg4,
                ]);

  @patch
  @pragma('dart2js:prefer-inline')
  JSObject _callAsConstructorVarArgs([List<JSAny?>? arguments]) =>
      js_util.callConstructor<JSObject>(this, arguments);
}
