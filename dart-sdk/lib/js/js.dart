// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Low-level support for interoperating with JavaScript.
///
/// > [!Note]
/// > You should usually use `dart:js_interop` instead of this library.
/// > To learn more, check out the
/// > [JS interop documentation](https://dart.dev/interop/js-interop).
///
/// This library provides access to JavaScript objects from Dart, allowing
/// Dart code to get and set properties, and call methods of JavaScript objects
/// and invoke JavaScript functions. The library takes care of converting
/// between Dart and JavaScript objects where possible, or providing proxies if
/// conversion isn't possible.
///
/// This library does not make Dart objects usable from JavaScript, their
/// methods and properties are not accessible, though it does allow Dart
/// functions to be passed into and called from JavaScript.
///
/// [JsObject] is the core type and represents a proxy of a JavaScript object.
/// JsObject gives access to the underlying JavaScript objects properties and
/// methods. `JsObject`s can be acquired by calls to JavaScript, or they can be
/// created from proxies to JavaScript constructors.
///
/// The top-level getter [context] provides a [JsObject] that represents the
/// global object in JavaScript, usually `window`.
///
/// The following example shows an alert dialog via a JavaScript call to the
/// global function `alert()`:
///
///     import 'dart:js';
///
///     main() => context.callMethod('alert', ['Hello from Dart!']);
///
/// This example shows how to create a [JsObject] from a JavaScript constructor
/// and access its properties:
///
///     import 'dart:js';
///
///     main() {
///       var object = JsObject(context['Object']);
///       object['greeting'] = 'Hello';
///       object['greet'] = (name) => "${object['greeting']} $name";
///       var message = object.callMethod('greet', ['JavaScript']);
///       context['console'].callMethod('log', [message]);
///     }
///
/// ## Proxying and automatic conversion
///
/// When setting properties on a JsObject or passing arguments to a JavaScript
/// method or function, Dart objects are automatically converted or proxied to
/// JavaScript objects. When accessing JavaScript properties, or when a Dart
/// closure is invoked from JavaScript, the JavaScript objects are also
/// converted to Dart.
///
/// Functions and closures are proxied in such a way that they are callable. A
/// Dart closure assigned to a JavaScript property is proxied by a function in
/// JavaScript. A JavaScript function accessed from Dart is proxied by a
/// [JsFunction], which has a [JsFunction.apply] method to invoke it.
///
/// The following types are transferred directly and not proxied:
///
///   * Basic types: `null`, `bool`, `num`, `String`, `DateTime`
///   * `TypedData`, including its subclasses like `Int32List`, but _not_
///     `ByteBuffer`
///   * When compiling for the web, also: `Blob`, `Event`, `ImageData`,
///     `KeyRange`, `Node`, and `Window`.
///
/// ## Converting collections with JsObject.jsify()
///
/// To create a JavaScript collection from a Dart collection use the
/// [JsObject.jsify] constructor, which converts Dart [Map]s and [Iterable]s
/// into JavaScript Objects and Arrays.
///
/// The following expression creates a new JavaScript object with the properties
/// `a` and `b` defined:
///
///     var jsMap = JsObject.jsify({'a': 1, 'b': 2});
///
/// This expression creates a JavaScript array:
///
///     var jsArray = JsObject.jsify([1, 2, 3]);
///
/// {@category Web (Legacy)}
library dart.js;

import 'dart:collection' show ListMixin;

export 'dart:js_util' show allowInterop, allowInteropCaptureThis;

/// The JavaScript global object, usually `window`.
external JsObject get context;

/// A proxy on a JavaScript object.
///
/// The properties of the JavaScript object are accessible via the `[]` and
/// `[]=` operators. Methods are callable via [callMethod].
class JsObject {
  /// Constructs a JavaScript object from its native [constructor] and returns
  /// a proxy to it.
  external factory JsObject(JsFunction constructor, [List? arguments]);

  /// Constructs a [JsObject] that proxies a native Dart object; _for expert use
  /// only_.
  ///
  /// Use this constructor only if you wish to get access to JavaScript
  /// properties attached to a browser host object, such as a Node or Blob, that
  /// is normally automatically converted into a native Dart object.
  ///
  /// An exception will be thrown if [object] has the type
  /// `bool`, `num`, or `String`.
  external factory JsObject.fromBrowserObject(Object object);

  /// Recursively converts a JSON-like collection of Dart objects to a
  /// collection of JavaScript objects and returns a [JsObject] proxy to it.
  ///
  /// [object] must be a [Map] or [Iterable], the contents of which are also
  /// converted. Maps and Iterables are copied to a new JavaScript object.
  /// Primitives and other transferable values are directly converted to their
  /// JavaScript type, and all other objects are proxied.
  external factory JsObject.jsify(Object object);

  /// Returns the value associated with [property] from the proxied JavaScript
  /// object.
  ///
  /// The type of [property] must be either [String] or [num].
  external dynamic operator [](Object property);

  // Sets the value associated with [property] on the proxied JavaScript
  // object.
  //
  // The type of [property] must be either [String] or [num].
  external void operator []=(Object property, Object? value);

  int get hashCode => 0;

  external bool operator ==(Object other);

  /// Returns `true` if the JavaScript object contains the specified property
  /// either directly or though its prototype chain.
  ///
  /// This is the equivalent of the `in` operator in JavaScript.
  external bool hasProperty(Object property);

  /// Removes [property] from the JavaScript object.
  ///
  /// This is the equivalent of the `delete` operator in JavaScript.
  external void deleteProperty(Object property);

  /// Returns `true` if the JavaScript object has [type] in its prototype chain.
  ///
  /// This is the equivalent of the `instanceof` operator in JavaScript.
  external bool instanceof(JsFunction type);

  /// Returns the result of the JavaScript objects `toString` method.
  external String toString();

  /// Calls [method] on the JavaScript object with the arguments [args] and
  /// returns the result.
  ///
  /// The type of [method] must be either [String] or [num].
  external dynamic callMethod(Object method, [List? args]);
}

/// A proxy on a JavaScript Function object.
class JsFunction extends JsObject {
  /// Returns a [JsFunction] that captures its 'this' binding and calls [f]
  /// with the value of JavaScript `this` passed as the first argument.
  external factory JsFunction.withThis(Function f);

  /// Invokes the JavaScript function with arguments [args]. If [thisArg] is
  /// supplied it is the value of `this` for the invocation.
  external dynamic apply(List args, {thisArg});
}

/// A [List] that proxies a JavaScript array.
class JsArray<E> extends JsObject with ListMixin<E> {
  /// Creates an empty JavaScript array.
  external factory JsArray();

  /// Creates a new JavaScript array and initializes it to the contents of
  /// [other].
  external factory JsArray.from(Iterable<E> other);

  // Methods required by ListMixin

  external E operator [](Object index);

  external void operator []=(Object index, E value);

  external int get length;

  external void set length(int length);

  // Methods overridden for better performance

  external void add(E value);

  external void addAll(Iterable<E> iterable);

  external void insert(int index, E element);

  external E removeAt(int index);

  external E removeLast();

  external void removeRange(int start, int end);

  external void setRange(int start, int end, Iterable<E> iterable,
      [int skipCount = 0]);

  external void sort([int compare(E a, E b)?]);
}
