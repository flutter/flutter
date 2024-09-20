// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

/// Foreign Function Interface for interoperability with the C programming language.
///
/// For further details, please see: https://dart.dev/server/c-interop.
///
/// {@category VM}
@Since('2.6')
library dart.ffi;

import 'dart:_internal' show Since;
import 'dart:isolate';
import 'dart:typed_data';

part 'abi.dart';
part 'abi_specific.dart';
part 'native_type.dart';
part 'native_finalizer.dart';
part 'allocation.dart';
part 'annotations.dart';
part 'c_type.dart';
part 'dynamic_library.dart';
part 'struct.dart';
part 'union.dart';

/// Number of bytes used by native type T.
///
/// Includes padding and alignment of structs.
///
/// This function must be invoked with a compile-time constant [T].
external int sizeOf<T extends SizedNativeType>();

/// Represents a pointer into the native C memory corresponding to 'NULL', e.g.
/// a pointer with address 0.
final Pointer<Never> nullptr = Pointer.fromAddress(0);

/// Represents a pointer into the native C memory. Cannot be extended.
@pragma('vm:entry-point')
@pragma("wasm:entry-point")
final class Pointer<T extends NativeType> implements SizedNativeType {
  /// Construction from raw integer.
  external factory Pointer.fromAddress(int ptr);

  /// Convert Dart function to a C function pointer, automatically marshalling
  /// the arguments and return value
  ///
  /// If an exception is thrown while calling `f()`, the native function will
  /// return `exceptionalReturn`, which must be assignable to return type of `f`.
  ///
  /// The returned function address can only be invoked on the mutator (main)
  /// thread of the current isolate. It will abort the process if invoked on any
  /// other thread. Use [NativeCallable.listener] to create callbacks that can
  /// be invoked from any thread.
  ///
  /// The pointer returned will remain alive for the duration of the current
  /// isolate's lifetime. After the isolate it was created in is terminated,
  /// invoking it from native code will cause undefined behavior.
  ///
  /// [Pointer.fromFunction] only accepts static or top level functions. Use
  /// [NativeCallable.isolateLocal] to create callbacks from any Dart function
  /// or closure.
  external static Pointer<NativeFunction<T>> fromFunction<T extends Function>(
      @DartRepresentationOf('T') Function f,
      [Object? exceptionalReturn]);

  /// Access to the raw pointer value.
  /// On 32-bit systems, the upper 32-bits of the result are 0.
  external int get address;

  /// Cast Pointer<T> to a Pointer<U>.
  external Pointer<U> cast<U extends NativeType>();

  /// Equality for Pointers only depends on their address.
  bool operator ==(Object other) {
    if (other is! Pointer) return false;
    Pointer otherPointer = other;
    return address == otherPointer.address;
  }

  /// The hash code for a Pointer only depends on its address.
  int get hashCode {
    return address.hashCode;
  }
}

/// A fixed-sized array of [T]s.
@Since('2.13')
final class Array<T extends NativeType> extends _Compound {
  /// Const constructor to specify [Array] dimensions in [Struct]s.
  ///
  /// ```dart
  /// final class MyStruct extends Struct {
  ///   @Array(8)
  ///   external Array<Uint8> inlineArray;
  ///
  ///   @Array(2, 2, 2)
  ///   external Array<Array<Array<Uint8>>> threeDimensionalInlineArray;
  /// }
  /// ```
  ///
  /// Do not invoke in normal code.
  const factory Array(int dimension1,
      [int dimension2,
      int dimension3,
      int dimension4,
      int dimension5]) = _ArraySize<T>;

  /// Const constructor to specify [Array] dimensions in [Struct]s.
  ///
  /// ```dart
  /// final class MyStruct extends Struct {
  ///   @Array.multi([2, 2, 2])
  ///   external Array<Array<Array<Uint8>>> threeDimensionalInlineArray;
  ///
  ///   @Array.multi([2, 2, 2, 2, 2, 2, 2, 2])
  ///   external Array<Array<Array<Array<Array<Array<Array<Array<Uint8>>>>>>>> eightDimensionalInlineArray;
  /// }
  /// ```
  ///
  /// Do not invoke in normal code.
  const factory Array.multi(List<int> dimensions) = _ArraySize<T>.multi;
}

final class _ArraySize<T extends NativeType> implements Array<T> {
  final int? dimension1;
  final int? dimension2;
  final int? dimension3;
  final int? dimension4;
  final int? dimension5;

  final List<int>? dimensions;

  const _ArraySize(this.dimension1,
      [this.dimension2, this.dimension3, this.dimension4, this.dimension5])
      : dimensions = null;

  const _ArraySize.multi(this.dimensions)
      : dimension1 = null,
        dimension2 = null,
        dimension3 = null,
        dimension4 = null,
        dimension5 = null;
}

/// Extension on [Pointer] specialized for the type argument [NativeFunction].
extension NativeFunctionPointer<NF extends Function>
    on Pointer<NativeFunction<NF>> {
  /// Convert to Dart function, automatically marshalling the arguments and
  /// return value.
  ///
  /// [isLeaf] specifies whether the function is a leaf function. Leaf functions
  /// are small, short-running, non-blocking functions which are not allowed to
  /// call back into Dart or use any Dart VM APIs. Leaf functions are invoked
  /// bypassing some of the heavier parts of the standard Dart-to-Native calling
  /// sequence which reduces the invocation overhead, making leaf calls faster
  /// than non-leaf calls. However, this implies that a thread executing a leaf
  /// function can't cooperate with the Dart runtime. A long running or blocking
  /// leaf function will delay any operation which requires synchronization
  /// between all threads associated with an isolate group until after the leaf
  /// function returns. For example, if one isolate in a group is trying to
  /// perform a GC and a second isolate is blocked in a leaf call, then the
  /// first isolate will have to pause and wait until this leaf call returns.
  external DF asFunction<@DartRepresentationOf('NF') DF extends Function>(
      {bool isLeaf = false});
}

/// A native callable which listens for calls to a native function.
///
/// Creates a native function linked to a Dart function, so that calling the
/// native function will call the Dart function in some way, with the arguments
/// converted to Dart values.
@Since('3.1')
abstract final class NativeCallable<T extends Function> {
  /// Constructs a [NativeCallable] that must be invoked from the same thread
  /// that created it.
  ///
  /// If an exception is thrown by the [callback], the native function will
  /// return the `exceptionalReturn`, which must be assignable to the return
  /// type of the [callback].
  ///
  /// The returned function address can only be invoked on the mutator (main)
  /// thread of the current isolate. It will abort the process if invoked on any
  /// other thread. Use [NativeCallable.listener] to create callbacks that can
  /// be invoked from any thread.
  ///
  /// Unlike [Pointer.fromFunction], [NativeCallable]s can be constructed from
  /// any Dart function or closure, not just static or top level functions.
  ///
  /// This callback must be [close]d when it is no longer needed. The [Isolate]
  /// that created the callback will be kept alive until [close] is called.
  /// After [NativeCallable.close] is called, invoking the [nativeFunction] from
  /// native code will cause undefined behavior.
  factory NativeCallable.isolateLocal(
      @DartRepresentationOf("T") Function callback,
      {Object? exceptionalReturn}) {
    throw UnsupportedError("NativeCallable cannot be constructed dynamically.");
  }

  /// Constructs a [NativeCallable] that can be invoked from any thread.
  ///
  /// When the native code invokes the function [nativeFunction], the arguments
  /// will be sent over a [SendPort] to the [Isolate] that created the
  /// [NativeCallable], and the callback will be invoked.
  ///
  /// The native code does not wait for a response from the callback, so only
  /// functions returning void are supported.
  ///
  /// The callback will be invoked at some time in the future. The native caller
  /// cannot assume the callback will be run immediately. Resources passed to
  /// the callback (such as pointers to malloc'd memory, or output parameters)
  /// must be valid until the call completes.
  ///
  /// This callback must be [close]d when it is no longer needed. The [Isolate]
  /// that created the callback will be kept alive until [close] is called.
  /// After [NativeCallable.close] is called, invoking the [nativeFunction] from
  /// native code will cause undefined behavior.
  ///
  /// For example:
  ///
  /// ```dart
  /// import 'dart:async';
  /// import 'dart:ffi';
  /// import 'package:ffi/ffi.dart';
  ///
  /// // Processes a simple HTTP GET request using a native HTTP library that
  /// // processes the request on a background thread.
  /// Future<String> httpGet(String uri) async {
  ///   final uriPointer = uri.toNativeUtf8();
  ///
  ///   // Create the NativeCallable.listener.
  ///   final completer = Completer<String>();
  ///   late final NativeCallable<NativeHttpCallback> callback;
  ///   void onResponse(Pointer<Utf8> responsePointer) {
  ///     completer.complete(responsePointer.toDartString());
  ///     calloc.free(responsePointer);
  ///     calloc.free(uriPointer);
  ///
  ///     // Remember to close the NativeCallable once the native API is
  ///     // finished with it, otherwise this isolate will stay alive
  ///     // indefinitely.
  ///     callback.close();
  ///   }
  ///   callback = NativeCallable<NativeHttpCallback>.listener(onResponse);
  ///
  ///   // Invoke the native HTTP API. Our example HTTP library processes our
  ///   // request on a background thread, and calls the callback on that same
  ///   // thread when it receives the response.
  ///   nativeHttpGet(uriPointer, callback.nativeFunction);
  ///
  ///   return completer.future;
  /// }
  ///
  /// // Load the native functions from a DynamicLibrary.
  /// final DynamicLibrary dylib = DynamicLibrary.process();
  /// typedef NativeHttpCallback = Void Function(Pointer<Utf8>);
  ///
  /// typedef HttpGetFunction = void Function(
  ///     Pointer<Utf8>, Pointer<NativeFunction<NativeHttpCallback>>);
  /// typedef HttpGetNativeFunction = Void Function(
  ///     Pointer<Utf8>, Pointer<NativeFunction<NativeHttpCallback>>);
  /// final nativeHttpGet =
  ///     dylib.lookupFunction<HttpGetNativeFunction, HttpGetFunction>(
  ///         'http_get');
  /// ```
  factory NativeCallable.listener(
      @DartRepresentationOf("T") Function callback) {
    throw UnsupportedError("NativeCallable cannot be constructed dynamically.");
  }

  /// The native function pointer which can be used to invoke the `callback`
  /// passed to the constructor.
  ///
  /// This pointer must not be read after the callable has been [close]d.
  Pointer<NativeFunction<T>> get nativeFunction;

  /// Closes this callback and releases its resources.
  ///
  /// Further calls to existing [nativeFunction]s will result in undefined
  /// behavior.
  ///
  /// Subsequent calls to [close] will be ignored.
  ///
  /// It is safe to call [close] inside the [callback].
  void close();

  /// Whether this [NativeCallable] keeps its [Isolate] alive.
  ///
  /// By default, [NativeCallable]s keep the [Isolate] that created them alive
  /// until [close] is called. If [keepIsolateAlive] is set to `false`, the
  /// isolate may exit even if the [NativeCallable] isn't closed.
  external bool keepIsolateAlive;
}

//
// The following code is generated, do not edit by hand.
//
// Code generated by `runtime/tools/ffi/sdk_lib_ffi_generator.dart`.
//

/// Extension on [Pointer] specialized for the type argument [Int8].
extension Int8Pointer on Pointer<Int8> {
  /// The 8-bit two's complement integer at [address].
  ///
  /// A Dart integer is truncated to 8 bits (as if by `.toSigned(8)`) before
  /// being stored, and the 8-bit value is sign-extended when it is loaded.
  external int get value;

  external void set value(int value);

  /// The 8-bit two's complement integer at `address + sizeOf<Int8>() * index`.
  ///
  /// A Dart integer is truncated to 8 bits (as if by `.toSigned(8)`) before
  /// being stored, and the 8-bit value is sign-extended when it is loaded.
  external int operator [](int index);

  /// The 8-bit two's complement integer at `address + sizeOf<Int8>() * index`.
  ///
  /// A Dart integer is truncated to 8 bits (as if by `.toSigned(8)`) before
  /// being stored, and the 8-bit value is sign-extended when it is loaded.
  external void operator []=(int index, int value);

  /// Pointer arithmetic (takes element size into account).
  @Deprecated('Use operator + instead')
  Pointer<Int8> elementAt(int index) =>
      Pointer.fromAddress(address + sizeOf<Int8>() * index);

  /// A pointer to the [offset]th [Int8] after this one.
  ///
  /// Returns a pointer to the [Int8] whose address is
  /// [offset] times the size of `Int8` after the address of this pointer.
  /// That is `(this + offset).address == this.address + offset * sizeOf<Int8>()`.
  ///
  /// Also `(this + offset).value` is equivalent to `this[offset]`,
  /// and similarly for setting.
  @Since('3.3')
  @pragma("vm:prefer-inline")
  Pointer<Int8> operator +(int offset) =>
      Pointer.fromAddress(address + sizeOf<Int8>() * offset);

  /// A pointer to the [offset]th [Int8] before this one.
  ///
  /// Equivalent to `this + (-offset)`.
  ///
  /// Returns a pointer to the [Int8] whose address is
  /// [offset] times the size of `Int8` before the address of this pointer.
  /// That is, `(this - offset).address == this.address - offset * sizeOf<Int8>()`.
  ///
  /// Also, `(this - offset).value` is equivalent to `this[-offset]`,
  /// and similarly for setting,
  @Since('3.3')
  @pragma("vm:prefer-inline")
  Pointer<Int8> operator -(int offset) =>
      Pointer.fromAddress(address - sizeOf<Int8>() * offset);

  /// Creates a typed list view backed by memory in the address space.
  ///
  /// The returned view will allow access to the memory range from [address]
  /// to `address + sizeOf<Int8>() * length`.
  ///
  /// The user has to ensure the memory range is accessible while using the
  /// returned list.
  ///
  /// If provided, [finalizer] will be run on the pointer once the typed list
  /// is GCed. If provided, [token] will be passed to [finalizer], otherwise
  /// the this pointer itself will be passed.
  external Int8List asTypedList(
    int length, {
    @Since('3.1') Pointer<NativeFinalizerFunction>? finalizer,
    @Since('3.1') Pointer<Void>? token,
  });
}

/// Extension on [Pointer] specialized for the type argument [Int16].
extension Int16Pointer on Pointer<Int16> {
  /// The 16-bit two's complement integer at [address].
  ///
  /// A Dart integer is truncated to 16 bits (as if by `.toSigned(16)`) before
  /// being stored, and the 16-bit value is sign-extended when it is loaded.
  ///
  /// The [address] must be 2-byte aligned.
  external int get value;

  external void set value(int value);

  /// The 16-bit two's complement integer at `address + sizeOf<Int16>() * index`.
  ///
  /// A Dart integer is truncated to 16 bits (as if by `.toSigned(16)`) before
  /// being stored, and the 16-bit value is sign-extended when it is loaded.
  ///
  /// The [address] must be 2-byte aligned.
  external int operator [](int index);

  /// The 16-bit two's complement integer at `address + sizeOf<Int16>() * index`.
  ///
  /// A Dart integer is truncated to 16 bits (as if by `.toSigned(16)`) before
  /// being stored, and the 16-bit value is sign-extended when it is loaded.
  ///
  /// The [address] must be 2-byte aligned.
  external void operator []=(int index, int value);

  /// Pointer arithmetic (takes element size into account).
  @Deprecated('Use operator + instead')
  Pointer<Int16> elementAt(int index) =>
      Pointer.fromAddress(address + sizeOf<Int16>() * index);

  /// A pointer to the [offset]th [Int16] after this one.
  ///
  /// Returns a pointer to the [Int16] whose address is
  /// [offset] times the size of `Int16` after the address of this pointer.
  /// That is `(this + offset).address == this.address + offset * sizeOf<Int16>()`.
  ///
  /// Also `(this + offset).value` is equivalent to `this[offset]`,
  /// and similarly for setting.
  @Since('3.3')
  @pragma("vm:prefer-inline")
  Pointer<Int16> operator +(int offset) =>
      Pointer.fromAddress(address + sizeOf<Int16>() * offset);

  /// A pointer to the [offset]th [Int16] before this one.
  ///
  /// Equivalent to `this + (-offset)`.
  ///
  /// Returns a pointer to the [Int16] whose address is
  /// [offset] times the size of `Int16` before the address of this pointer.
  /// That is, `(this - offset).address == this.address - offset * sizeOf<Int16>()`.
  ///
  /// Also, `(this - offset).value` is equivalent to `this[-offset]`,
  /// and similarly for setting,
  @Since('3.3')
  @pragma("vm:prefer-inline")
  Pointer<Int16> operator -(int offset) =>
      Pointer.fromAddress(address - sizeOf<Int16>() * offset);

  /// Creates a typed list view backed by memory in the address space.
  ///
  /// The returned view will allow access to the memory range from [address]
  /// to `address + sizeOf<Int16>() * length`.
  ///
  /// The user has to ensure the memory range is accessible while using the
  /// returned list.
  ///
  /// If provided, [finalizer] will be run on the pointer once the typed list
  /// is GCed. If provided, [token] will be passed to [finalizer], otherwise
  /// the this pointer itself will be passed.
  ///
  /// The [address] must be 2-byte aligned.
  external Int16List asTypedList(
    int length, {
    @Since('3.1') Pointer<NativeFinalizerFunction>? finalizer,
    @Since('3.1') Pointer<Void>? token,
  });
}

/// Extension on [Pointer] specialized for the type argument [Int32].
extension Int32Pointer on Pointer<Int32> {
  /// The 32-bit two's complement integer at [address].
  ///
  /// A Dart integer is truncated to 32 bits (as if by `.toSigned(32)`) before
  /// being stored, and the 32-bit value is sign-extended when it is loaded.
  ///
  /// The [address] must be 4-byte aligned.
  external int get value;

  external void set value(int value);

  /// The 32-bit two's complement integer at `address + sizeOf<Int32>() * index`.
  ///
  /// A Dart integer is truncated to 32 bits (as if by `.toSigned(32)`) before
  /// being stored, and the 32-bit value is sign-extended when it is loaded.
  ///
  /// The [address] must be 4-byte aligned.
  external int operator [](int index);

  /// The 32-bit two's complement integer at `address + sizeOf<Int32>() * index`.
  ///
  /// A Dart integer is truncated to 32 bits (as if by `.toSigned(32)`) before
  /// being stored, and the 32-bit value is sign-extended when it is loaded.
  ///
  /// The [address] must be 4-byte aligned.
  external void operator []=(int index, int value);

  /// Pointer arithmetic (takes element size into account).
  @Deprecated('Use operator + instead')
  Pointer<Int32> elementAt(int index) =>
      Pointer.fromAddress(address + sizeOf<Int32>() * index);

  /// A pointer to the [offset]th [Int32] after this one.
  ///
  /// Returns a pointer to the [Int32] whose address is
  /// [offset] times the size of `Int32` after the address of this pointer.
  /// That is `(this + offset).address == this.address + offset * sizeOf<Int32>()`.
  ///
  /// Also `(this + offset).value` is equivalent to `this[offset]`,
  /// and similarly for setting.
  @Since('3.3')
  @pragma("vm:prefer-inline")
  Pointer<Int32> operator +(int offset) =>
      Pointer.fromAddress(address + sizeOf<Int32>() * offset);

  /// A pointer to the [offset]th [Int32] before this one.
  ///
  /// Equivalent to `this + (-offset)`.
  ///
  /// Returns a pointer to the [Int32] whose address is
  /// [offset] times the size of `Int32` before the address of this pointer.
  /// That is, `(this - offset).address == this.address - offset * sizeOf<Int32>()`.
  ///
  /// Also, `(this - offset).value` is equivalent to `this[-offset]`,
  /// and similarly for setting,
  @Since('3.3')
  @pragma("vm:prefer-inline")
  Pointer<Int32> operator -(int offset) =>
      Pointer.fromAddress(address - sizeOf<Int32>() * offset);

  /// Creates a typed list view backed by memory in the address space.
  ///
  /// The returned view will allow access to the memory range from [address]
  /// to `address + sizeOf<Int32>() * length`.
  ///
  /// The user has to ensure the memory range is accessible while using the
  /// returned list.
  ///
  /// If provided, [finalizer] will be run on the pointer once the typed list
  /// is GCed. If provided, [token] will be passed to [finalizer], otherwise
  /// the this pointer itself will be passed.
  ///
  /// The [address] must be 4-byte aligned.
  external Int32List asTypedList(
    int length, {
    @Since('3.1') Pointer<NativeFinalizerFunction>? finalizer,
    @Since('3.1') Pointer<Void>? token,
  });
}

/// Extension on [Pointer] specialized for the type argument [Int64].
extension Int64Pointer on Pointer<Int64> {
  /// The 64-bit two's complement integer at [address].
  ///
  /// The [address] must be 8-byte aligned.
  external int get value;

  external void set value(int value);

  /// The 64-bit two's complement integer at `address + sizeOf<Int64>() * index`.
  ///
  /// The [address] must be 8-byte aligned.
  external int operator [](int index);

  /// The 64-bit two's complement integer at `address + sizeOf<Int64>() * index`.
  ///
  /// The [address] must be 8-byte aligned.
  external void operator []=(int index, int value);

  /// Pointer arithmetic (takes element size into account).
  @Deprecated('Use operator + instead')
  Pointer<Int64> elementAt(int index) =>
      Pointer.fromAddress(address + sizeOf<Int64>() * index);

  /// A pointer to the [offset]th [Int64] after this one.
  ///
  /// Returns a pointer to the [Int64] whose address is
  /// [offset] times the size of `Int64` after the address of this pointer.
  /// That is `(this + offset).address == this.address + offset * sizeOf<Int64>()`.
  ///
  /// Also `(this + offset).value` is equivalent to `this[offset]`,
  /// and similarly for setting.
  @Since('3.3')
  @pragma("vm:prefer-inline")
  Pointer<Int64> operator +(int offset) =>
      Pointer.fromAddress(address + sizeOf<Int64>() * offset);

  /// A pointer to the [offset]th [Int64] before this one.
  ///
  /// Equivalent to `this + (-offset)`.
  ///
  /// Returns a pointer to the [Int64] whose address is
  /// [offset] times the size of `Int64` before the address of this pointer.
  /// That is, `(this - offset).address == this.address - offset * sizeOf<Int64>()`.
  ///
  /// Also, `(this - offset).value` is equivalent to `this[-offset]`,
  /// and similarly for setting,
  @Since('3.3')
  @pragma("vm:prefer-inline")
  Pointer<Int64> operator -(int offset) =>
      Pointer.fromAddress(address - sizeOf<Int64>() * offset);

  /// Creates a typed list view backed by memory in the address space.
  ///
  /// The returned view will allow access to the memory range from [address]
  /// to `address + sizeOf<Int64>() * length`.
  ///
  /// The user has to ensure the memory range is accessible while using the
  /// returned list.
  ///
  /// If provided, [finalizer] will be run on the pointer once the typed list
  /// is GCed. If provided, [token] will be passed to [finalizer], otherwise
  /// the this pointer itself will be passed.
  ///
  /// The [address] must be 8-byte aligned.
  external Int64List asTypedList(
    int length, {
    @Since('3.1') Pointer<NativeFinalizerFunction>? finalizer,
    @Since('3.1') Pointer<Void>? token,
  });
}

/// Extension on [Pointer] specialized for the type argument [Uint8].
extension Uint8Pointer on Pointer<Uint8> {
  /// The 8-bit unsigned integer at [address].
  ///
  /// A Dart integer is truncated to 8 bits (as if by `.toUnsigned(8)`) before
  /// being stored, and the 8-bit value is zero-extended when it is loaded.
  external int get value;

  external void set value(int value);

  /// The 8-bit unsigned integer at `address + sizeOf<Uint8>() * index`.
  ///
  /// A Dart integer is truncated to 8 bits (as if by `.toUnsigned(8)`) before
  /// being stored, and the 8-bit value is zero-extended when it is loaded.
  external int operator [](int index);

  /// The 8-bit unsigned integer at `address + sizeOf<Uint8>() * index`.
  ///
  /// A Dart integer is truncated to 8 bits (as if by `.toUnsigned(8)`) before
  /// being stored, and the 8-bit value is zero-extended when it is loaded.
  external void operator []=(int index, int value);

  /// Pointer arithmetic (takes element size into account).
  @Deprecated('Use operator + instead')
  Pointer<Uint8> elementAt(int index) =>
      Pointer.fromAddress(address + sizeOf<Uint8>() * index);

  /// A pointer to the [offset]th [Uint8] after this one.
  ///
  /// Returns a pointer to the [Uint8] whose address is
  /// [offset] times the size of `Uint8` after the address of this pointer.
  /// That is `(this + offset).address == this.address + offset * sizeOf<Uint8>()`.
  ///
  /// Also `(this + offset).value` is equivalent to `this[offset]`,
  /// and similarly for setting.
  @Since('3.3')
  @pragma("vm:prefer-inline")
  Pointer<Uint8> operator +(int offset) =>
      Pointer.fromAddress(address + sizeOf<Uint8>() * offset);

  /// A pointer to the [offset]th [Uint8] before this one.
  ///
  /// Equivalent to `this + (-offset)`.
  ///
  /// Returns a pointer to the [Uint8] whose address is
  /// [offset] times the size of `Uint8` before the address of this pointer.
  /// That is, `(this - offset).address == this.address - offset * sizeOf<Uint8>()`.
  ///
  /// Also, `(this - offset).value` is equivalent to `this[-offset]`,
  /// and similarly for setting,
  @Since('3.3')
  @pragma("vm:prefer-inline")
  Pointer<Uint8> operator -(int offset) =>
      Pointer.fromAddress(address - sizeOf<Uint8>() * offset);

  /// Creates a typed list view backed by memory in the address space.
  ///
  /// The returned view will allow access to the memory range from [address]
  /// to `address + sizeOf<Uint8>() * length`.
  ///
  /// The user has to ensure the memory range is accessible while using the
  /// returned list.
  ///
  /// If provided, [finalizer] will be run on the pointer once the typed list
  /// is GCed. If provided, [token] will be passed to [finalizer], otherwise
  /// the this pointer itself will be passed.
  external Uint8List asTypedList(
    int length, {
    @Since('3.1') Pointer<NativeFinalizerFunction>? finalizer,
    @Since('3.1') Pointer<Void>? token,
  });
}

/// Extension on [Pointer] specialized for the type argument [Uint16].
extension Uint16Pointer on Pointer<Uint16> {
  /// The 16-bit unsigned integer at [address].
  ///
  /// A Dart integer is truncated to 16 bits (as if by `.toUnsigned(16)`) before
  /// being stored, and the 16-bit value is zero-extended when it is loaded.
  ///
  /// The [address] must be 2-byte aligned.
  external int get value;

  external void set value(int value);

  /// The 16-bit unsigned integer at `address + sizeOf<Uint16>() * index`.
  ///
  /// A Dart integer is truncated to 16 bits (as if by `.toUnsigned(16)`) before
  /// being stored, and the 16-bit value is zero-extended when it is loaded.
  ///
  /// The [address] must be 2-byte aligned.
  external int operator [](int index);

  /// The 16-bit unsigned integer at `address + sizeOf<Uint16>() * index`.
  ///
  /// A Dart integer is truncated to 16 bits (as if by `.toUnsigned(16)`) before
  /// being stored, and the 16-bit value is zero-extended when it is loaded.
  ///
  /// The [address] must be 2-byte aligned.
  external void operator []=(int index, int value);

  /// Pointer arithmetic (takes element size into account).
  @Deprecated('Use operator + instead')
  Pointer<Uint16> elementAt(int index) =>
      Pointer.fromAddress(address + sizeOf<Uint16>() * index);

  /// A pointer to the [offset]th [Uint16] after this one.
  ///
  /// Returns a pointer to the [Uint16] whose address is
  /// [offset] times the size of `Uint16` after the address of this pointer.
  /// That is `(this + offset).address == this.address + offset * sizeOf<Uint16>()`.
  ///
  /// Also `(this + offset).value` is equivalent to `this[offset]`,
  /// and similarly for setting.
  @Since('3.3')
  @pragma("vm:prefer-inline")
  Pointer<Uint16> operator +(int offset) =>
      Pointer.fromAddress(address + sizeOf<Uint16>() * offset);

  /// A pointer to the [offset]th [Uint16] before this one.
  ///
  /// Equivalent to `this + (-offset)`.
  ///
  /// Returns a pointer to the [Uint16] whose address is
  /// [offset] times the size of `Uint16` before the address of this pointer.
  /// That is, `(this - offset).address == this.address - offset * sizeOf<Uint16>()`.
  ///
  /// Also, `(this - offset).value` is equivalent to `this[-offset]`,
  /// and similarly for setting,
  @Since('3.3')
  @pragma("vm:prefer-inline")
  Pointer<Uint16> operator -(int offset) =>
      Pointer.fromAddress(address - sizeOf<Uint16>() * offset);

  /// Creates a typed list view backed by memory in the address space.
  ///
  /// The returned view will allow access to the memory range from [address]
  /// to `address + sizeOf<Uint16>() * length`.
  ///
  /// The user has to ensure the memory range is accessible while using the
  /// returned list.
  ///
  /// If provided, [finalizer] will be run on the pointer once the typed list
  /// is GCed. If provided, [token] will be passed to [finalizer], otherwise
  /// the this pointer itself will be passed.
  ///
  /// The [address] must be 2-byte aligned.
  external Uint16List asTypedList(
    int length, {
    @Since('3.1') Pointer<NativeFinalizerFunction>? finalizer,
    @Since('3.1') Pointer<Void>? token,
  });
}

/// Extension on [Pointer] specialized for the type argument [Uint32].
extension Uint32Pointer on Pointer<Uint32> {
  /// The 32-bit unsigned integer at [address].
  ///
  /// A Dart integer is truncated to 32 bits (as if by `.toUnsigned(32)`) before
  /// being stored, and the 32-bit value is zero-extended when it is loaded.
  ///
  /// The [address] must be 4-byte aligned.
  external int get value;

  external void set value(int value);

  /// The 32-bit unsigned integer at `address + sizeOf<Uint32>() * index`.
  ///
  /// A Dart integer is truncated to 32 bits (as if by `.toUnsigned(32)`) before
  /// being stored, and the 32-bit value is zero-extended when it is loaded.
  ///
  /// The [address] must be 4-byte aligned.
  external int operator [](int index);

  /// The 32-bit unsigned integer at `address + sizeOf<Uint32>() * index`.
  ///
  /// A Dart integer is truncated to 32 bits (as if by `.toUnsigned(32)`) before
  /// being stored, and the 32-bit value is zero-extended when it is loaded.
  ///
  /// The [address] must be 4-byte aligned.
  external void operator []=(int index, int value);

  /// Pointer arithmetic (takes element size into account).
  @Deprecated('Use operator + instead')
  Pointer<Uint32> elementAt(int index) =>
      Pointer.fromAddress(address + sizeOf<Uint32>() * index);

  /// A pointer to the [offset]th [Uint32] after this one.
  ///
  /// Returns a pointer to the [Uint32] whose address is
  /// [offset] times the size of `Uint32` after the address of this pointer.
  /// That is `(this + offset).address == this.address + offset * sizeOf<Uint32>()`.
  ///
  /// Also `(this + offset).value` is equivalent to `this[offset]`,
  /// and similarly for setting.
  @Since('3.3')
  @pragma("vm:prefer-inline")
  Pointer<Uint32> operator +(int offset) =>
      Pointer.fromAddress(address + sizeOf<Uint32>() * offset);

  /// A pointer to the [offset]th [Uint32] before this one.
  ///
  /// Equivalent to `this + (-offset)`.
  ///
  /// Returns a pointer to the [Uint32] whose address is
  /// [offset] times the size of `Uint32` before the address of this pointer.
  /// That is, `(this - offset).address == this.address - offset * sizeOf<Uint32>()`.
  ///
  /// Also, `(this - offset).value` is equivalent to `this[-offset]`,
  /// and similarly for setting,
  @Since('3.3')
  @pragma("vm:prefer-inline")
  Pointer<Uint32> operator -(int offset) =>
      Pointer.fromAddress(address - sizeOf<Uint32>() * offset);

  /// Creates a typed list view backed by memory in the address space.
  ///
  /// The returned view will allow access to the memory range from [address]
  /// to `address + sizeOf<Uint32>() * length`.
  ///
  /// The user has to ensure the memory range is accessible while using the
  /// returned list.
  ///
  /// If provided, [finalizer] will be run on the pointer once the typed list
  /// is GCed. If provided, [token] will be passed to [finalizer], otherwise
  /// the this pointer itself will be passed.
  ///
  /// The [address] must be 4-byte aligned.
  external Uint32List asTypedList(
    int length, {
    @Since('3.1') Pointer<NativeFinalizerFunction>? finalizer,
    @Since('3.1') Pointer<Void>? token,
  });
}

/// Extension on [Pointer] specialized for the type argument [Uint64].
extension Uint64Pointer on Pointer<Uint64> {
  /// The 64-bit unsigned integer at [address].
  ///
  /// The [address] must be 8-byte aligned.
  external int get value;

  external void set value(int value);

  /// The 64-bit unsigned integer at `address + sizeOf<Uint64>() * index`.
  ///
  /// The [address] must be 8-byte aligned.
  external int operator [](int index);

  /// The 64-bit unsigned integer at `address + sizeOf<Uint64>() * index`.
  ///
  /// The [address] must be 8-byte aligned.
  external void operator []=(int index, int value);

  /// Pointer arithmetic (takes element size into account).
  @Deprecated('Use operator + instead')
  Pointer<Uint64> elementAt(int index) =>
      Pointer.fromAddress(address + sizeOf<Uint64>() * index);

  /// A pointer to the [offset]th [Uint64] after this one.
  ///
  /// Returns a pointer to the [Uint64] whose address is
  /// [offset] times the size of `Uint64` after the address of this pointer.
  /// That is `(this + offset).address == this.address + offset * sizeOf<Uint64>()`.
  ///
  /// Also `(this + offset).value` is equivalent to `this[offset]`,
  /// and similarly for setting.
  @Since('3.3')
  @pragma("vm:prefer-inline")
  Pointer<Uint64> operator +(int offset) =>
      Pointer.fromAddress(address + sizeOf<Uint64>() * offset);

  /// A pointer to the [offset]th [Uint64] before this one.
  ///
  /// Equivalent to `this + (-offset)`.
  ///
  /// Returns a pointer to the [Uint64] whose address is
  /// [offset] times the size of `Uint64` before the address of this pointer.
  /// That is, `(this - offset).address == this.address - offset * sizeOf<Uint64>()`.
  ///
  /// Also, `(this - offset).value` is equivalent to `this[-offset]`,
  /// and similarly for setting,
  @Since('3.3')
  @pragma("vm:prefer-inline")
  Pointer<Uint64> operator -(int offset) =>
      Pointer.fromAddress(address - sizeOf<Uint64>() * offset);

  /// Creates a typed list view backed by memory in the address space.
  ///
  /// The returned view will allow access to the memory range from [address]
  /// to `address + sizeOf<Uint64>() * length`.
  ///
  /// The user has to ensure the memory range is accessible while using the
  /// returned list.
  ///
  /// If provided, [finalizer] will be run on the pointer once the typed list
  /// is GCed. If provided, [token] will be passed to [finalizer], otherwise
  /// the this pointer itself will be passed.
  ///
  /// The [address] must be 8-byte aligned.
  external Uint64List asTypedList(
    int length, {
    @Since('3.1') Pointer<NativeFinalizerFunction>? finalizer,
    @Since('3.1') Pointer<Void>? token,
  });
}

/// Extension on [Pointer] specialized for the type argument [Float].
extension FloatPointer on Pointer<Float> {
  /// The float at [address].
  ///
  /// A Dart double loses precision before being stored, and the float value is
  /// converted to a double when it is loaded.
  ///
  /// The [address] must be 4-byte aligned.
  external double get value;

  external void set value(double value);

  /// The float at `address + sizeOf<Float>() * index`.
  ///
  /// A Dart double loses precision before being stored, and the float value is
  /// converted to a double when it is loaded.
  ///
  /// The [address] must be 4-byte aligned.
  external double operator [](int index);

  /// The float at `address + sizeOf<Float>() * index`.
  ///
  /// A Dart double loses precision before being stored, and the float value is
  /// converted to a double when it is loaded.
  ///
  /// The [address] must be 4-byte aligned.
  external void operator []=(int index, double value);

  /// Pointer arithmetic (takes element size into account).
  @Deprecated('Use operator + instead')
  Pointer<Float> elementAt(int index) =>
      Pointer.fromAddress(address + sizeOf<Float>() * index);

  /// A pointer to the [offset]th [Float] after this one.
  ///
  /// Returns a pointer to the [Float] whose address is
  /// [offset] times the size of `Float` after the address of this pointer.
  /// That is `(this + offset).address == this.address + offset * sizeOf<Float>()`.
  ///
  /// Also `(this + offset).value` is equivalent to `this[offset]`,
  /// and similarly for setting.
  @Since('3.3')
  @pragma("vm:prefer-inline")
  Pointer<Float> operator +(int offset) =>
      Pointer.fromAddress(address + sizeOf<Float>() * offset);

  /// A pointer to the [offset]th [Float] before this one.
  ///
  /// Equivalent to `this + (-offset)`.
  ///
  /// Returns a pointer to the [Float] whose address is
  /// [offset] times the size of `Float` before the address of this pointer.
  /// That is, `(this - offset).address == this.address - offset * sizeOf<Float>()`.
  ///
  /// Also, `(this - offset).value` is equivalent to `this[-offset]`,
  /// and similarly for setting,
  @Since('3.3')
  @pragma("vm:prefer-inline")
  Pointer<Float> operator -(int offset) =>
      Pointer.fromAddress(address - sizeOf<Float>() * offset);

  /// Creates a typed list view backed by memory in the address space.
  ///
  /// The returned view will allow access to the memory range from [address]
  /// to `address + sizeOf<Float>() * length`.
  ///
  /// The user has to ensure the memory range is accessible while using the
  /// returned list.
  ///
  /// If provided, [finalizer] will be run on the pointer once the typed list
  /// is GCed. If provided, [token] will be passed to [finalizer], otherwise
  /// the this pointer itself will be passed.
  ///
  /// The [address] must be 4-byte aligned.
  external Float32List asTypedList(
    int length, {
    @Since('3.1') Pointer<NativeFinalizerFunction>? finalizer,
    @Since('3.1') Pointer<Void>? token,
  });
}

/// Extension on [Pointer] specialized for the type argument [Double].
extension DoublePointer on Pointer<Double> {
  /// The double at [address].
  ///
  /// The [address] must be 8-byte aligned.
  external double get value;

  external void set value(double value);

  /// The double at `address + sizeOf<Double>() * index`.
  ///
  /// The [address] must be 8-byte aligned.
  external double operator [](int index);

  /// The double at `address + sizeOf<Double>() * index`.
  ///
  /// The [address] must be 8-byte aligned.
  external void operator []=(int index, double value);

  /// Pointer arithmetic (takes element size into account).
  @Deprecated('Use operator + instead')
  Pointer<Double> elementAt(int index) =>
      Pointer.fromAddress(address + sizeOf<Double>() * index);

  /// A pointer to the [offset]th [Double] after this one.
  ///
  /// Returns a pointer to the [Double] whose address is
  /// [offset] times the size of `Double` after the address of this pointer.
  /// That is `(this + offset).address == this.address + offset * sizeOf<Double>()`.
  ///
  /// Also `(this + offset).value` is equivalent to `this[offset]`,
  /// and similarly for setting.
  @Since('3.3')
  @pragma("vm:prefer-inline")
  Pointer<Double> operator +(int offset) =>
      Pointer.fromAddress(address + sizeOf<Double>() * offset);

  /// A pointer to the [offset]th [Double] before this one.
  ///
  /// Equivalent to `this + (-offset)`.
  ///
  /// Returns a pointer to the [Double] whose address is
  /// [offset] times the size of `Double` before the address of this pointer.
  /// That is, `(this - offset).address == this.address - offset * sizeOf<Double>()`.
  ///
  /// Also, `(this - offset).value` is equivalent to `this[-offset]`,
  /// and similarly for setting,
  @Since('3.3')
  @pragma("vm:prefer-inline")
  Pointer<Double> operator -(int offset) =>
      Pointer.fromAddress(address - sizeOf<Double>() * offset);

  /// Creates a typed list view backed by memory in the address space.
  ///
  /// The returned view will allow access to the memory range from [address]
  /// to `address + sizeOf<Double>() * length`.
  ///
  /// The user has to ensure the memory range is accessible while using the
  /// returned list.
  ///
  /// If provided, [finalizer] will be run on the pointer once the typed list
  /// is GCed. If provided, [token] will be passed to [finalizer], otherwise
  /// the this pointer itself will be passed.
  ///
  /// The [address] must be 8-byte aligned.
  external Float64List asTypedList(
    int length, {
    @Since('3.1') Pointer<NativeFinalizerFunction>? finalizer,
    @Since('3.1') Pointer<Void>? token,
  });
}

/// Extension on [Pointer] specialized for the type argument [Bool].
@Since('2.15')
extension BoolPointer on Pointer<Bool> {
  /// The bool at [address].
  external bool get value;

  external void set value(bool value);

  /// The bool at `address + sizeOf<Bool>() * index`.
  external bool operator [](int index);

  /// The bool at `address + sizeOf<Bool>() * index`.
  external void operator []=(int index, bool value);

  /// Pointer arithmetic (takes element size into account).
  @Deprecated('Use operator + instead')
  Pointer<Bool> elementAt(int index) =>
      Pointer.fromAddress(address + sizeOf<Bool>() * index);

  /// A pointer to the [offset]th [Bool] after this one.
  ///
  /// Returns a pointer to the [Bool] whose address is
  /// [offset] times the size of `Bool` after the address of this pointer.
  /// That is `(this + offset).address == this.address + offset * sizeOf<Bool>()`.
  ///
  /// Also `(this + offset).value` is equivalent to `this[offset]`,
  /// and similarly for setting.
  @Since('3.3')
  @pragma("vm:prefer-inline")
  Pointer<Bool> operator +(int offset) =>
      Pointer.fromAddress(address + sizeOf<Bool>() * offset);

  /// A pointer to the [offset]th [Bool] before this one.
  ///
  /// Equivalent to `this + (-offset)`.
  ///
  /// Returns a pointer to the [Bool] whose address is
  /// [offset] times the size of `Bool` before the address of this pointer.
  /// That is, `(this - offset).address == this.address - offset * sizeOf<Bool>()`.
  ///
  /// Also, `(this - offset).value` is equivalent to `this[-offset]`,
  /// and similarly for setting,
  @Since('3.3')
  @pragma("vm:prefer-inline")
  Pointer<Bool> operator -(int offset) =>
      Pointer.fromAddress(address - sizeOf<Bool>() * offset);
}

/// Bounds checking indexing methods on [Array]s of [Int8].
@Since('2.13')
extension Int8Array on Array<Int8> {
  external int operator [](int index);

  external void operator []=(int index, int value);
}

/// Bounds checking indexing methods on [Array]s of [Int16].
@Since('2.13')
extension Int16Array on Array<Int16> {
  external int operator [](int index);

  external void operator []=(int index, int value);
}

/// Bounds checking indexing methods on [Array]s of [Int32].
@Since('2.13')
extension Int32Array on Array<Int32> {
  external int operator [](int index);

  external void operator []=(int index, int value);
}

/// Bounds checking indexing methods on [Array]s of [Int64].
@Since('2.13')
extension Int64Array on Array<Int64> {
  external int operator [](int index);

  external void operator []=(int index, int value);
}

/// Bounds checking indexing methods on [Array]s of [Uint8].
@Since('2.13')
extension Uint8Array on Array<Uint8> {
  external int operator [](int index);

  external void operator []=(int index, int value);
}

/// Bounds checking indexing methods on [Array]s of [Uint16].
@Since('2.13')
extension Uint16Array on Array<Uint16> {
  external int operator [](int index);

  external void operator []=(int index, int value);
}

/// Bounds checking indexing methods on [Array]s of [Uint32].
@Since('2.13')
extension Uint32Array on Array<Uint32> {
  external int operator [](int index);

  external void operator []=(int index, int value);
}

/// Bounds checking indexing methods on [Array]s of [Uint64].
@Since('2.13')
extension Uint64Array on Array<Uint64> {
  external int operator [](int index);

  external void operator []=(int index, int value);
}

/// Bounds checking indexing methods on [Array]s of [Float].
@Since('2.13')
extension FloatArray on Array<Float> {
  external double operator [](int index);

  external void operator []=(int index, double value);
}

/// Bounds checking indexing methods on [Array]s of [Double].
@Since('2.13')
extension DoubleArray on Array<Double> {
  external double operator [](int index);

  external void operator []=(int index, double value);
}

/// Bounds checking indexing methods on [Array]s of [Bool].
@Since('2.15')
extension BoolArray on Array<Bool> {
  external bool operator [](int index);

  external void operator []=(int index, bool value);
}

@Since('3.5')
extension Int8ListAddress on Int8List {
  /// The memory address of the underlying data.
  ///
  /// An expression of the form `expression.address` denoting this `address`
  /// can only occurr as an entire argument expression in the invocation of
  /// a leaf [Native] external function.
  ///
  /// Example:
  ///
  /// ```dart import:typed_data
  /// @Native<Void Function(Pointer<Int8>)>(isLeaf: true)
  /// external void myFunction(Pointer<Int8> pointer);
  ///
  /// void main() {
  ///   final list = Int8List(10);
  ///   myFunction(list.address);
  /// }
  /// ```
  ///
  /// The expression before `.address` is evaluated like the left-hand-side of
  /// an assignment, to something that gives access to the storage behind the
  /// expression, which can be used both for reading and writing. The `.address`
  /// then gives a native pointer to that storage.
  ///
  /// The `.address` is evaluated just before calling into native code when
  /// invoking a leaf [Native] external function. This ensures the Dart garbage
  /// collector will not move the object that the address points in to.
  external Pointer<Int8> get address;
}

@Since('3.5')
extension Int16ListAddress on Int16List {
  /// The memory address of the underlying data.
  ///
  /// An expression of the form `expression.address` denoting this `address`
  /// can only occurr as an entire argument expression in the invocation of
  /// a leaf [Native] external function.
  ///
  /// Example:
  ///
  /// ```dart import:typed_data
  /// @Native<Void Function(Pointer<Int16>)>(isLeaf: true)
  /// external void myFunction(Pointer<Int16> pointer);
  ///
  /// void main() {
  ///   final list = Int16List(10);
  ///   myFunction(list.address);
  /// }
  /// ```
  ///
  /// The expression before `.address` is evaluated like the left-hand-side of
  /// an assignment, to something that gives access to the storage behind the
  /// expression, which can be used both for reading and writing. The `.address`
  /// then gives a native pointer to that storage.
  ///
  /// The `.address` is evaluated just before calling into native code when
  /// invoking a leaf [Native] external function. This ensures the Dart garbage
  /// collector will not move the object that the address points in to.
  external Pointer<Int16> get address;
}

@Since('3.5')
extension Int32ListAddress on Int32List {
  /// The memory address of the underlying data.
  ///
  /// An expression of the form `expression.address` denoting this `address`
  /// can only occurr as an entire argument expression in the invocation of
  /// a leaf [Native] external function.
  ///
  /// Example:
  ///
  /// ```dart import:typed_data
  /// @Native<Void Function(Pointer<Int32>)>(isLeaf: true)
  /// external void myFunction(Pointer<Int32> pointer);
  ///
  /// void main() {
  ///   final list = Int32List(10);
  ///   myFunction(list.address);
  /// }
  /// ```
  ///
  /// The expression before `.address` is evaluated like the left-hand-side of
  /// an assignment, to something that gives access to the storage behind the
  /// expression, which can be used both for reading and writing. The `.address`
  /// then gives a native pointer to that storage.
  ///
  /// The `.address` is evaluated just before calling into native code when
  /// invoking a leaf [Native] external function. This ensures the Dart garbage
  /// collector will not move the object that the address points in to.
  external Pointer<Int32> get address;
}

@Since('3.5')
extension Int64ListAddress on Int64List {
  /// The memory address of the underlying data.
  ///
  /// An expression of the form `expression.address` denoting this `address`
  /// can only occurr as an entire argument expression in the invocation of
  /// a leaf [Native] external function.
  ///
  /// Example:
  ///
  /// ```dart import:typed_data
  /// @Native<Void Function(Pointer<Int64>)>(isLeaf: true)
  /// external void myFunction(Pointer<Int64> pointer);
  ///
  /// void main() {
  ///   final list = Int64List(10);
  ///   myFunction(list.address);
  /// }
  /// ```
  ///
  /// The expression before `.address` is evaluated like the left-hand-side of
  /// an assignment, to something that gives access to the storage behind the
  /// expression, which can be used both for reading and writing. The `.address`
  /// then gives a native pointer to that storage.
  ///
  /// The `.address` is evaluated just before calling into native code when
  /// invoking a leaf [Native] external function. This ensures the Dart garbage
  /// collector will not move the object that the address points in to.
  external Pointer<Int64> get address;
}

@Since('3.5')
extension Uint8ListAddress on Uint8List {
  /// The memory address of the underlying data.
  ///
  /// An expression of the form `expression.address` denoting this `address`
  /// can only occurr as an entire argument expression in the invocation of
  /// a leaf [Native] external function.
  ///
  /// Example:
  ///
  /// ```dart import:typed_data
  /// @Native<Void Function(Pointer<Uint8>)>(isLeaf: true)
  /// external void myFunction(Pointer<Uint8> pointer);
  ///
  /// void main() {
  ///   final list = Uint8List(10);
  ///   myFunction(list.address);
  /// }
  /// ```
  ///
  /// The expression before `.address` is evaluated like the left-hand-side of
  /// an assignment, to something that gives access to the storage behind the
  /// expression, which can be used both for reading and writing. The `.address`
  /// then gives a native pointer to that storage.
  ///
  /// The `.address` is evaluated just before calling into native code when
  /// invoking a leaf [Native] external function. This ensures the Dart garbage
  /// collector will not move the object that the address points in to.
  external Pointer<Uint8> get address;
}

@Since('3.5')
extension Uint16ListAddress on Uint16List {
  /// The memory address of the underlying data.
  ///
  /// An expression of the form `expression.address` denoting this `address`
  /// can only occurr as an entire argument expression in the invocation of
  /// a leaf [Native] external function.
  ///
  /// Example:
  ///
  /// ```dart import:typed_data
  /// @Native<Void Function(Pointer<Uint16>)>(isLeaf: true)
  /// external void myFunction(Pointer<Uint16> pointer);
  ///
  /// void main() {
  ///   final list = Uint16List(10);
  ///   myFunction(list.address);
  /// }
  /// ```
  ///
  /// The expression before `.address` is evaluated like the left-hand-side of
  /// an assignment, to something that gives access to the storage behind the
  /// expression, which can be used both for reading and writing. The `.address`
  /// then gives a native pointer to that storage.
  ///
  /// The `.address` is evaluated just before calling into native code when
  /// invoking a leaf [Native] external function. This ensures the Dart garbage
  /// collector will not move the object that the address points in to.
  external Pointer<Uint16> get address;
}

@Since('3.5')
extension Uint32ListAddress on Uint32List {
  /// The memory address of the underlying data.
  ///
  /// An expression of the form `expression.address` denoting this `address`
  /// can only occurr as an entire argument expression in the invocation of
  /// a leaf [Native] external function.
  ///
  /// Example:
  ///
  /// ```dart import:typed_data
  /// @Native<Void Function(Pointer<Uint32>)>(isLeaf: true)
  /// external void myFunction(Pointer<Uint32> pointer);
  ///
  /// void main() {
  ///   final list = Uint32List(10);
  ///   myFunction(list.address);
  /// }
  /// ```
  ///
  /// The expression before `.address` is evaluated like the left-hand-side of
  /// an assignment, to something that gives access to the storage behind the
  /// expression, which can be used both for reading and writing. The `.address`
  /// then gives a native pointer to that storage.
  ///
  /// The `.address` is evaluated just before calling into native code when
  /// invoking a leaf [Native] external function. This ensures the Dart garbage
  /// collector will not move the object that the address points in to.
  external Pointer<Uint32> get address;
}

@Since('3.5')
extension Uint64ListAddress on Uint64List {
  /// The memory address of the underlying data.
  ///
  /// An expression of the form `expression.address` denoting this `address`
  /// can only occurr as an entire argument expression in the invocation of
  /// a leaf [Native] external function.
  ///
  /// Example:
  ///
  /// ```dart import:typed_data
  /// @Native<Void Function(Pointer<Uint64>)>(isLeaf: true)
  /// external void myFunction(Pointer<Uint64> pointer);
  ///
  /// void main() {
  ///   final list = Uint64List(10);
  ///   myFunction(list.address);
  /// }
  /// ```
  ///
  /// The expression before `.address` is evaluated like the left-hand-side of
  /// an assignment, to something that gives access to the storage behind the
  /// expression, which can be used both for reading and writing. The `.address`
  /// then gives a native pointer to that storage.
  ///
  /// The `.address` is evaluated just before calling into native code when
  /// invoking a leaf [Native] external function. This ensures the Dart garbage
  /// collector will not move the object that the address points in to.
  external Pointer<Uint64> get address;
}

@Since('3.5')
extension Float32ListAddress on Float32List {
  /// The memory address of the underlying data.
  ///
  /// An expression of the form `expression.address` denoting this `address`
  /// can only occurr as an entire argument expression in the invocation of
  /// a leaf [Native] external function.
  ///
  /// Example:
  ///
  /// ```dart import:typed_data
  /// @Native<Void Function(Pointer<Float>)>(isLeaf: true)
  /// external void myFunction(Pointer<Float> pointer);
  ///
  /// void main() {
  ///   final list = Float32List(10);
  ///   myFunction(list.address);
  /// }
  /// ```
  ///
  /// The expression before `.address` is evaluated like the left-hand-side of
  /// an assignment, to something that gives access to the storage behind the
  /// expression, which can be used both for reading and writing. The `.address`
  /// then gives a native pointer to that storage.
  ///
  /// The `.address` is evaluated just before calling into native code when
  /// invoking a leaf [Native] external function. This ensures the Dart garbage
  /// collector will not move the object that the address points in to.
  external Pointer<Float> get address;
}

@Since('3.5')
extension Float64ListAddress on Float64List {
  /// The memory address of the underlying data.
  ///
  /// An expression of the form `expression.address` denoting this `address`
  /// can only occurr as an entire argument expression in the invocation of
  /// a leaf [Native] external function.
  ///
  /// Example:
  ///
  /// ```dart import:typed_data
  /// @Native<Void Function(Pointer<Double>)>(isLeaf: true)
  /// external void myFunction(Pointer<Double> pointer);
  ///
  /// void main() {
  ///   final list = Float64List(10);
  ///   myFunction(list.address);
  /// }
  /// ```
  ///
  /// The expression before `.address` is evaluated like the left-hand-side of
  /// an assignment, to something that gives access to the storage behind the
  /// expression, which can be used both for reading and writing. The `.address`
  /// then gives a native pointer to that storage.
  ///
  /// The `.address` is evaluated just before calling into native code when
  /// invoking a leaf [Native] external function. This ensures the Dart garbage
  /// collector will not move the object that the address points in to.
  external Pointer<Double> get address;
}

//
// End of generated code.
//

/// Extension on [Pointer] specialized for the type argument [Pointer].
extension PointerPointer<T extends NativeType> on Pointer<Pointer<T>> {
  /// The pointer at [address].
  ///
  /// A [Pointer] is unboxed before being stored (as if by `.address`), and the
  /// pointer is boxed (as if by `Pointer.fromAddress`) when loaded.
  ///
  /// On 32-bit platforms the [address] must be 4-byte aligned, and on 64-bit
  /// platforms the [address] must be 8-byte aligned.
  external Pointer<T> get value;

  external void set value(Pointer<T> value);

  /// Load a Dart value from this location offset by [index].
  ///
  /// A [Pointer] is unboxed before being stored (as if by `.address`), and the
  /// pointer is boxed (as if by `Pointer.fromAddress`) when loaded.
  ///
  /// On 32-bit platforms the [address] must be 4-byte aligned, and on 64-bit
  /// platforms the [address] must be 8-byte aligned.
  external Pointer<T> operator [](int index);

  /// Store a Dart value into this location offset by [index].
  ///
  /// A [Pointer] is unboxed before being stored (as if by `.address`), and the
  /// pointer is boxed (as if by [Pointer.fromAddress]) when loaded.
  ///
  /// On 32-bit platforms the [address] must be 4-byte aligned, and on 64-bit
  /// platforms the [address] must be 8-byte aligned.
  external void operator []=(int index, Pointer<T> value);

  /// Pointer arithmetic (takes element size into account).
  @Deprecated('Use operator + instead')
  external Pointer<Pointer<T>> elementAt(int index);

  /// A pointer to the [offset]th [Pointer<T>] after this one.
  ///
  /// Returns a pointer to the [Pointer<T>] whose address is
  /// [offset] times the size of `Pointer<T>` after the address of this pointer.
  /// That is `(this + offset).address == this.address + offset * sizeOf<Pointer<T>>()`.
  ///
  /// Also `(this + offset).value` is equivalent to `this[offset]`,
  /// and similarly for setting.
  external Pointer<Pointer<T>> operator +(int offset);

  /// A pointer to the [offset]th [Pointer<T>] before this one.
  ///
  /// Equivalent to `this + (-offset)`.
  ///
  /// Returns a pointer to the [Pointer<T>] whose address is
  /// [offset] times the size of `Pointer<T>` before the address of this pointer.
  /// That is, `(this - offset).address == this.address - offset * sizeOf<Pointer<T>>()`.
  ///
  /// Also, `(this - offset).value` is equivalent to `this[-offset]`,
  /// and similarly for setting,
  external Pointer<Pointer<T>> operator -(int offset);
}

/// Extension on [Pointer] specialized for the type argument [Struct].
@Since('2.12')
extension StructPointer<T extends Struct> on Pointer<T> {
  /// A Dart view of the struct referenced by this pointer.
  ///
  /// Reading [ref] creates a reference accessing the fields of this struct
  /// backed by native memory at [address].
  /// The [address] must be aligned according to the struct alignment rules of
  /// the platform.
  ///
  /// Assigning to [ref] copies contents of the struct into the native memory
  /// starting at [address].
  ///
  /// This extension method must be invoked on a receiver of type `Pointer<T>`
  /// where `T` is a compile-time constant type.
  external T get ref;
  external set ref(T value);

  /// Creates a reference to access the fields of this struct backed by native
  /// memory at `address + sizeOf<T>() * index`.
  ///
  /// The [address] must be aligned according to the struct alignment rules of
  /// the platform.
  ///
  /// This extension method must be invoked on a receiver of type `Pointer<T>`
  /// where `T` is a compile-time constant type.
  external T operator [](int index);

  /// Copies the [value] struct into native memory, starting at
  /// `address * sizeOf<T>() * index`.
  ///
  /// This extension method must be invoked on a receiver of type `Pointer<T>`
  /// where `T` is a compile-time constant type.
  external void operator []=(int index, T value);

  /// Pointer arithmetic (takes element size into account)
  @Deprecated('Use operator + instead')
  external Pointer<T> elementAt(int index);

  /// A pointer to the [offset]th [T] after this one.
  ///
  /// Returns a pointer to the [T] whose address is
  /// [offset] times the size of `T` after the address of this pointer.
  /// That is `(this + offset).address == this.address + offset * sizeOf<T>()`.
  ///
  /// Also `(this + offset).value` is equivalent to `this[offset]`,
  /// and similarly for setting.
  external Pointer<T> operator +(int offset);

  /// A pointer to the [offset]th [T] before this one.
  ///
  /// Equivalent to `this + (-offset)`.
  ///
  /// Returns a pointer to the [T] whose address is
  /// [offset] times the size of `T` before the address of this pointer.
  /// That is, `(this - offset).address == this.address - offset * sizeOf<T>()`.
  ///
  /// Also, `(this - offset).value` is equivalent to `this[-offset]`,
  /// and similarly for setting,
  external Pointer<T> operator -(int offset);
}

/// Extension on [Pointer] specialized for the type argument [Union].
@Since('2.14')
extension UnionPointer<T extends Union> on Pointer<T> {
  /// A Dart view of the union referenced by this pointer.
  ///
  /// Reading [ref] creates a reference accessing the fields of this union
  /// backed by native memory at [address].
  /// The [address] must be aligned according to the union alignment rules of
  /// the platform.
  ///
  /// Assigning to [ref] copies contents of the union into the native memory
  /// starting at [address].
  ///
  /// This extension method must be invoked on a receiver of type `Pointer<T>`
  /// where `T` is a compile-time constant type.
  external T get ref;
  external set ref(T value);

  /// Creates a reference to access the fields of this union backed by native
  /// memory at `address + sizeOf<T>() * index`.
  ///
  /// The [address] must be aligned according to the union alignment rules of
  /// the platform.
  ///
  /// This extension method must be invoked on a receiver of type `Pointer<T>`
  /// where `T` is a compile-time constant type.
  external T operator [](int index);

  /// Copies the [value] union into native memory, starting at
  /// `address * sizeOf<T>() * index`.
  ///
  /// This extension method must be invoked on a receiver of type `Pointer<T>`
  /// where `T` is a compile-time constant type.
  external void operator []=(int index, T value);

  /// Pointer arithmetic (takes element size into account).
  @Deprecated('Use operator + instead')
  external Pointer<T> elementAt(int index);

  /// A pointer to the [offset]th [T] after this one.
  ///
  /// Returns a pointer to the [T] whose address is
  /// [offset] times the size of `T` after the address of this pointer.
  /// That is `(this + offset).address == this.address + offset * sizeOf<T>()`.
  ///
  /// Also `(this + offset).value` is equivalent to `this[offset]`,
  /// and similarly for setting.
  external Pointer<T> operator +(int offset);

  /// A pointer to the [offset]th [T] before this one.
  ///
  /// Equivalent to `this + (-offset)`.
  ///
  /// Returns a pointer to the [T] whose address is
  /// [offset] times the size of `T` before the address of this pointer.
  /// That is, `(this - offset).address == this.address - offset * sizeOf<T>()`.
  ///
  /// Also, `(this - offset).value` is equivalent to `this[-offset]`,
  /// and similarly for setting,
  external Pointer<T> operator -(int offset);
}

/// Extension on [Pointer] specialized for the type argument
/// [AbiSpecificInteger].
@Since('2.16')
extension AbiSpecificIntegerPointer<T extends AbiSpecificInteger>
    on Pointer<T> {
  /// The integer at [address].
  external int get value;

  external void set value(int value);

  /// The integer at `address + sizeOf<T>() * index`.
  external int operator [](int index);

  /// The integer at `address + sizeOf<T>() * index`.
  external void operator []=(int index, int value);

  /// Pointer arithmetic (takes element size into account).
  @Deprecated('Use operator + instead')
  external Pointer<T> elementAt(int index);

  /// A pointer to the [offset]th [T] after this one.
  ///
  /// Returns a pointer to the [T] whose address is
  /// [offset] times the size of `T` after the address of this pointer.
  /// That is `(this + offset).address == this.address + offset * sizeOf<T>()`.
  ///
  /// Also `(this + offset).value` is equivalent to `this[offset]`,
  /// and similarly for setting.
  external Pointer<T> operator +(int offset);

  /// A pointer to the [offset]th [T] before this one.
  ///
  /// Equivalent to `this + (-offset)`.
  ///
  /// Returns a pointer to the [T] whose address is
  /// [offset] times the size of `T` before the address of this pointer.
  /// That is, `(this - offset).address == this.address - offset * sizeOf<T>()`.
  ///
  /// Also, `(this - offset).value` is equivalent to `this[-offset]`,
  /// and similarly for setting,
  external Pointer<T> operator -(int offset);
}

/// Bounds checking indexing methods on [Array]s of [Pointer].
@Since('2.13')
extension PointerArray<T extends NativeType> on Array<Pointer<T>> {
  external Pointer<T> operator [](int index);

  external void operator []=(int index, Pointer<T> value);
}

/// Bounds checking indexing methods on [Array]s of [Struct].
@Since('2.13')
extension StructArray<T extends Struct> on Array<T> {
  /// This extension method must be invoked on a receiver of type `Pointer<T>`
  /// where `T` is a compile-time constant type.
  external T operator [](int index);
}

/// Bounds checking indexing methods on [Array]s of [Union].
@Since('2.14')
extension UnionArray<T extends Union> on Array<T> {
  /// This extension method must be invoked on a receiver of type `Pointer<T>`
  /// where `T` is a compile-time constant type.
  external T operator [](int index);
}

/// Bounds checking indexing methods on [Array]s of [Array].
@Since('2.13')
extension ArrayArray<T extends NativeType> on Array<Array<T>> {
  external Array<T> operator [](int index);

  external void operator []=(int index, Array<T> value);
}

/// Bounds checking indexing methods on [Array]s of [AbiSpecificInteger].
@Since('2.16')
extension AbiSpecificIntegerArray<T extends AbiSpecificInteger> on Array<T> {
  external int operator [](int index);

  external void operator []=(int index, int value);
}

@Since('3.5')
extension ArrayAddress<T extends NativeType> on Array<T> {
  /// The memory address of the underlying data.
  ///
  /// An expression of the form `expression.address` denoting this `address` can
  /// only occurr as an entire argument expression in the invocation of a leaf
  /// [Native] external function.
  ///
  /// Example:
  ///
  /// ```dart
  /// @Native<Void Function(Pointer<Int8>)>(isLeaf: true)
  /// external void myFunction(Pointer<Int8> pointer);
  ///
  /// final class MyStruct extends Struct {
  ///   @Array(10)
  ///   external Array<Int8> array;
  /// }
  ///
  /// void main() {
  ///   final array = Struct.create<MyStruct>().array;
  ///   myFunction(array.address);
  /// }
  /// ```
  ///
  /// The expression before `.address` is evaluated like the left-hand-side of
  /// an assignment, to something that gives access to the storage behind the
  /// expression, which can be used both for reading and writing. The `.address`
  /// then gives a native pointer to that storage.
  ///
  /// The `.address` is evaluated just before calling into native code when
  /// invoking a leaf [Native] external function. This ensures the Dart garbage
  /// collector will not move the object that the address points in to.
  external Pointer<T> get address;
}

@Since('3.5')
extension StructAddress<T extends Struct> on T {
  /// The memory address of the underlying data.
  ///
  /// An expression of the form `expression.address` denoting this `address` can
  /// only occurr as an entire argument expression in the invocation of a leaf
  /// [Native] external function.
  ///
  /// Example:
  ///
  /// ```dart
  /// @Native<Void Function(Pointer<MyStruct>)>(isLeaf: true)
  /// external void myFunction(Pointer<MyStruct> pointer);
  ///
  /// final class MyStruct extends Struct {
  ///   @Int8()
  ///   external int x;
  /// }
  ///
  /// void main() {
  ///   final myStruct = Struct.create<MyStruct>();
  ///   myFunction(myStruct.address);
  /// }
  /// ```
  ///
  /// The expression before `.address` is evaluated like the left-hand-side of
  /// an assignment, to something that gives access to the storage behind the
  /// expression, which can be used both for reading and writing. The `.address`
  /// then gives a native pointer to that storage.
  ///
  /// The `.address` is evaluated just before calling into native code when
  /// invoking a leaf [Native] external function. This ensures the Dart garbage
  /// collector will not move the object that the address points in to.
  external Pointer<T> get address;
}

@Since('3.5')
extension UnionAddress<T extends Union> on T {
  /// The memory address of the underlying data.
  ///
  /// An expression of the form `expression.address` denoting this `address` can
  /// only occurr as an entire argument expression in the invocation of a leaf
  /// [Native] external function.
  ///
  /// Example:
  ///
  /// ```dart
  /// @Native<Void Function(Pointer<MyUnion>)>(isLeaf: true)
  /// external void myFunction(Pointer<MyUnion> pointer);
  ///
  /// final class MyUnion extends Union {
  ///   @Int8()
  ///   external int x;
  /// }
  ///
  /// void main() {
  ///   final myUnion = Union.create<MyUnion>();
  ///   myFunction(myUnion.address);
  /// }
  /// ```
  ///
  /// The expression before `.address` is evaluated like the left-hand-side of
  /// an assignment, to something that gives access to the storage behind the
  /// expression, which can be used both for reading and writing. The `.address`
  /// then gives a native pointer to that storage.
  ///
  /// The `.address` is evaluated just before calling into native code when
  /// invoking a leaf [Native] external function. This ensures the Dart garbage
  /// collector will not move the object that the address points in to.
  external Pointer<T> get address;
}

@Since('3.5')
extension IntAddress on int {
  /// The memory address of the underlying data.
  ///
  /// An expression of the form `expression.address` denoting this `address` can
  /// only occurr as an entire argument expression in the invocation of a leaf
  /// [Native] external function.
  ///
  /// Can only be used on fields of [Struct] subtypes, fields of [Union]
  /// subtypes, [Array] elements, or [TypedData] elements. In other words, the
  /// number whose address is being accessed must itself be acccessed through a
  /// [Struct], [Union], [Array], or [TypedData].
  ///
  /// Example:
  ///
  /// ```dart import:typed_data
  /// @Native<Void Function(Pointer<Int8>)>(isLeaf: true)
  /// external void myFunction(Pointer<Int8> pointer);
  ///
  /// final class MyStruct extends Struct {
  ///   @Int8()
  ///   external int x;
  ///
  ///   @Int8()
  ///   external int y;
  ///
  ///   @Array(10)
  ///   external Array<Int8> array;
  /// }
  ///
  /// void main() {
  ///   final myStruct = Struct.create<MyStruct>();
  ///   myFunction(myStruct.y.address);
  ///   myFunction(myStruct.array[5].address);
  ///
  ///   final list = Int8List(10);
  ///   myFunction(list[5].address);
  /// }
  /// ```
  ///
  /// The expression before `.address` is evaluated like the left-hand-side of
  /// an assignment, to something that gives access to the storage behind the
  /// expression, which can be used both for reading and writing. The `.address`
  /// then gives a native pointer to that storage.
  ///
  /// The `.address` is evaluated just before calling into native code when
  /// invoking a leaf [Native] external function. This ensures the Dart garbage
  /// collector will not move the object that the address points in to.
  external Pointer<Never> address;
}

@Since('3.5')
extension DoubleAddress on double {
  /// The memory address of the underlying data.
  ///
  /// An expression of the form `expression.address` denoting this `address` can
  /// only occurr as an entire argument expression in the invocation of a leaf
  /// [Native] external function.
  ///
  /// Can only be used on fields of [Struct] subtypes, fields of [Union]
  /// subtypes, [Array] elements, or [TypedData] elements. In other words, the
  /// number whose address is being accessed must itself be acccessed through a
  /// [Struct], [Union], [Array], or [TypedData].
  ///
  /// Example:
  ///
  /// ```dart import:typed_data
  /// @Native<Void Function(Pointer<Float>)>(isLeaf: true)
  /// external void myFunction(Pointer<Float> pointer);
  ///
  /// final class MyStruct extends Struct {
  ///   @Float()
  ///   external double x;
  ///
  ///   @Float()
  ///   external double y;
  ///
  ///   @Array(10)
  ///   external Array<Float> array;
  /// }
  ///
  /// void main() {
  ///   final myStruct = Struct.create<MyStruct>();
  ///   myFunction(myStruct.y.address);
  ///   myFunction(myStruct.array[5].address);
  ///
  ///   final list = Float32List(10);
  ///   myFunction(list[5].address);
  /// }
  /// ```
  ///
  /// The expression before `.address` is evaluated like the left-hand-side of
  /// an assignment, to something that gives access to the storage behind the
  /// expression, which can be used both for reading and writing. The `.address`
  /// then gives a native pointer to that storage.
  ///
  /// The `.address` is evaluated just before calling into native code when
  /// invoking a leaf [Native] external function. This ensures the Dart garbage
  /// collector will not move the object that the address points in to.
  external Pointer<Never> address;
}

@Since('3.5')
extension BoolAddress on bool {
  /// The memory address of the underlying data.
  ///
  /// An expression of the form `expression.address` denoting this `address` can
  /// only occurr as an entire argument expression in the invocation of a leaf
  /// [Native] external function.
  ///
  /// Can only be used on fields of [Struct] subtypes, fields of [Union]
  /// subtypes, or [Array] elements. In other words, the boolean whose address
  /// is being accessed must itself be acccessed through a [Struct], [Union] or
  /// [Array].
  ///
  /// Example:
  ///
  /// ```dart
  /// @Native<Void Function(Pointer<Int8>)>(isLeaf: true)
  /// external void myFunction(Pointer<Int8> pointer);
  ///
  /// final class MyStruct extends Struct {
  ///   @Bool()
  ///   external bool x;
  ///
  ///   @Bool()
  ///   external bool y;
  ///
  ///   @Array(10)
  ///   external Array<Bool> array;
  /// }
  ///
  /// void main() {
  ///   final myStruct = Struct.create<MyStruct>();
  ///   myFunction(myStruct.y.address);
  ///   myFunction(myStruct.array[5].address);
  /// }
  /// ```
  ///
  /// The expression before `.address` is evaluated like the left-hand-side of
  /// an assignment, to something that gives access to the storage behind the
  /// expression, which can be used both for reading and writing. The `.address`
  /// then gives a native pointer to that storage.
  ///
  /// The `.address` is evaluated just before calling into native code when
  /// invoking a leaf [Native] external function. This ensures the Dart garbage
  /// collector will not move the object that the address points in to.
  external Pointer<Never> address;
}

/// Extension to retrieve the native `Dart_Port` from a [SendPort].
@Since('2.7')
extension NativePort on SendPort {
  /// The native port of this [SendPort].
  ///
  /// The returned native port can for example be used by C code to post
  /// messages to the connected [ReceivePort] via `Dart_PostCObject()` - see
  /// `dart_native_api.h`.
  ///
  /// Only the send ports from the platform classes [ReceivePort] and
  /// [RawReceivePort] are supported. User-defined implementations of
  /// [SendPort] are not supported.
  external int get nativePort;
}

/// Opaque, not exposing it's members.
@Since('2.8')
final class Dart_CObject extends Opaque {}

typedef Dart_NativeMessageHandler = Void Function(Int64, Pointer<Dart_CObject>);

/// Utilities for accessing the Dart VM API from Dart code or
/// from C code via `dart_api_dl.h`.
@Since('2.8')
abstract final class NativeApi {
  /// On breaking changes the major version is increased.
  ///
  /// The versioning covers the API surface in `dart_api_dl.h`.
  @Since('2.9')
  external static int get majorVersion;

  /// On backwards compatible changes the minor version is increased.
  ///
  /// The versioning covers the API surface in `dart_api_dl.h`.
  @Since('2.9')
  external static int get minorVersion;

  /// A function pointer to
  /// `bool Dart_PostCObject(Dart_Port port_id, Dart_CObject* message)`
  /// in `dart_native_api.h`.
  external static Pointer<
          NativeFunction<Int8 Function(Int64, Pointer<Dart_CObject>)>>
      get postCObject;

  /// A function pointer to
  /// ```c
  /// Dart_Port Dart_NewNativePort(const char* name,
  ///                              Dart_NativeMessageHandler handler,
  ///                              bool handle_concurrently)
  /// ```
  /// in `dart_native_api.h`.
  external static Pointer<
      NativeFunction<
          Int64 Function(
              Pointer<Uint8>,
              Pointer<NativeFunction<Dart_NativeMessageHandler>>,
              Int8)>> get newNativePort;

  /// A function pointer to
  /// `bool Dart_CloseNativePort(Dart_Port native_port_id)`
  /// in `dart_native_api.h`.
  external static Pointer<NativeFunction<Int8 Function(Int64)>>
      get closeNativePort;

  /// Pass this to `Dart_InitializeApiDL` in your native code to enable using the
  /// symbols in `dart_api_dl.h`.
  @Since('2.9')
  external static Pointer<Void> get initializeApiDLData;
}

/// Annotation binding an external declaration to its native implementation.
///
/// Can only be applied to `external` declarations of static and top-level
/// functions and variables.
///
/// A [Native]-annotated `external` function is implemented by native code.
/// The implementation is found in the native library denoted by [assetId].
/// Similarly, a [Native]-annotated `external` variable is implemented by
/// reading from or writing to native memory.
///
/// The compiler and/or runtime provides a binding from [assetId] to native
/// library, which depends on the target platform.
/// The compiler/runtime can then resolve/lookup symbols (identifiers)
/// against the native library, to find a native function or a native global
/// variable, and bind an `external` Dart function or variable declaration to
/// that native declaration.
/// By default, the runtime expects a native symbol with the same name as the
/// annotated function or variable in Dart. This can be overridden with the
/// [symbol] parameter on the annotation.
///
/// If this annotation is used on a function, then the type argument [T] to the
/// [Native] annotation must be a function type representing the native
/// function's parameter and return types. The parameter and return types must
/// be subtypes of [NativeType].
///
/// If this annotation is used on an external variable, then the type argument
/// [T] must be a compatible native type. For example, an [int] field can be
/// annotated with [Int32].
/// If the type argument to `@Native` is omitted, it defaults to the Dart type
/// of the annotated declaration, which *must* then be a native type too.
/// This will never work for function declarations, but can apply to variables
/// whose type is some of the types of this library, such as [Pointer].
/// For native global variables that cannot be re-assigned, a final variable in
/// Dart or a getter can be used to prevent assignments to the native field.
///
/// Example:
///
/// ```dart template:top
/// @Native<Int64 Function(Int64, Int64)>()
/// external int sum(int a, int b);
///
/// @Native<Int64>()
/// external int aGlobalInt;
///
/// @Native()
/// external final Pointer<Char> aGlobalString;
/// ```
///
/// Calling a `@Native` function, as well as reading or writing to a `@Native`
/// variable, will try to resolve the [symbol] in (in the order):
/// 1. the provided or default [assetId],
/// 2. the native resolver set with `Dart_SetFfiNativeResolver` in
///    `dart_api.h`, and
/// 3. the current process.
///
/// At least one of those three *must* provide a binding for the symbol,
/// otherwise the method call or the variable access fails.
///
/// NOTE: This is an experimental feature and may change in the future.
@Since('2.19')
final class Native<T> {
  // Implementation note: VM hardcodes the layout of this class (number and
  // order of its fields), so adding/removing/changing fields requires
  // updating the VM code (see Function::GetNativeAnnotation()).

  /// The native symbol to be resolved, if not using the default.
  ///
  /// If not specified, the default symbol used for native function lookup
  /// is the annotated function's name.
  ///
  /// Example:
  ///
  /// ```dart template:top
  /// @Native<Int64 Function(Int64, Int64)>()
  /// external int sum(int a, int b);
  /// ```
  ///
  /// Example 2:
  ///
  /// ```dart template:top
  /// @Native<Int64 Function(Int64, Int64)>(symbol: 'sum')
  /// external int sum(int a, int b);
  /// ```
  ///
  /// The above two examples are equivalent.
  ///
  /// Prefer omitting the [symbol] when possible.
  final String? symbol;

  /// The ID of the asset in which [symbol] is resolved, if not using the
  /// default.
  ///
  /// If no asset name is specified, the default is to use an asset ID
  /// specified using an [DefaultAsset] annotation on the current library's
  /// `library` declaration, and if there is no [DefaultAsset] annotation on
  /// the current library, the library's URI (as a string) is used instead.
  ///
  /// Example (file `package:a/a.dart`):
  ///
  /// ```dart template:top
  /// @Native<Int64 Function(Int64, Int64)>()
  /// external int sum(int a, int b);
  /// ```
  ///
  /// Example 2 (file `package:a/a.dart`):
  ///
  /// ```dart template:none
  /// @DefaultAsset('package:a/a.dart')
  /// library a;
  ///
  /// import 'dart:ffi';
  ///
  /// @Native<Int64 Function(Int64, Int64)>()
  /// external int sum(int a, int b);
  /// ```
  ///
  /// Example 3 (file `package:a/a.dart`):
  ///
  /// ```dart template:top
  /// @Native<Int64 Function(Int64, Int64)>(assetId: 'package:a/a.dart')
  /// external int sum(int a, int b);
  /// ```
  ///
  /// The above three examples are all equivalent.
  ///
  /// Prefer using the library URI as an asset name over specifying it.
  /// Prefer using an [DefaultAsset] on the `library` declaration
  /// over specifying the asset name in a [Native] annotation.
  final String? assetId;

  /// Whether the function is a leaf function.
  ///
  /// Leaf functions are small, short-running, non-blocking functions which are
  /// not allowed to call back into Dart or use any Dart VM APIs. Leaf functions
  /// are invoked bypassing some of the heavier parts of the standard
  /// Dart-to-Native calling sequence which reduces the invocation overhead,
  /// making leaf calls faster than non-leaf calls. However, this implies that a
  /// thread executing a leaf function can't cooperate with the Dart runtime. A
  /// long running or blocking leaf function will delay any operation which
  /// requires synchronization between all threads associated with an isolate
  /// group until after the leaf function returns. For example, if one isolate
  /// in a group is trying to perform a GC and a second isolate is blocked in a
  /// leaf call, then the first isolate will have to pause and wait until this
  /// leaf call returns.
  ///
  /// This value has no meaning for native fields.
  final bool isLeaf;

  const Native({
    this.assetId,
    this.isLeaf = false,
    this.symbol,
  });

  /// The native address of the implementation of [native].
  ///
  /// When calling this function, the argument for [native] must be an
  /// expression denoting a variable or function declaration which is annotated
  /// with [Native].
  /// For a variable declaration, the type [T] must be the same native type
  /// as the type argument to that `@Native` annotation.
  /// For a function declaration, the type [T] must be `NativeFunction<F>`
  /// where `F` was the type argument to that `@Native` annotation.
  ///
  /// For example, for a native C library exposing a function:
  ///
  /// ```C
  /// #include <stdint.h>
  /// int64_t sum(int64_t a, int64_t b) { return a + b; }
  /// ```
  ///
  /// The following code binds `sum` to a Dart function declaration, and
  /// extracts the address of the native `sum` implementation:
  ///
  /// ```dart
  /// import 'dart:ffi';
  ///
  /// typedef NativeAdd = Int64 Function(Int64, Int64);
  ///
  /// @Native<NativeAdd>()
  /// external int sum(int a, int b);
  ///
  /// void main() {
  ///   Pointer<NativeFunction<NativeAdd>> addressSum = Native.addressOf(sum);
  /// }
  /// ```
  ///
  /// Similarly, for a native C library exposing a global variable:
  ///
  /// ```C
  /// const char* myString;
  /// ```
  ///
  /// The following code binds `myString` to a top-level variable in Dart, and
  /// extracts the address of the underlying native field:
  ///
  /// ```dart
  /// import 'dart:ffi';
  ///
  /// @Native()
  /// external Pointer<Char> myString;
  ///
  /// void main() {
  ///   // This pointer points to the memory location where the loader has
  ///   // placed the `myString` global itself. To get the string value, read
  ///   // the myString field directly.
  ///   Pointer<Pointer<Char>> addressMyString = Native.addressOf(myString);
  /// }
  /// ```
  @Since('3.3')
  external static Pointer<T> addressOf<T extends NativeType>(
      @DartRepresentationOf('T') Object native);
}

/// Annotation specifying the default asset ID for the current library.
///
/// The annotation applies only to `library` declarations.
///
/// The compiler and/or runtime provides a binding from _asset ID_ to native
/// library, which depends on the target platform and architecture.
/// The compiler/runtime can resolve identifiers (symbols)
/// against the native library, looking up native function implementations
/// which are then used as the implementation of `external` Dart function
/// declarations.
///
/// If used as annotation on a `library` declaration, all [Native]-annotated
/// external functions in this library will use the specified asset [id]
/// for native function resolution (unless overridden by [Native.assetId]).
///
/// If no [DefaultAsset] annotation is provided, the current library's URI
/// is the default asset ID for [Native]-annotated external functions.
///
/// Example (file `package:a/a.dart`):
///
/// ```dart template:top
/// @Native<Int64 Function(Int64, Int64)>()
/// external int sum(int a, int b);
/// ```
///
/// Example 2 (file `package:a/a.dart`):
///
/// ```dart template:none
/// @DefaultAsset('package:a/a.dart')
/// library a;
///
/// import 'dart:ffi';
///
/// @Native<Int64 Function(Int64, Int64)>()
/// external int sum(int a, int b);
/// ```
///
/// The above two examples are equivalent.
///
/// Prefer using the library URI as asset name when possible.
///
/// NOTE: This is an experimental feature and may change in the future.
@Since('2.19')
final class DefaultAsset {
  /// The default asset name for [Native] external functions in this library.
  final String id;

  const DefaultAsset(
    this.id,
  );
}
