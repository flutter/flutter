// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.ffi;

/// Marker interface for objects which should not be finalized too soon.
///
/// Any local variable with a static type that _includes `Finalizable`_
/// is guaranteed to be alive until execution exits the code block where
/// the variable is in scope.
///
/// A type _includes `Finalizable`_ if either
/// * the type is a non-`Never` subtype of `Finalizable`, or
/// * the type is `T?` or `FutureOr<T>` where `T` includes `Finalizable`.
///
/// In other words, while an object is referenced by such a variable,
/// it is guaranteed to *not* be considered unreachable,
/// and the variable itself is considered alive for the entire duration
/// of its scope, even after it is last referenced.
///
/// _Without this marker interface on the variable's type, a variable's
/// value might be garbage collected before the surrounding scope has
/// been completely executed, as long as the variable is definitely not
/// referenced again. That can, in turn, trigger a `NativeFinalizer`
/// to perform a callback. When the variable's type includes [Finalizable],
/// The `NativeFinalizer` callback is prevented from running until
/// the current code using that variable is complete._
///
/// For example, `finalizable` is kept alive during the execution of
/// `someNativeCall`:
///
/// ```dart
/// void myFunction() {
///   final finalizable = MyFinalizable(Pointer.fromAddress(0));
///   someNativeCall(finalizable.nativeResource);
/// }
///
/// void someNativeCall(Pointer nativeResource) {
///   // ..
/// }
///
/// class MyFinalizable implements Finalizable {
///   final Pointer nativeResource;
///
///   MyFinalizable(this.nativeResource);
/// }
/// ```
///
/// Methods on a class implementing `Finalizable` keep the `this` object alive
/// for the duration of the method execution. _The `this` value is treated
/// like a local variable._
///
/// For example, `this` is kept alive during the execution of `someNativeCall`
/// in `myFunction`:
///
/// ```dart
/// class MyFinalizable implements Finalizable {
///   final Pointer nativeResource;
///
///   MyFinalizable(this.nativeResource);
///
///   void myFunction() {
///     someNativeCall(nativeResource);
///   }
/// }
///
/// void someNativeCall(Pointer nativeResource) {
///   // ..
/// }
/// ```
///
/// It is good practise to implement logic involving finalizables as methods
/// on the class that implements [Finalizable].
///
/// If a closure is created inside the block scope declaring the variable, and
/// that closure contains any reference to the variable, the variable stays
/// alive as long as the closure object does, or as long as the body of such a
/// closure is executing.
///
/// For example, `finalizable` is kept alive by the closure object and until the
/// end of the closure body:
///
/// ```dart
/// void doSomething() {
///   final resourceAction = myFunction();
///   resourceAction(); // `finalizable` is alive until this call returns.
/// }
///
/// void Function() myFunction() {
///   final finalizable = MyFinalizable(Pointer.fromAddress(0));
///   return () {
///     someNativeCall(finalizable.nativeResource);
///   };
/// }
///
/// void someNativeCall(Pointer nativeResource) {
///   // ..
/// }
///
/// class MyFinalizable implements Finalizable {
///   final Pointer nativeResource;
///
///   MyFinalizable(this.nativeResource);
/// }
/// ```
///
/// Only captured variables are kept alive by closures, not all variables.
///
/// For example, `finalizable` is not kept alive by the returned closure object:
///
/// ```dart
/// void Function() myFunction() {
///   final finalizable = MyFinalizable(Pointer.fromAddress(0));
///   final nativeResource = finalizable.nativeResource;
///   return () {
///     someNativeCall(nativeResource);
///   };
/// }
///
/// void someNativeCall(Pointer nativeResource) {
///   // ..
/// }
///
/// class MyFinalizable implements Finalizable {
///   final Pointer nativeResource;
///
///   MyFinalizable(this.nativeResource);
/// }
/// ```
///
/// It's likely an error if a resource extracted from a finalizable object
/// escapes the scope of the finalizable variable it's taken from.
///
/// The behavior of `Finalizable` variables applies to asynchronous
/// functions too. Such variables are kept alive as long as any
/// code may still execute inside the scope that declared the variable,
/// or in a closure capturing the variable,
/// even if there are asynchronous delays during that execution.
///
/// For example, `finalizable` is kept alive during the `await someAsyncCall()`:
///
/// ```dart
/// Future<void> myFunction() async {
///   final finalizable = MyFinalizable();
///   await someAsyncCall();
/// }
///
/// Future<void> someAsyncCall() async {
///   // ..
/// }
///
/// class MyFinalizable implements Finalizable {
///   // ..
/// }
/// ```
///
/// Also in asynchronous code it's likely an error if a resource extracted from
/// a finalizable object escapes the scope of the finalizable variable it's
/// taken from. If you have to extract a resource from a `Finalizable`, you
/// should ensure the scope in which Finalizable is defined outlives the
/// resource by `await`ing any asynchronous code that uses the resource.
///
/// For example, `this` is kept alive until `resource` is not used anymore in
/// `useAsync1`, but not in `useAsync2` and `useAsync3`:
///
/// ```dart
/// class MyFinalizable {
///   final Pointer<Int8> resource;
///
///   MyFinalizable(this.resource);
///
///   Future<int> useAsync1() async {
///     return await useResource(resource);
///   }
///
///   Future<int> useAsync2() async {
///     return useResource(resource);
///   }
///
///   Future<int> useAsync3() {
///     return useResource(resource);
///   }
/// }
///
/// /// Does not use [resource] after the returned future completes.
/// Future<int> useResource(Pointer<Int8> resource) async {
///   return resource.value;
/// }
/// ```
///
/// _It is possible for an asynchronous function to *stall* at an
/// `await`, such that the runtime system can see that there is no possible
/// way for that `await` to complete. In that case, no code after the
/// `await` will ever execute, including `finally` blocks, and the
/// variable may be considered dead along with everything else._
///
/// If you're not going to keep a variable alive yourself, make sure to pass the
/// finalizable object to other functions instead of just its resource.
///
/// For example, `finalizable` is not kept alive by `myFunction` after it has
/// run to the end of its scope, while `someAsyncCall` could still continue
/// execution. However, `finalizable` is kept alive by `someAsyncCall` itself:
///
/// ```dart
/// void myFunction() {
///   final finalizable = MyFinalizable();
///   someAsyncCall(finalizable);
/// }
///
/// Future<void> someAsyncCall(MyFinalizable finalizable) async {
///   // ..
/// }
///
/// class MyFinalizable implements Finalizable {
///   // ..
/// }
/// ```
// TODO(http://dartbug.com/44395): Add implicit await to Dart implementation.
// This will fix `useAsync2` above.
@Since('2.17')
abstract interface class Finalizable {
  factory Finalizable._() => throw UnsupportedError("");
}

/// The native function type for [NativeFinalizer]s.
///
/// A [NativeFinalizer]'s `callback` should have the C
/// `void nativeFinalizer(void* token)` type.
typedef NativeFinalizerFunction
    = NativeFunction<Void Function(Pointer<Void> token)>;

/// A native finalizer which can be attached to Dart objects.
///
/// When [attach]ed to a Dart object, this finalizer's native callback is called
/// after the Dart object is garbage collected or becomes inaccessible for other
/// reasons.
///
/// Callbacks will happen as early as possible, when the object becomes
/// inaccessible to the program, and may happen at any moment during execution
/// of the program. At the latest, when an isolate group shuts down,
/// this callback is guaranteed to be called for each object in that isolate
/// group that the finalizer is still attached to.
///
/// Compared to the [Finalizer] from `dart:core`, which makes no promises to
/// ever call an attached callback, this native finalizer promises that all
/// attached finalizers are definitely called at least once before the isolate
/// group shuts down, and the callbacks are called as soon as possible after
/// an object is recognized as inaccessible.
///
/// Note that an isolate group is not necessarily guaranteed to shutdown
/// normally as the whole process might crash or be abruptly terminated
/// by a function like `exit`. This means `NativeFinalizer` can not be
/// relied upon for running actions on the programs exit.
///
/// When the callback is a Dart function rather than a native function, use
/// [Finalizer] instead.
///
/// A native finalizer can be used to close native resources. See the following
/// example.
///
/// ```dart
/// /// [Database] enables interacting with the native database.
/// ///
/// /// After [close] is called, cannot be used to [query].
/// ///
/// /// If a [Database] is garbage collected, it is automatically closed by
/// /// means of a native finalizer. Prefer closing manually for timely
/// /// release of native resources.
/// ///
/// /// Note this class is incomplete and for illustration purposes only.
/// class Database implements Finalizable {
///   /// The native finalizer runs [_closeDatabasePointer] on [_nativeDatabase]
///   /// if the object is garbage collected.
///   ///
///   /// Keeps the finalizer itself reachable, otherwise it might be disposed
///   /// before the finalizer callback gets a chance to run.
///   static final _finalizer =
///       NativeFinalizer(_nativeDatabaseBindings.closeDatabaseAddress.cast());
///
///   /// The native resource.
///   ///
///   /// Should be closed exactly once with [_closeDatabase] or
///   /// [_closeDatabasePointer].
///   Pointer<_NativeDatabase> _nativeDatabase;
///
///   /// Used to prevent double close and usage after close.
///   bool _closed = false;
///
///   Database._(this._nativeDatabase);
///
///   /// Open a database.
///   factory Database.open() {
///     final nativeDatabase = _nativeDatabaseBindings.openDatabase();
///     final database = Database._(nativeDatabase);
///     _finalizer.attach(database, nativeDatabase.cast(), detach: database);
///     return database;
///   }
///
///   /// Closes this database.
///   ///
///   /// This database cannot be used anymore after it is closed.
///   void close() {
///     if (_closed) {
///       return;
///     }
///     _closed = true;
///     _finalizer.detach(this);
///     _nativeDatabaseBindings.closeDatabase(_nativeDatabase);
///   }
///
///   /// Query the database.
///   ///
///   /// The database should not have been closed.
///   void query() {
///     if (_closed) {
///       throw StateError('The database has been closed.');
///     }
///
///     // Query the database.
///   }
/// }
///
/// final _nativeDatabaseBindings = _NativeDatabaseLib(DynamicLibrary.process());
///
/// // The following classes are typically generated with `package:ffigen`.
/// // Use `symbol-address` to expose the address of the close function.
/// class _NativeDatabaseLib {
///   final DynamicLibrary _library;
///
///   _NativeDatabaseLib(this._library);
///
///   late final openDatabase = _library.lookupFunction<
///       Pointer<_NativeDatabase> Function(),
///       Pointer<_NativeDatabase> Function()>('OpenDatabase');
///   late final closeDatabaseAddress =
///       _library.lookup<NativeFunction<Void Function(Pointer<_NativeDatabase>)>>(
///           'CloseDatabase');
///   late final closeDatabase = closeDatabaseAddress
///       .asFunction<void Function(Pointer<_NativeDatabase>)>();
/// }
///
/// final class _NativeDatabase extends Opaque {}
/// ```
@Since('2.17')
abstract final class NativeFinalizer {
  /// Creates a finalizer with the given finalization callback.
  ///
  /// The [callback] must be a native function which can be executed outside of
  /// a Dart isolate. This means that passing an FFI trampoline (a function
  /// pointer obtained via [Pointer.fromFunction]) is not supported.
  ///
  /// The [callback] might be invoked on an arbitrary thread and not necessary
  /// on the same thread that created [NativeFinalizer].
  // TODO(https://dartbug.com/47778): Implement isolate independent code and
  // update the above comment.
  external factory NativeFinalizer(Pointer<NativeFinalizerFunction> callback);

  /// Attaches this finalizer to [value].
  ///
  /// When [value] is no longer accessible to the program,
  /// the finalizer will call its callback function with [token]
  /// as argument.
  ///
  /// If a non-`null` [detach] value is provided, that object can be
  /// passed to [Finalizer.detach] to remove the attachment again.
  ///
  /// The [value] and [detach] arguments do not count towards those
  /// objects being accessible to the program. Both must be objects supported
  /// as an [Expando] key. They may be the *same* object.
  ///
  /// Multiple objects may be using the same finalization token,
  /// and the finalizer can be attached multiple times to the same object
  /// with different, or the same, finalization token.
  ///
  /// The callback will be called exactly once per attachment, except for
  /// registrations which have been detached since they were attached.
  ///
  /// The [externalSize] should represent the amount of native (non-Dart) memory
  /// owned by the given [value]. This information is used for garbage
  /// collection scheduling heuristics.
  void attach(Finalizable value, Pointer<Void> token,
      {Object? detach, int? externalSize});

  /// Detaches this finalizer from values attached with [detach].
  ///
  /// If this finalizer was attached multiple times to the same object with
  /// different detachment keys, only those attachments which used [detach]
  /// are removed.
  ///
  /// After detaching, an attachment won't cause any callbacks to happen if the
  /// object become inaccessible.
  void detach(Object detach);
}

// To make dart2wasm compile without patch file.
external void _attachAsTypedListFinalizer(
  Pointer<NativeFinalizerFunction> callback,
  Object typedList,
  Pointer pointer,
  int? externalSize,
);
