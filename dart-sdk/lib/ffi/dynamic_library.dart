// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.ffi;

/// A dynamically loaded native library.
///
/// A dynamically loaded library is a mapping from symbols to memory addresses.
/// These memory addresses can be accessed through [lookup].
final class DynamicLibrary {
  /// Creates a [DynamicLibrary] holding all global symbols.
  ///
  /// Any symbol in a library currently loaded with global visibility
  /// (including the executable itself) may be resolved through this library.
  external factory DynamicLibrary.process();

  /// Creates a [DynamicLibrary] containing all the symbols of the running
  /// executable.
  ///
  /// This is useful for using dart:ffi with static libraries.
  external factory DynamicLibrary.executable();

  /// Loads a library file and provides access to its symbols.
  ///
  /// The [path] must refer to a native library file which can be successfully
  /// loaded.
  ///
  /// Calling this function multiple times with the same [path], even across
  /// different isolates, only loads the library into the DartVM process once.
  /// Multiple loads of the same library file produces [DynamicLibrary] objects
  /// which are equal (`==`), but not [identical].
  external factory DynamicLibrary.open(String path);

  /// Looks up a symbol in the [DynamicLibrary] and returns its address in
  /// memory.
  ///
  /// Similar to the functionality of the
  /// [dlsym(3)](https://man7.org/linux/man-pages/man3/dlsym.3.html) system
  /// call.
  ///
  /// The symbol must be provided by the dynamic library. To check whether
  /// the library provides such symbol, use [providesSymbol].
  external Pointer<T> lookup<T extends NativeType>(String symbolName);

  /// Checks whether this dynamic library provides a symbol with the given
  /// name.
  @Since('2.14')
  external bool providesSymbol(String symbolName);

  /// Closes this dynamic library.
  ///
  /// After calling [close], this library object can no longer be used for
  /// lookups. Further, this information is forwarded to the operating system,
  /// which may unload the library if there are no remaining references to it
  /// in the current process.
  ///
  /// Depending on whether another reference to this library has been opened,
  /// pointers and functions previously returned by [lookup] and
  /// [DynamicLibraryExtension.lookupFunction] may become invalid as well.
  @Since('3.1')
  external void close();

  /// Dynamic libraries are equal if they load the same library.
  external bool operator ==(Object other);

  /// The hash code for a [DynamicLibrary] only depends on the loaded library.
  external int get hashCode;

  /// The opaque handle to the dynamic library.
  ///
  /// Similar to the return value of
  /// [dlopen(3)](https://man7.org/linux/man-pages/man3/dlopen.3.html).
  /// Can be used as arguments to other functions in the `dlopen` API
  /// through FFI calls.
  external Pointer<Void> get handle;
}

/// Method which must not be invoked dynamically.
extension DynamicLibraryExtension on DynamicLibrary {
  /// Looks up a native function and returns it as a Dart function.
  ///
  /// [T] is the C function signature, and [F] is the Dart function signature.
  ///
  /// For example:
  ///
  /// ```c
  /// int32_t add(int32_t a, int32_t b) {
  ///   return a + b;
  /// }
  /// ```
  ///
  /// ```dart
  /// DynamicLibrary dylib = DynamicLibrary.executable();
  /// final add = dylib.lookupFunction<Int32 Function(Int32, Int32), int Function(int, int)>(
  ///         'add');
  /// ```
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
  external F lookupFunction<T extends Function, F extends Function>(
      String symbolName,
      {bool isLeaf = false});
}
