// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart._interceptors;

import 'dart:collection';
import 'dart:_internal' hide Symbol;
import 'dart:_js_helper';
import 'dart:_foreign_helper' show JS, JS_GET_FLAG, TYPE_REF;
import 'dart:math' show Random, ln2;
import 'dart:_rti' as rti show createRuntimeType, Rti;
import 'dart:_runtime' as dart;
import 'dart:_js_shared_embedded_names' show ARRAY_RTI_PROPERTY;

part 'js_array.dart';
part 'js_number.dart';
part 'js_string.dart';

// TODO(jmesserly): remove, this doesn't do anything for us.
abstract class Interceptor {
  const Interceptor();

  // Use native JS toString method instead of standard Dart Object.toString.
  String toString() => JS<String>('!', '#.toString()', this);
}

/// The interceptor class for [bool].
@JsPeerInterface(name: 'Boolean')
final class JSBool extends Interceptor implements bool, TrustedGetRuntimeType {
  const JSBool();

  // Note: if you change this, also change the function [S].
  @notNull
  String toString() => JS<String>('!', r'String(#)', this);

  // The values here are SMIs, co-prime and differ about half of the bit
  // positions, including the low bit, so they are different mod 2^k.
  @notNull
  int get hashCode => this ? (2 * 3 * 23 * 3761) : (269 * 811);

  @notNull
  bool operator &(@nullCheck bool other) =>
      JS<bool>('!', "# && #", other, this);

  @notNull
  bool operator |(@nullCheck bool other) =>
      JS<bool>('!', "# || #", other, this);

  @notNull
  bool operator ^(@nullCheck bool other) => !identical(this, other);

  Type get runtimeType => bool;
}

/// The supertype for JSString and JSArray. Used by the backend as to
/// have a type mask that contains the objects that we can use the
/// native JS [] operator and length on.
abstract class JSIndexable<E> {
  int get length;
  E operator [](int index);
}

/// The supertype for JSMutableArray and JavaScriptIndexingBehavior.
///
// TODO(nshahan) Use as a type mask that contains the objects we can use the JS
// []= operator on.
abstract class JSMutableIndexable<E> extends JSIndexable<E> {
  operator []=(int index, E value);
}

/// The interface implemented by JavaScript objects.
///
/// These are methods in addition to the regular Dart Object methods like
/// [Object.hashCode]. This is the type that should be exported by a JavaScript
/// interop library.
abstract class JSObject {}

/// Superclass of all interop objects and native types defined in the web
/// libraries.
///
/// This is the class @staticInterop classes erase to.
class JavaScriptObject extends Interceptor implements JSObject {
  const JavaScriptObject();
}

/// Interceptor base class for JavaScript objects not recognized as some more
/// specific native type.
///
/// Note that this used to be `JavaScriptObject`.
class LegacyJavaScriptObject extends JavaScriptObject {
  const LegacyJavaScriptObject();
}

/// Interceptor for plain JavaScript objects created as JavaScript object
/// literals or `new Object()`.
///
/// Note that this isn't being used today in ddc. Instead of using interceptors,
/// we have other type logic to distinguish JS types.
class PlainJavaScriptObject extends LegacyJavaScriptObject {
  const PlainJavaScriptObject();
}

/// Interceptor for unclassified JavaScript objects, typically objects with a
/// non-trivial prototype chain.
///
/// This class also serves as a fallback for unknown JavaScript exceptions.
/// Note that this isn't being used today in ddc. Instead of using interceptors,
/// we have other type logic to distinguish JS types.
class UnknownJavaScriptObject extends LegacyJavaScriptObject {
  const UnknownJavaScriptObject();
}

@JsPeerInterface(name: 'Error')
class NativeError extends JavaScriptObject {
  String dartStack() => JS<String>('!', '#.stack', this);
}

// Note that this needs to be in interceptors.dart in order for
// it to be picked up as an extension type.
@JsPeerInterface(name: 'TypeError')
class JSNoSuchMethodError extends NativeError implements NoSuchMethodError {
  static final _nullError = RegExp(r"^Cannot read property '(.+)' of null$");
  static final _notAFunction = RegExp(r"^(.+) is not a function$");
  static final _extensionName = RegExp(r"^Symbol\(dartx\.(.+)\)$");
  static final _privateName = RegExp(r"^Symbol\((_.+)\)$");

  String? _fieldName(String message) {
    RegExpMatch? match = _nullError.firstMatch(message);
    if (match == null) return null;
    String name = match[1]!;
    match = _extensionName.firstMatch(name) ?? _privateName.firstMatch(name);
    return match != null ? match[1] : name;
  }

  String? _functionCallTarget(String message) {
    var match = _notAFunction.firstMatch(message);
    return match != null ? match[1] : null;
  }

  String dartStack() {
    var stack = super.dartStack();
    // Strip TypeError from first line.
    stack = toString() + '\n' + stack.split('\n').sublist(1).join('\n');
    return stack;
  }

  StackTrace get stackTrace => dart.stackTrace(this);

  String toString() {
    String message = JS('!', '#.message', this);
    var callTarget = _functionCallTarget(message);
    if (callTarget != null) {
      return "NoSuchMethodError: tried to call a non-function, such as null: "
          "'$callTarget'";
    }
    // TODO(vsm): Distinguish between null reference errors and other
    // TypeErrors.  We should not get non-null TypeErrors from DDC code,
    // but we may from native JavaScript.
    var name = _fieldName(message);
    if (name == null) {
      // Not a Null NSM error: fallback to JS.
      return JS<String>('!', '#.toString()', this);
    }
    return "NoSuchMethodError: invalid member on null: '$name'";
  }
}

@JsPeerInterface(name: 'Function')
class JSFunction extends Interceptor {
  toString() {
    if (dart.isDartClass(this)) {
      // If the function is a Dart class, we should just display the class name.
      // Regular Dart code shouldn't be able to access these values to call
      // `.toString()` but they might be accessed through debugging tools.
      return 'Dart class: ${JS<String>('!', '#.name', this)}';
    }
    return JS<String>('!', r'"Closure: " + # + " from: " + #',
        dart.typeName(dart.getReifiedType(this)), this);
  }

  // TODO(nshahan): We can remove these if we canonicalize all tearoffs and no
  // longer support weak null safety "same type" equality.
  operator ==(other) {
    // Basic function values (no generics, no bound instances) are represented
    // as the original functions so reference equality is sufficient.
    if (JS<bool>('!', '# === #', this, other)) return true;

    dynamic boundObj;
    dynamic otherFn;
    var originalFn = JS('', '#._originalFn', this);

    if (originalFn == null) {
      // No generic instantiation present.
      boundObj = JS('', '#._boundObject', this);
      if (boundObj == null) return false;
      originalFn = this;
      otherFn = other;
    } else {
      // Generic instantiation was present.
      var typeArgs = JS('!', '#._typeArgs', this);
      var otherTypeArgs = JS('', '#._typeArgs', other);
      // Test if all instantiated type arguments are equal.
      if (JS_GET_FLAG('SOUND_NULL_SAFETY')) {
        // The list has been canonicalized on creation so reference equality
        // is sufficient.
        if (JS<bool>('!', '# !== #', typeArgs, otherTypeArgs)) return false;
      } else {
        // In weak null safety all types arguments must be compared in a way
        // that is agnostic to legacy.
        var typeArgCount = JS<int>('!', '#.length', typeArgs);
        if (JS<bool>('!', '!#', otherTypeArgs) ||
            typeArgCount != JS('', '#.length', otherTypeArgs)) {
          return false;
        }
        for (var i = 0; i < typeArgCount; i++) {
          var typeArg = JS<rti.Rti>('!', '#[#]', typeArgs, i);
          var otherTypeArg = JS<rti.Rti>('!', '#[#]', otherTypeArgs, i);
          if (JS_GET_FLAG('SOUND_NULL_SAFETY')) {
            if (typeArg != otherTypeArg) return false;
          } else {
            if (rti.Rti.getLegacyErasedRecipe(typeArg) !=
                rti.Rti.getLegacyErasedRecipe(otherTypeArg)) {
              return false;
            }
          }
        }
      }
      boundObj = JS('', '#._boundObject', originalFn);
      otherFn = JS('', '#._originalFn', other);
      if (boundObj == null) {
        // This isn't an instance tearoff, test if the original uninstantiated
        // methods are equal.
        return JS<bool>('!', '# === #', originalFn, otherFn);
      }
    }
    // This is an instance tearoff, test if the bound instances and methods
    // are equal.
    return JS<bool>(
        '!',
        '# === #._boundObject && #._boundMethod === #._boundMethod',
        boundObj,
        otherFn,
        originalFn,
        otherFn);
  }

  get hashCode {
    var boundObj = JS<Object?>('', '#._boundObject', this);
    if (boundObj == null) return identityHashCode(this);

    var boundMethod = JS<Object>('!', '#._boundMethod', this);
    int hash = (17 * 31 + boundObj.hashCode) & 0x1fffffff;
    return (hash * 31 + identityHashCode(boundMethod)) & 0x1fffffff;
  }

  Type get runtimeType =>
      rti.createRuntimeType(JS<rti.Rti>('!', '#', dart.getReifiedType(this)));
}

/// A class used for implementing `null` tear-offs.
class JSNull {
  toString() => 'null';
  noSuchMethod(Invocation i) => dart.defaultNoSuchMethod(null, i);
}

final Object jsNull = JSNull();

// Note that this needs to be in interceptors.dart in order for
// it to be picked up as an extension type.
@JsPeerInterface(name: 'RangeError')
class JSRangeError extends JavaScriptObject implements ArgumentError {
  StackTrace get stackTrace => dart.stackTrace(this);

  get invalidValue => null;
  get name => null;
  get message => JS<String>('!', '#.message', this);

  String toString() => "Invalid argument: $message";
}

// Obsolete in dart dev compiler. Added only so that the same version of
// dart:html can be used in dart2js an dev compiler.
// Warning: calls to these methods need to be removed before custom elements
// and cross-frame dom objects behave correctly in ddc.
// See https://github.com/dart-lang/sdk/issues/28326
findInterceptorConstructorForType(Type? type) {}
findConstructorForNativeSubclassType(Type? type, String name) {}
getNativeInterceptor(object) {}
setDispatchProperty(object, value) {}

// Added to allow dart2js and dartdevc to share tests
// TODO(sigmund): revisit whether this method is still needed after reorganizing
// all web tests.
findInterceptorForType(Type? type) {}

/// Interceptor class for JavaScript function objects and Dart functions that
/// have been converted to JavaScript functions.
///
/// A reference to this class is only used by `getInterceptor()` to return to
/// the dart:rti library because stores information used for type checks.
class JavaScriptFunction extends LegacyJavaScriptObject implements Function {}

/// Interceptor for JavaScript BigInt primitive values, i.e. values `x` for
/// which `typeof x == "bigint"`.
@JsPeerInterface(name: 'BigInt')
final class JavaScriptBigInt extends Interceptor {
  const JavaScriptBigInt();

  // JavaScript BigInt objects don't have any operations that look efficient
  // enough to generate a good hash code.
  //
  // TODO(https://dartbug.com/53162): "bigint" primitive values might be used as
  // keys without using the `hashCode`, but that will not help for compound hash
  // values, e.g. produced by `Object.hash`.
  int get hashCode => 0;

  /// Returns the result of the JavaScript BigInt's `toString` method.
  String toString() => JS('String', 'String(#)', this);
}

/// Interceptor for JavaScript Symbol primitive values, i.e. values `x` for
/// which `typeof x == "symbol"`.
@JsPeerInterface(name: 'Symbol')
final class JavaScriptSymbol extends Interceptor {
  const JavaScriptSymbol();

  // It is not clear what to do for a Symbol's hashCode.  Registered Symbols
  // [can't be keys of WeakMaps][1].  Using a property won't work because the
  // property will be added to the ephmeral Object wrapper, either being an
  // incorrect operation or an error in strict mode.
  //
  // TODO(https://dartbug.com/53162): "symbol" primitive values might be used as
  // keys without using the `hashCode`, but that will not help for compound hash
  // values, e.g. produced by `Object.hash`.
  //
  // [1]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Symbol#shared_symbols_in_the_global_symbol_registry
  int get hashCode => 0;

  /// Returns the result of the JavaScript Symbol's `toString` method.
  String toString() => JS('String', 'String(#)', this);
}
