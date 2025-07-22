// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import "dart:_js_helper"
    show
        JS,
        JSAnyToExternRef,
        jsStringFromDartString,
        jsUint8ArrayFromDartUint8List;
import "dart:_js_types" show JSStringImpl;
import 'dart:_string';
import 'dart:js_interop'
    show
        ByteBufferToJSArrayBuffer,
        JSArray,
        JSFunction,
        JSFunctionUtilExtension,
        JSString,
        JSArrayToList,
        JSStringToString,
        JSPromise,
        JSPromiseToFuture,
        StringToJSString;
import 'dart:_js_helper' show dartifyRaw, JSValue;
import 'dart:_js_types';
import 'dart:_wasm';
import 'dart:math';
import 'dart:typed_data' show Uint8List;

part "class_id.dart";
part "deferred.dart";
part "dynamic_module.dart";
part "print_patch.dart";
part "symbol_patch.dart";

// Compilation to Wasm is always fully null safe.
@patch
bool typeAcceptsNull<T>() => null is T;

const bool has63BitSmis = false;

class Lists {
  static void copy(List src, int srcStart, List dst, int dstStart, int count) {
    if (srcStart + count > src.length) {
      throw IterableElementError.tooFew();
    }

    // TODO(askesc): Intrinsify for efficient copying
    if (srcStart < dstStart) {
      for (
        int i = srcStart + count - 1, j = dstStart + count - 1;
        i >= srcStart;
        i--, j--
      ) {
        dst[j] = src[i];
      }
    } else {
      for (int i = srcStart, j = dstStart; i < srcStart + count; i++, j++) {
        dst[j] = src[i];
      }
    }
  }
}

// Base class for any wasm-backed typed data implementation class.
abstract class WasmTypedDataBase {}

// This function can be used to skip implicit or explicit checked down casts in
// the parts of the core library implementation where we know by construction
// the type of a value.
//
// Important: this is unsafe and must be used with care.
@patch
@pragma("wasm:intrinsic")
external T unsafeCast<T>(Object? v);

// A version of [unsafeCast] that is opaque to the TFA. The TFA knows about the
// [unsafeCast] function and will sharpen the result type with the inferred type
// of the input. When such sharpening is undesirable, this function should be
// used. One such situation is when either the source or destination type is not
// an ordinary Dart type, for instance if it is one of the special Wasm types
// from wasm_types.dart.
@pragma("wasm:intrinsic")
external T unsafeCastOpaque<T>(Object? v);

// This function can be used to keep an object alive till that point.
void reachabilityFence(Object? object) {}

// Used for exporting wasm functions that are annotated via
// `@pragma('wasm:weak-export', '<name>')
@pragma("wasm:intrinsic")
external void exportWasmFunction(Function object);

// This function can be used to encode native side effects.
@pragma("wasm:intrinsic")
external void _nativeEffect(Object object);

// Thomas Wang 64-bit mix.
// https://gist.github.com/badboy/6267743
int mix64(int n) {
  n = (~n) + (n << 21); // n = (n << 21) - n - 1;
  n = n ^ (n >>> 24);
  n = n * 265; // n = (n + (n << 3)) + (n << 8);
  n = n ^ (n >>> 14);
  n = n * 21; // n = (n + (n << 2)) + (n << 4);
  n = n ^ (n >>> 28);
  n = n + (n << 31);
  return n;
}

@pragma("wasm:intrinsic")
external int floatToIntBits(double value);
@pragma("wasm:intrinsic")
external double intBitsToFloat(int value);
@pragma("wasm:intrinsic")
external int doubleToIntBits(double value);
@pragma("wasm:intrinsic")
external double intBitsToDouble(int value);

// Will be patched in `pkg/dart2wasm/lib/compile.dart` right before TFA.
external void Function()? get mainTearOffArg0;
external void Function(List<String>)? get mainTearOffArg1;
external void Function(List<String>, Null)? get mainTearOffArg2;

/// Used to invoke the `main` function from JS, printing any exceptions that
/// escape.
@pragma("wasm:export", "\$invokeMain")
void _invokeMain(WasmExternRef jsArrayRef) {
  try {
    // We will only compile one of these cases, the remaining cases will be
    // eliminated by the compiler.
    if (mainTearOffArg0 case final mainMethod?) {
      mainMethod();
      return;
    }
    if (mainTearOffArg1 case final mainMethod?) {
      final jsArray = (JSValue(jsArrayRef) as JSArray<JSString>).toDart;
      final args = <String>[for (final jsValue in jsArray) jsValue.toDart];
      mainMethod(List.unmodifiable(args));
      return;
    }
    if (mainTearOffArg2 case final mainMethod?) {
      final jsArray = (JSValue(jsArrayRef) as JSArray<JSString>).toDart;
      final args = <String>[for (final jsValue in jsArray) jsValue.toDart];
      mainMethod(List.unmodifiable(args), null);
      return;
    }
    throw "Could not call main";
  } catch (e, s) {
    print(e);
    print(s);
    rethrow;
  }
}

String jsonEncode(String object) => JSStringImpl(
  JS<WasmExternRef>(
    "s => JSON.stringify(s)",
    jsStringFromDartString(object).toExternRef,
  ),
);

/// Whether to check bounds in [IndexErrorUtils.checkIndex],
/// which are  used in list and typed data implementations.
///
/// Bounds checks are disabled with `--omit-bounds-checks`, which is implied by
/// `-O4`.
///
/// Reads of this variable are evaluated before the TFA by the constant
/// evaluator, and its value depends on `--omit-bounds-checks`.
external bool get checkBounds;

/// Whether minification mode is on.
///
/// If minification is on we do not retain specific error message details (e.g.
/// omit the index in index errors).
///
/// Reads of this variable are evaluated before the TFA by the constant
/// evaluator, and its value depends on `--minify`.
external bool get minify;

/// Whether dynamic module support is enabled for this build.
///
/// Enables shortcuts in some runtime logic if it is known that no support is
/// needed for dynamic modules.
///
/// Reads of this variable are evaluated before the TFA by the constant
/// evaluator, and its value depends on `--dynamic-module-main`.
external bool get hasDynamicModuleSupport;

/// Whether deferred loading is enabled.
///
/// If true, then there may be deferred modules that can be loaded at runtime.
///
/// Reads of this variable are evaluated before the TFA by the constant
/// evaluator, and its value depends on `--enable-deferred-loading` and
/// `--enable-multi-module-stress-test-mode`.
external bool get deferredLoadingEnabled;

/// Compiler intrinsic to push an element to a Wasm array in a class field or
/// variable.
///
/// The `array` and `length` arguments need to be `InstanceGet`s (e.g. `this.x`)
/// or `VariableGet`s (e.g. `x`). This function will update the class field
/// (when the argument is `InstanceGet`) or the variable (when the argument is
/// `InstanceGet`).
///
/// `elem` is the element to be pushed onto the array and can have any shape.
///
/// `nextCapacity` is the capacity to be used when growing the array. It can
/// have any shape, and it will be evaluated only when the array is full.
external void pushWasmArray<T>(
  WasmArray<T> array,
  int length,
  T elem,
  int nextCapacity,
);

/// Similar to `pushWasmArray`, but for popping.
///
/// Note that when [T] is not nullable, this does not clear the popped element
/// slot in the array, which may cause memory leaks. Callers should manually
/// clear non-nullable reference element slots in the array when popping.
external T popWasmArray<T>(WasmArray<T> array, int length);
