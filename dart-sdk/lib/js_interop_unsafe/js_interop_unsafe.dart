// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Utility methods to manipulate JavaScript objects dynamically.
///
/// This library is typically meant to be used when the names of properties or
/// methods are not known statically. This library is similar to `dart:js_util`,
/// except the methods here are extension methods that use JS types. This
/// allows code using these functions to also be compiled to WebAssembly.
///
/// In general, prefer to write JS interop interfaces and external static
/// interop members using `dart:js_interop`. This library is meant to work
/// around issues and help with migration from older JS interop libraries.
///
/// > [!NOTE]
/// > As the name suggests, usage of this library *can* be unsafe. This means
/// > that safe usage of these methods cannot necessarily be verified
/// > statically. Prefer using statically analyzable values like constants or
/// > literals for property or method names so that usage can be verified. This
/// > library should be used cautiously and only when the same effect cannot be
/// > achieved with static interop.
///
/// {@category Web}
library;

import 'dart:js_interop';

/// Utility methods to check, get, set, and call properties on a [JSObject].
///
/// See the [JavaScript specification](https://tc39.es/ecma262/#sec-object-type)
/// for more details on using properties.
extension JSObjectUnsafeUtilExtension on JSObject {
  /// Shorthand helper for [hasProperty] to check whether this [JSObject]
  /// contains the property key [property], but takes and returns a Dart value.
  bool has(String property) => hasProperty(property.toJS).toDart;

  /// Whether or not this [JSObject] contains the property key [property].
  external JSBoolean hasProperty(JSAny property);

  /// Shorthand helper for [getProperty] to get the value of the property key
  /// [property] of this [JSObject], but takes and returns a Dart value.
  JSAny? operator [](String property) => getProperty(property.toJS);

  /// The value of the property key [property] of this [JSObject].
  external R getProperty<R extends JSAny?>(JSAny property);

  /// Shorthand helper for [setProperty] to write the [value] of the property
  /// key [property] of this [JSObject], but takes a Dart value.
  void operator []=(String property, JSAny? value) =>
      setProperty(property.toJS, value);

  /// Write the [value] of property key [property] of this [JSObject].
  external void setProperty(JSAny property, JSAny? value);

  external JSAny? _callMethod(JSAny method,
      [JSAny? arg1, JSAny? arg2, JSAny? arg3, JSAny? arg4]);

  /// Calls [method] on this [JSObject] with up to four arguments.
  ///
  /// Returns the result of calling [method], which must be an [R].
  ///
  /// This helper doesn't allow passing nulls, as it determines whether an
  /// argument is passed based on whether it was null or not. Prefer
  /// [callMethodVarArgs] if you need to pass nulls.
  R callMethod<R extends JSAny?>(JSAny method,
          [JSAny? arg1, JSAny? arg2, JSAny? arg3, JSAny? arg4]) =>
      _callMethod(method, arg1, arg2, arg3, arg4) as R;

  external JSAny? _callMethodVarArgs(JSAny method, [List<JSAny?>? arguments]);

  /// Calls [method] on this [JSObject] with a variable number of [arguments].
  ///
  /// Returns the result of calling [method], which must be an [R].
  R callMethodVarArgs<R extends JSAny?>(JSAny method,
          [List<JSAny?>? arguments]) =>
      _callMethodVarArgs(method, arguments) as R;

  /// Deletes the property with key [property] from this [JSObject].
  external JSBoolean delete(JSAny property);
}

/// Utility methods to call [JSFunction]s as constructors.
extension JSFunctionUnsafeUtilExtension on JSFunction {
  external JSObject _callAsConstructor(
      [JSAny? arg1, JSAny? arg2, JSAny? arg3, JSAny? arg4]);

  /// Calls this [JSFunction] as a constructor with up to four arguments.
  ///
  /// Returns the constructed object, which must be an [R].
  ///
  /// This helper doesn't allow passing nulls, as it determines whether an
  /// argument is passed based on whether it was null or not. Prefer
  /// [callAsConstructorVarArgs] if you need to pass nulls.
  // TODO(srujzs): The type bound should extend `JSObject`.
  R callAsConstructor<R>(
          [JSAny? arg1, JSAny? arg2, JSAny? arg3, JSAny? arg4]) =>
      _callAsConstructor(arg1, arg2, arg3, arg4) as R;

  external JSObject _callAsConstructorVarArgs([List<JSAny?>? arguments]);

  /// Calls this [JSFunction] as a constructor with a variable number of
  /// arguments.
  ///
  /// Returns the constructed [JSObject], which must be an [R].
  R callAsConstructorVarArgs<R extends JSObject>([List<JSAny?>? arguments]) =>
      _callAsConstructorVarArgs(arguments) as R;
}
