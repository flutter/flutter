// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

/// A type representing values that are either `Future<T>` or `T`.
///
/// This class declaration is a public stand-in for an internal
/// future-or-value generic type, which is not a class type.
/// References to this class are resolved to the internal type.
///
/// It is a compile-time error for any class to extend, mix in or implement
/// `FutureOr`.
///
/// ### Examples
///
/// ```dart
/// // The `Future<T>.then` function takes a callback [f] that returns either
/// // an `S` or a `Future<S>`.
/// Future<S> then<S>(FutureOr<S> f(T x), ...);
///
/// // `Completer<T>.complete` takes either a `T` or `Future<T>`.
/// void complete(FutureOr<T> value);
/// ```
///
/// ### Advanced
///
/// The `FutureOr<int>` type is actually the "type union" of the types `int` and
/// `Future<int>`. This type union is defined in such a way that
/// `FutureOr<Object>` is both a super- and sub-type of `Object` (sub-type
/// because `Object` is one of the types of the union, super-type because
/// `Object` is a super-type of both of the types of the union). Together it
/// means that `FutureOr<Object>` is equivalent to `Object`.
///
/// As a corollary, `FutureOr<Object>` is equivalent to
/// `FutureOr<FutureOr<Object>>`, `FutureOr<Future<Object>>` is equivalent to
/// `Future<Object>`.
@pragma("vm:entry-point")
abstract class FutureOr<T> {
  // Private generative constructor, so that it is not subclassable, mixable,
  // or instantiable.
  FutureOr._() {
    throw new UnsupportedError("FutureOr cannot be instantiated");
  }
}

/// The result of an asynchronous computation.
///
/// An _asynchronous computation_ cannot provide a result immediately
/// when it is started, unlike a synchronous computation which does compute
/// a result immediately by either returning a value or by throwing.
/// An asynchronous computation may need to wait for something external
/// to the program (reading a file, querying a database, fetching a web page)
/// which takes time.
/// Instead of blocking all computation until the result is available,
/// the asynchronous computation immediately returns a `Future`
/// which will *eventually* "complete" with the result.
///
/// ### Asynchronous programming
///
/// To perform an asynchronous computation, you use an `async` function
/// which always produces a future.
/// Inside such an asynchronous function, you can use the `await` operation
/// to delay execution until another asynchronous computation has a result.
/// While execution of the awaiting function is delayed,
/// the program is not blocked, and can continue doing other things.
///
/// Example:
/// ```dart
/// import "dart:io";
/// Future<bool> fileContains(String path, String needle) async {
///    var haystack = await File(path).readAsString();
///    return haystack.contains(needle);
/// }
/// ```
/// Here the `File.readAsString` method from `dart:io` is an asynchronous
/// function returning a `Future<String>`.
/// The `fileContains` function is marked with `async` right before its body,
/// which means that you can use `await` inside it,
/// and that it must return a future.
/// The call to `File(path).readAsString()` initiates reading the file into
/// a string and produces a `Future<String>` which will eventually contain the
/// result.
/// The `await` then waits for that future to complete with a string
/// (or an error, if reading the file fails).
/// While waiting, the program can do other things.
/// When the future completes with a string, the `fileContains` function
/// computes a boolean and returns it, which then completes the original
/// future that it returned when first called.
///
/// If a future completes with an *error*, awaiting that future will
/// (re-)throw that error. In the example here, we can add error checking:
/// ```dart
/// import "dart:io";
/// Future<bool> fileContains(String path, String needle) async {
///   try {
///     var haystack = await File(path).readAsString();
///     return haystack.contains(needle);
///   } on FileSystemException catch (exception, stack) {
///     _myLog.logError(exception, stack);
///     return false;
///   }
/// }
/// ```
/// You use a normal `try`/`catch` to catch the failures of awaited
/// asynchronous computations.
///
/// In general, when writing asynchronous code, you should always await a
/// future when it is produced, and not wait until after another asynchronous
/// delay. That ensures that you are ready to receive any error that the
/// future might produce, which is important because an asynchronous error
/// that no-one is awaiting is an *uncaught* error and may terminate
/// the running program.
///
/// ### Programming with the `Future` API.
///
/// The `Future` class also provides a more direct, low-level functionality
/// for accessing the result that it completes with.
/// The `async` and `await` language features are built on top of this
/// functionality, and it sometimes makes sense to use it directly.
/// There are things that you cannot do by just `await`ing one future at
/// a time.
///
/// With a [Future], you can manually register callbacks
/// that handle the value, or error, once it is available.
/// For example:
/// ```dart
/// Future<int> future = getFuture();
/// future.then((value) => handleValue(value))
///       .catchError((error) => handleError(error));
/// ```
/// Since a [Future] can be completed in two ways,
/// either with a value (if the asynchronous computation succeeded)
/// or with an error (if the computation failed),
/// you can install callbacks for either or both cases.
///
/// In some cases we say that a future is completed *with another future*.
/// This is a short way of stating that the future is completed in the same way,
/// with the same value or error,
/// as the other future once that other future itself completes.
/// Most functions in the platform libraries that complete a future
/// (for example [Completer.complete] or [Future.value]),
/// also accepts another future, and automatically handles forwarding
/// the result to the future being completed.
///
/// The result of registering callbacks is itself a `Future`,
/// which in turn is completed with the result of invoking the
/// corresponding callback with the original future's result.
/// The new future is completed with an error if the invoked callback throws.
/// For example:
/// ```dart
/// Future<int> successor = future.then((int value) {
///     // Invoked when the future is completed with a value.
///     return 42;  // The successor is completed with the value 42.
///   },
///   onError: (e) {
///     // Invoked when the future is completed with an error.
///     if (canHandle(e)) {
///       return 499;  // The successor is completed with the value 499.
///     } else {
///       throw e;  // The successor is completed with the error e.
///     }
///   });
/// ```
///
/// If a future does not have any registered handler when it completes
/// with an error, it forwards the error to an "uncaught-error handler".
/// This behavior ensures that no error is silently dropped.
/// However, it also means that error handlers should be installed early,
/// so that they are present as soon as a future is completed with an error.
/// The following example demonstrates this potential bug:
/// ```dart
/// var future = getFuture();
/// Timer(const Duration(milliseconds: 5), () {
///   // The error-handler is not attached until 5 ms after the future has
///   // been received. If the future fails before that, the error is
///   // forwarded to the global error-handler, even though there is code
///   // (just below) to eventually handle the error.
///   future.then((value) { useValue(value); },
///               onError: (e) { handleError(e); });
/// });
/// ```
///
/// When registering callbacks, it's often more readable to register the two
/// callbacks separately, by first using [then] with one argument
/// (the value handler) and using a second [catchError] for handling errors.
/// Each of these will forward the result that they don't handle
/// to their successors, and together they handle both value and error result.
/// It has the additional benefit of the [catchError] handling errors in the
/// [then] value callback too.
/// Using sequential handlers instead of parallel ones often leads to code that
/// is easier to reason about.
/// It also makes asynchronous code very similar to synchronous code:
/// ```dart
/// // Synchronous code.
/// try {
///   int value = foo();
///   return bar(value);
/// } catch (e) {
///   return 499;
/// }
/// ```
///
/// Equivalent asynchronous code, based on futures:
/// ```dart
/// Future<int> asyncValue = Future(foo);  // Result of foo() as a future.
/// asyncValue.then((int value) {
///   return bar(value);
/// }).catchError((e) {
///   return 499;
/// });
/// ```
///
/// Similar to the synchronous code, the error handler (registered with
/// [catchError]) is handling any errors thrown by either `foo` or `bar`.
/// If the error-handler had been registered as the `onError` parameter of
/// the `then` call, it would not catch errors from the `bar` call.
///
/// Futures can have more than one callback-pair registered. Each successor is
/// treated independently and is handled as if it was the only successor.
/// The order in which the individual successors are completed is undefined.
///
/// A future may also fail to ever complete. In that case, no callbacks are
/// called. That situation should generally be avoided if possible, unless
/// it's very clearly documented.
@pragma("wasm:entry-point")
@vmIsolateUnsendable
abstract interface class Future<T> {
  /// A `Future<Null>` completed with `null`.
  ///
  /// Currently shared with `dart:internal`.
  /// If that future can be removed, then change this back to
  /// `_Future<Null>.zoneValue(null, _rootZone);`
  static final _Future<Null> _nullFuture = nullFuture as _Future<Null>;

  /// A `Future<bool>` completed with `false`.
  static final _Future<bool> _falseFuture =
      new _Future<bool>.zoneValue(false, _rootZone);

  /// Creates a future containing the result of calling [computation]
  /// asynchronously with [Timer.run].
  ///
  /// If the result of executing [computation] throws, the returned future is
  /// completed with the error.
  ///
  /// If the returned value is itself a [Future], completion of
  /// the created future will wait until the returned future completes,
  /// and will then complete with the same result.
  ///
  /// If a non-future value is returned, the returned future is completed
  /// with that value.
  factory Future(FutureOr<T> computation()) {
    _Future<T> result = new _Future<T>();
    Timer.run(() {
      FutureOr<T> computationResult;
      try {
        computationResult = computation();
      } catch (e, s) {
        _completeWithErrorCallback(result, e, s);
        return;
      }
      result._complete(computationResult);
    });
    return result;
  }

  /// Creates a future containing the result of calling [computation]
  /// asynchronously with [scheduleMicrotask].
  ///
  /// If executing [computation] throws,
  /// the returned future is completed with the thrown error.
  ///
  /// If calling [computation] returns a [Future], completion of
  /// the created future will wait until the returned future completes,
  /// and will then complete with the same result.
  ///
  /// If calling [computation] returns a non-future value,
  /// the returned future is completed with that value.
  factory Future.microtask(FutureOr<T> computation()) {
    _Future<T> result = new _Future<T>();
    scheduleMicrotask(() {
      FutureOr<T> computationResult;
      try {
        computationResult = computation();
      } catch (e, s) {
        _completeWithErrorCallback(result, e, s);
        return;
      }
      result._complete(computationResult);
    });
    return result;
  }

  /// Returns a future containing the result of immediately calling
  /// [computation].
  ///
  /// If calling [computation] throws, the returned future is completed with the
  /// error.
  ///
  /// If calling [computation] returns a `Future<T>`, that future is returned.
  ///
  /// If calling [computation] returns a non-future value,
  /// a future is returned which has been completed with that value.
  ///
  /// Example:
  /// ```dart
  /// final result = await Future<int>.sync(() => 12);
  /// ```
  factory Future.sync(FutureOr<T> computation()) {
    FutureOr<T> result;
    try {
      result = computation();
    } catch (error, stackTrace) {
      var future = new _Future<T>();
      AsyncError? replacement = Zone.current.errorCallback(error, stackTrace);
      if (replacement != null) {
        future._asyncCompleteError(replacement.error, replacement.stackTrace);
      } else {
        future._asyncCompleteError(error, stackTrace);
      }
      return future;
    }
    return result is Future<T> ? result : _Future<T>.value(result);
  }

  /// Creates a future completed with [value].
  ///
  /// If [value] is a future, the created future waits for the
  /// [value] future to complete, and then completes with the same result.
  /// Since a [value] future can complete with an error, so can the future
  /// created by [Future.value], even if the name suggests otherwise.
  ///
  /// If [value] is not a [Future], the created future is completed
  /// with the [value] value,
  /// equivalently to `new Future<T>.sync(() => value)`.
  ///
  /// If [value] is omitted or `null`, it is converted to `FutureOr<T>` by
  /// `value as FutureOr<T>`. If `T` is not nullable, then a non-`null` [value]
  /// must be provided, otherwise the construction throws.
  ///
  /// Use [Completer] to create a future now and complete it later.
  ///
  /// Example:
  /// ```dart
  /// Future<int> getFuture() {
  ///  return Future<int>.value(2021);
  /// }
  ///
  /// final result = await getFuture();
  /// ```
  @pragma("vm:entry-point")
  @pragma("vm:prefer-inline")
  factory Future.value([FutureOr<T>? value]) {
    return new _Future<T>.immediate(value == null ? value as T : value);
  }

  /// Creates a future that completes with an error.
  ///
  /// The created future will be completed with an error in a future microtask.
  /// This allows enough time for someone to add an error handler on the future.
  /// If an error handler isn't added before the future completes, the error
  /// will be considered unhandled.
  ///
  /// Use [Completer] to create a future and complete it later.
  ///
  /// Example:
  /// ```dart
  /// Future<int> getFuture() {
  ///  return Future.error(Exception('Issue'));
  /// }
  ///
  /// final error = await getFuture(); // Throws.
  /// ```
  factory Future.error(Object error, [StackTrace? stackTrace]) {
    // TODO(40614): Remove once non-nullability is sound.
    checkNotNullable(error, "error");
    if (!identical(Zone.current, _rootZone)) {
      AsyncError? replacement = Zone.current.errorCallback(error, stackTrace);
      if (replacement != null) {
        error = replacement.error;
        stackTrace = replacement.stackTrace;
      }
    }
    stackTrace ??= AsyncError.defaultStackTrace(error);
    return new _Future<T>.immediateError(error, stackTrace);
  }

  /// Creates a future that runs its computation after a delay.
  ///
  /// The [computation] will be executed after the given [duration] has passed,
  /// and the future is completed with the result of the computation.
  ///
  /// If [computation] returns a future,
  /// the future returned by this constructor will complete with the value or
  /// error of that future.
  ///
  /// If the duration is 0 or less,
  /// it completes no sooner than in the next event-loop iteration,
  /// after all microtasks have run.
  ///
  /// If [computation] is omitted,
  /// it will be treated as if [computation] was `() => null`,
  /// and the future will eventually complete with the `null` value.
  /// In that case, [T] must be nullable.
  ///
  /// If calling [computation] throws, the created future will complete with the
  /// error.
  ///
  /// See also [Completer] for a way to create and complete a future at a
  /// later time that isn't necessarily after a known fixed duration.
  ///
  /// Example:
  /// ```dart
  /// Future.delayed(const Duration(seconds: 1), () {
  ///   print('One second has passed.'); // Prints after 1 second.
  /// });
  /// ```
  factory Future.delayed(Duration duration, [FutureOr<T> computation()?]) {
    if (computation == null && !typeAcceptsNull<T>()) {
      throw ArgumentError.value(
          null, "computation", "The type parameter is not nullable");
    }
    _Future<T> result = _Future<T>();
    new Timer(duration, () {
      if (computation == null) {
        result._complete(null as T);
      } else {
        FutureOr<T> computationResult;
        try {
          computationResult = computation();
        } catch (e, s) {
          _completeWithErrorCallback(result, e, s);
          return;
        }
        result._complete(computationResult);
      }
    });
    return result;
  }

  /// Waits for multiple futures to complete and collects their results.
  ///
  /// Returns a future which will complete once all the provided futures
  /// have completed, either with their results, or with an error if any
  /// of the provided futures fail.
  ///
  /// The value of the returned future will be a list of all the values that
  /// were produced in the order that the futures are provided by iterating
  /// [futures].
  ///
  /// If any future completes with an error,
  /// then the returned future completes with that error.
  /// If further futures also complete with errors, those errors are discarded.
  ///
  /// If `eagerError` is true, the returned future completes with an error
  /// immediately on the first error from one of the futures. Otherwise all
  /// futures must complete before the returned future is completed (still with
  /// the first error; the remaining errors are silently dropped).
  ///
  /// In the case of an error, [cleanUp] (if provided), is invoked on any
  /// non-null result of successful futures.
  /// This makes it possible to `cleanUp` resources that would otherwise be
  /// lost (since the returned future does not provide access to these values).
  /// The [cleanUp] function is unused if there is no error.
  ///
  /// The call to [cleanUp] should not throw. If it does, the error will be an
  /// uncaught asynchronous error.
  ///
  /// Example:
  /// ```dart
  /// void main() async {
  ///   var value = await Future.wait([delayedNumber(), delayedString()]);
  ///   print(value); // [2, result]
  /// }
  ///
  /// Future<int> delayedNumber() async {
  ///   await Future.delayed(const Duration(seconds: 2));
  ///   return 2;
  /// }
  ///
  /// Future<String> delayedString() async {
  ///   await Future.delayed(const Duration(seconds: 2));
  ///   return 'result';
  /// }
  /// ```
  static Future<List<T>> wait<T>(Iterable<Future<T>> futures,
      {bool eagerError = false, void cleanUp(T successValue)?}) {
    @pragma('vm:awaiter-link')
    final _Future<List<T>> _future = _Future<List<T>>();
    List<T?>? values; // Collects the values. Set to null on error.
    int remaining = 0; // How many futures are we waiting for.
    Object? error; // The first error from a future.
    StackTrace? stackTrace; // The stackTrace that came with the error.

    // Handle an error from any of the futures.
    void handleError(Object theError, StackTrace theStackTrace) {
      var remainingResults = --remaining;
      List<T?>? valueList = values;
      if (valueList != null) {
        // First error, set state to represent error having already happened.
        values = null;
        error = theError;
        stackTrace = theStackTrace;
        // Then clean up any already successfully produced results.
        if (cleanUp != null) {
          for (var value in valueList) {
            if (value != null) {
              // Ensure errors from `cleanUp` are uncaught.
              T cleanUpValue = value;
              Future.sync(() {
                cleanUp(cleanUpValue);
              });
            }
          }
        }
        if (remainingResults == 0 || eagerError) {
          _future._completeError(theError, theStackTrace);
        }
      } else {
        // Not the first error.
        if (remainingResults == 0 && !eagerError) {
          // Last future completed, non-eagerly report the first error.
          _future._completeError(error!, stackTrace!);
        }
      }
    }

    try {
      // As each future completes, put its value into the corresponding
      // position in the list of values.
      for (var future in futures) {
        int pos = remaining;
        future.then((T value) {
          var remainingResults = --remaining;
          List<T?>? valueList = values;
          if (valueList != null) {
            // No errors yet.
            assert(valueList[pos] == null);
            valueList[pos] = value;
            if (remainingResults == 0) {
              _future._completeWithValue(
                  [for (var value in valueList) value as T]);
            }
          } else {
            // Prior error, clean-up this value if necessary.
            if (cleanUp != null && value != null) {
              // Ensure errors from cleanUp are uncaught.
              Future.sync(() {
                cleanUp(value);
              });
            }
            if (remainingResults == 0 && !eagerError) {
              // Last future completed, non-eagerly report the first error.
              _future._completeError(error!, stackTrace!);
            }
          }
        }, onError: handleError);
        // Increment the 'remaining' after the call to 'then'.
        // If that call throws, we don't expect any future callback from
        // the future, and we also don't increment remaining.
        remaining++;
      }
      if (remaining == 0) {
        // No elements in iterable.
        return _future.._completeWithValue(<T>[]);
      }
      values = List<T?>.filled(remaining, null);
    } catch (e, st) {
      // The error must have been thrown while iterating over the futures
      // list, or while installing a callback handler on the future.
      // This is a breach of the `Future` protocol, but we try to handle it
      // gracefully.
      if (remaining == 0 || eagerError) {
        // Throw a new Future.error.
        // Don't just call `_future._completeError` since that would propagate
        // the error too eagerly, not giving the callers time to install
        // error handlers.
        // Also, don't use `_asyncCompleteError` since that one doesn't give
        // zones the chance to intercept the error.
        return new Future.error(e, st);
      } else {
        // Don't allocate a list for values, thus indicating that there was an
        // error.
        // Set error to the caught exception.
        error = e;
        stackTrace = st;
      }
    }
    return _future;
  }

  /// Returns the result of the first future in [futures] to complete.
  ///
  /// The returned future is completed with the result of the first
  /// future in [futures] to report that it is complete,
  /// whether it's with a value or an error.
  /// The results of all the other futures are discarded.
  ///
  /// If [futures] is empty, or if none of its futures complete,
  /// the returned future never completes.
  ///
  /// Example:
  /// ```dart
  /// void main() async {
  ///   final result =
  ///       await Future.any([slowInt(), delayedString(), fastInt()]);
  ///   // The future of fastInt completes first, others are ignored.
  ///   print(result); // 3
  /// }
  /// Future<int> slowInt() async {
  ///   await Future.delayed(const Duration(seconds: 2));
  ///   return 2;
  /// }
  ///
  /// Future<String> delayedString() async {
  ///   await Future.delayed(const Duration(seconds: 2));
  ///   throw TimeoutException('Time has passed');
  /// }
  ///
  /// Future<int> fastInt() async {
  ///   await Future.delayed(const Duration(seconds: 1));
  ///   return 3;
  /// }
  /// ```
  static Future<T> any<T>(Iterable<Future<T>> futures) {
    var completer = new Completer<T>.sync();
    void onValue(T value) {
      if (!completer.isCompleted) completer.complete(value);
    }

    void onError(Object error, StackTrace stack) {
      if (!completer.isCompleted) completer.completeError(error, stack);
    }

    for (var future in futures) {
      future.then(onValue, onError: onError);
    }
    return completer.future;
  }

  /// Performs an action for each element of the iterable, in turn.
  ///
  /// The [action] may be either synchronous or asynchronous.
  ///
  /// Calls [action] with each element in [elements] in order.
  /// If the call to [action] returns a `Future<T>`, the iteration waits
  /// until the future is completed before continuing with the next element.
  ///
  /// Returns a [Future] that completes with `null` when all elements have been
  /// processed.
  ///
  /// Non-[Future] return values, and completion-values of returned [Future]s,
  /// are discarded.
  ///
  /// Any error from [action], synchronous or asynchronous,
  /// will stop the iteration and be reported in the returned [Future].
  static Future<void> forEach<T>(
      Iterable<T> elements, FutureOr action(T element)) {
    var iterator = elements.iterator;
    return doWhile(() {
      if (!iterator.moveNext()) return false;
      var result = action(iterator.current);
      if (result is Future) return result.then(_kTrue);
      return true;
    });
  }

  // Constant `true` function, used as callback by [forEach].
  static bool _kTrue(Object? _) => true;

  /// Performs an operation repeatedly until it returns `false`.
  ///
  /// The operation, [action], may be either synchronous or asynchronous.
  ///
  /// The operation is called repeatedly as long as it returns either the [bool]
  /// value `true` or a `Future<bool>` which completes with the value `true`.
  ///
  /// If a call to [action] returns `false` or a [Future] that completes to
  /// `false`, iteration ends and the future returned by [doWhile] is completed
  /// with a `null` value.
  ///
  /// If a call to [action] throws or a future returned by [action] completes
  /// with an error, iteration ends and the future returned by [doWhile]
  /// completes with the same error.
  ///
  /// Calls to [action] may happen at any time,
  /// including immediately after calling `doWhile`.
  /// The only restriction is a new call to [action] won't happen before
  /// the previous call has returned, and if it returned a `Future<bool>`, not
  /// until that future has completed.
  ///
  /// Example:
  /// ```dart
  /// void main() async {
  ///   var value = 0;
  ///   await Future.doWhile(() async {
  ///     value++;
  ///     await Future.delayed(const Duration(seconds: 1));
  ///     if (value == 3) {
  ///       print('Finished with $value');
  ///       return false;
  ///     }
  ///     return true;
  ///   });
  /// }
  /// // Outputs: 'Finished with 3'
  /// ```
  static Future<void> doWhile(FutureOr<bool> action()) {
    _Future<void> doneSignal = new _Future<void>();
    late void Function(bool) nextIteration;
    // Bind this callback explicitly so that each iteration isn't bound in the
    // context of all the previous iterations' callbacks.
    // This avoids, e.g., deeply nested stack traces from the stack trace
    // package.
    nextIteration = Zone.current.bindUnaryCallbackGuarded((bool keepGoing) {
      while (keepGoing) {
        FutureOr<bool> result;
        try {
          result = action();
        } catch (error, stackTrace) {
          // Cannot use _completeWithErrorCallback because it completes
          // the future synchronously.
          _asyncCompleteWithErrorCallback(doneSignal, error, stackTrace);
          return;
        }
        if (result is Future<bool>) {
          result.then(nextIteration, onError: doneSignal._completeError);
          return;
        }
        keepGoing = result;
      }
      doneSignal._complete(null);
    });
    nextIteration(true);
    return doneSignal;
  }

  /// Register callbacks to be called when this future completes.
  ///
  /// When this future completes with a value,
  /// the [onValue] callback will be called with that value.
  /// If this future is already completed, the callback will not be called
  /// immediately, but will be scheduled in a later microtask.
  ///
  /// If [onError] is provided, and this future completes with an error,
  /// the `onError` callback is called with that error and its stack trace.
  /// The `onError` callback must accept either one argument or two arguments
  /// where the latter is a [StackTrace].
  /// If `onError` accepts two arguments,
  /// it is called with both the error and the stack trace,
  /// otherwise it is called with just the error object.
  /// The `onError` callback must return a value or future that can be used
  /// to complete the returned future, so it must be something assignable to
  /// `FutureOr<R>`.
  ///
  /// Returns a new [Future]
  /// which is completed with the result of the call to `onValue`
  /// (if this future completes with a value)
  /// or to `onError` (if this future completes with an error).
  ///
  /// If the invoked callback throws,
  /// the returned future is completed with the thrown error
  /// and a stack trace for the error.
  /// In the case of `onError`,
  /// if the exception thrown is `identical` to the error argument to `onError`,
  /// and it is thrown *synchronously*
  /// the throw is considered a rethrow,
  /// and the original stack trace is used instead.
  /// To rethrow with the same stack trace in an asynchronous callback,
  /// use [Error.throwWithStackTrace].
  ///
  /// If the callback returns a [Future],
  /// the future returned by `then` will be completed with
  /// the same result as the future returned by the callback.
  ///
  /// If [onError] is not given, and this future completes with an error,
  /// the error is forwarded directly to the returned future.
  ///
  /// In most cases, it is more readable to use [catchError] separately,
  /// possibly with a `test` parameter,
  /// instead of handling both value and error in a single [then] call.
  ///
  /// Note that futures don't delay reporting of errors until listeners are
  /// added. If the first `then` or `catchError` call happens
  /// after this future has completed with an error,
  /// then the error is reported as unhandled error.
  /// See the description on [Future].
  Future<R> then<R>(FutureOr<R> onValue(T value), {Function? onError});

  /// Handles errors emitted by this [Future].
  ///
  /// This is the asynchronous equivalent of a "catch" block.
  ///
  /// Returns a new [Future] that will be completed with either the result of
  /// this future or the result of calling the `onError` callback.
  ///
  /// If this future completes with a value,
  /// the returned future completes with the same value.
  ///
  /// If this future completes with an error,
  /// then [test] is first called with the error value.
  ///
  /// If `test` returns false, the exception is not handled by this `catchError`,
  /// and the returned future completes with the same error and stack trace
  /// as this future.
  ///
  /// If `test` returns `true`,
  /// [onError] is called with the error and possibly stack trace,
  /// and the returned future is completed with the result of this call
  /// in exactly the same way as for [then]'s `onError`.
  ///
  /// If `test` is omitted, it defaults to a function that always returns true.
  /// The `test` function should not throw, but if it does, it is handled as
  /// if the `onError` function had thrown.
  ///
  /// Note that futures don't delay reporting of errors until listeners are
  /// added. If the first `catchError` (or `then`) call happens after this future
  /// has completed with an error then the error is reported as unhandled error.
  /// See the description on [Future].
  ///
  /// Example:
  /// ```dart
  /// Future.delayed(
  ///   const Duration(seconds: 1),
  ///   () => throw 401,
  /// ).then((value) {
  ///   throw 'Unreachable';
  /// }).catchError((err) {
  ///   print('Error: $err'); // Prints 401.
  /// }, test: (error) {
  ///   return error is int && error >= 400;
  /// });
  /// ```
  // The `Function` below stands for one of two types:
  // - (dynamic) -> FutureOr<T>
  // - (dynamic, StackTrace) -> FutureOr<T>
  // Given that there is a `test` function that is usually used to do an
  // `is` check, we should also expect functions that take a specific argument.
  Future<T> catchError(Function onError, {bool test(Object error)?});

  /// Registers a function to be called when this future completes.
  ///
  /// The [action] function is called when this future completes, whether it
  /// does so with a value or with an error.
  ///
  /// This is the asynchronous equivalent of a "finally" block.
  ///
  /// The future returned by this call, `f`, will complete the same way
  /// as this future unless an error occurs in the [action] call, or in
  /// a [Future] returned by the [action] call. If the call to [action]
  /// does not return a future, its return value is ignored.
  ///
  /// If the call to [action] throws, then `f` is completed with the
  /// thrown error.
  ///
  /// If the call to [action] returns a [Future], `f2`, then completion of
  /// `f` is delayed until `f2` completes. If `f2` completes with
  /// an error, that will be the result of `f` too. The value of `f2` is always
  /// ignored.
  ///
  /// This method is equivalent to:
  /// ```dart
  /// Future<T> whenComplete(action()) {
  ///   return this.then((v) {
  ///     var f2 = action();
  ///     if (f2 is Future) return f2.then((_) => v);
  ///     return v;
  ///   }, onError: (e) {
  ///     var f2 = action();
  ///     if (f2 is Future) return f2.then((_) { throw e; });
  ///     throw e;
  ///   });
  /// }
  /// ```
  /// Example:
  /// ```dart
  /// void main() async {
  ///   var value =
  ///       await waitTask().whenComplete(() => print('do something here'));
  ///   // Prints "do something here" after waitTask() completed.
  ///   print(value); // Prints "done"
  /// }
  ///
  /// Future<String> waitTask() {
  ///   Future.delayed(const Duration(seconds: 5));
  ///   return Future.value('done');
  /// }
  /// // Outputs: 'do some work here' after waitTask is completed.
  /// ```
  Future<T> whenComplete(FutureOr<void> action());

  /// Creates a [Stream] containing the result of this future.
  ///
  /// The stream will produce single data or error event containing the
  /// completion result of this future, and then it will close with a
  /// done event.
  ///
  /// If the future never completes, the stream will not produce any events.
  Stream<T> asStream();

  /// Stop waiting for this future after [timeLimit] has passed.
  ///
  /// Creates a new _timeout future_ that completes
  /// with the same result as this future, the _source future_,
  /// *if* the source future completes in time.
  ///
  /// If the source future does not complete before [timeLimit] has passed,
  /// the [onTimeout] action is executed,
  /// and its result (whether it returns or throws)
  /// is used as the result of the timeout future.
  /// The [onTimeout] function must return a [T] or a `Future<T>`.
  /// If [onTimeout] returns a future, the _alternative result future_,
  /// the eventual result of the alternative result future is used
  /// to complete the timeout future,
  /// even if the source future completes
  /// before the alternative result future.
  /// It only matters that the source future did not complete in time.
  ///
  /// If `onTimeout` is omitted, a timeout will cause the returned future to
  /// complete with a [TimeoutException].
  ///
  /// In either case, the source future can still complete normally
  /// at a later time.
  /// It just won't be used as the result of the timeout future
  /// unless it completes within the time bound.
  /// Even if the source future completes with an error,
  /// if that error happens after [timeLimit] has passed,
  /// the error is ignored, just like a value result would be.
  ///
  /// Examples:
  /// ```dart
  /// void main() async {
  ///   var result =
  ///       await waitTask("completed").timeout(const Duration(seconds: 10));
  ///   print(result); // Prints "completed" after 5 seconds.
  ///
  ///   result = await waitTask("completed")
  ///       .timeout(const Duration(seconds: 1), onTimeout: () => "timeout");
  ///   print(result); // Prints "timeout" after 1 second.
  ///
  ///   result = await waitTask("first").timeout(const Duration(seconds: 2),
  ///       onTimeout: () => waitTask("second"));
  ///   print(result); // Prints "second" after 7 seconds.
  ///
  ///   try {
  ///     await waitTask("completed").timeout(const Duration(seconds: 2));
  ///   } on TimeoutException {
  ///     print("throws"); // Prints "throws" after 2 seconds.
  ///   }
  ///
  ///   var printFuture = waitPrint();
  ///   await printFuture.timeout(const Duration(seconds: 2), onTimeout: () {
  ///     print("timeout"); // Prints "timeout" after 2 seconds.
  ///   });
  ///   await printFuture; // Prints "printed" after additional 3 seconds.
  ///
  ///   try {
  ///     await waitThrow("error").timeout(const Duration(seconds: 2));
  ///   } on TimeoutException {
  ///     print("throws"); // Prints "throws" after 2 seconds.
  ///   }
  ///   // StateError is ignored
  /// }
  ///
  /// /// Returns [string] after five seconds.
  /// Future<String> waitTask(String string) async {
  ///   await Future.delayed(const Duration(seconds: 5));
  ///   return string;
  /// }
  ///
  /// /// Prints "printed" after five seconds.
  /// Future<void> waitPrint() async {
  ///   await Future.delayed(const Duration(seconds: 5));
  ///   print("printed");
  /// }
  /// /// Throws a [StateError] with [message] after five seconds.
  /// Future<void> waitThrow(String message) async {
  ///   await Future.delayed(const Duration(seconds: 5));
  ///   throw Exception(message);
  /// }
  /// ```
  Future<T> timeout(Duration timeLimit, {FutureOr<T> onTimeout()?});
}

/// Explicitly ignores a future.
///
/// Not all futures need to be awaited.
/// The Dart linter has an optional
/// ["unawaited futures" lint](https://dart.dev/lints/unawaited_futures)
/// which enforces that potential futures
/// (expressions with a static type of [Future] or `Future?`)
/// in asynchronous functions are handled *somehow*.
/// If a particular future value doesn't need to be awaited,
/// you can call `unawaited(...)` with it, which will avoid the lint,
/// simply because the expression no longer has type [Future].
/// Using `unawaited` has no other effect.
/// You should use `unawaited` to convey the *intention* of
/// deliberately not waiting for the future.
///
/// If the future completes with an error,
/// it was likely a mistake to not await it.
/// That error will still occur and will be considered unhandled
/// unless the same future is awaited (or otherwise handled) elsewhere too.
/// Because of that, `unawaited` should only be used for futures that
/// are *expected* to complete with a value.
/// You can use [FutureExtensions.ignore] if you also don't want to know
/// about errors from this future.
@Since("2.15")
void unawaited(Future<void>? future) {}

/// Convenience methods on futures.
///
/// Adds functionality to futures which makes it easier to
/// write well-typed asynchronous code.
@Since("2.12")
extension FutureExtensions<T> on Future<T> {
  /// Handles errors on this future.
  ///
  /// Catches errors of type [E] that this future complete with.
  /// If [test] is supplied, only catches errors of type [E]
  /// where [test] returns `true`.
  /// If [E] is [Object], then all errors are potentially caught,
  /// depending only on a supplied [test].toString()
  ///
  /// If the error is caught,
  /// the returned future completes with the result of calling [handleError]
  /// with the error and stack trace.
  /// This result must be a value of the same type that this future
  /// could otherwise complete with.
  /// For example, if this future cannot complete with `null`,
  /// then [handleError] also cannot return `null`.
  /// Example:
  /// ```dart
  /// Future<T> retryOperation<T>(Future<T> operation(), T onFailure()) =>
  ///     operation().onError<RetryException>((e, s) {
  ///       if (e.canRetry) {
  ///         return retryOperation(operation, onFailure);
  ///       }
  ///       return onFailure();
  ///     });
  /// ```
  ///
  /// If [handleError] throws, the returned future completes
  /// with the thrown error and stack trace,
  /// except that if it throws the *same* error object again,
  /// then it is considered a "rethrow"
  /// and the original stack trace is retained.
  /// This can be used as an alternative to skipping the
  /// error in [test].
  /// Example:
  /// ```dart
  /// // Unwraps an exceptions cause, if it has one.
  /// someFuture.onError<SomeException>((e, _) {
  ///   throw e.cause ?? e;
  /// });
  /// // vs.
  /// someFuture.onError<SomeException>((e, _) {
  ///   throw e.cause!;
  /// }, test: (e) => e.cause != null);
  /// ```
  ///
  /// If the error is not caught, the returned future
  /// completes with the same result, value or error,
  /// as this future.
  ///
  /// This method is effectively a more precisely typed version
  /// of [Future.catchError].
  /// It makes it easy to catch specific error types,
  /// and requires a correctly typed error handler function,
  /// rather than just [Function].
  /// Because of this, the error handlers must accept
  /// the stack trace argument.
  Future<T> onError<E extends Object>(
      FutureOr<T> handleError(E error, StackTrace stackTrace),
      {bool test(E error)?}) {
    FutureOr<T> onError(Object error, StackTrace stackTrace) {
      if (error is! E || test != null && !test(error)) {
        // Counts as rethrow, preserves stack trace.
        throw error;
      }
      return handleError(error, stackTrace);
    }

    if (this is _Future<Object?>) {
      // Internal method working like `catchError`,
      // but allows specifying a different result future type.
      return unsafeCast<_Future<T>>(this)._safeOnError<T>(onError);
    }

    return this.then<T>((T value) => value, onError: onError);
  }

  /// Completely ignores this future and its result.
  ///
  /// Not all futures are important, not even if they contain errors,
  /// for example if a request was made, but the response is no longer needed.
  /// Simply ignoring a future can result in uncaught asynchronous errors.
  /// This method instead handles (and ignores) any values or errors
  /// coming from this future, making it safe to otherwise ignore
  /// the future.
  ///
  /// Use `ignore` to signal that the result of the future is
  /// no longer important to the program, not even if it's an error.
  /// If you merely want to silence the
  /// ["unawaited futures" lint](https://dart.dev/lints/unawaited_futures),
  /// use the [unawaited] function instead.
  /// That will ensure that an unexpected error is still reported.
  @Since("2.14")
  void ignore() {
    var self = this;
    if (self is _Future<T>) {
      self._ignore();
    } else {
      self.then<void>(_ignore, onError: _ignore);
    }
  }

  static void _ignore(Object? _, [Object? __]) {}
}

/// Thrown when a scheduled timeout happens while waiting for an async result.
class TimeoutException implements Exception {
  /// Description of the cause of the timeout.
  final String? message;

  /// The duration that was exceeded.
  final Duration? duration;

  TimeoutException(this.message, [this.duration]);

  String toString() {
    String result = "TimeoutException";
    if (duration != null) result = "TimeoutException after $duration";
    if (message != null) result = "$result: $message";
    return result;
  }
}

/// A way to produce Future objects and to complete them later
/// with a value or error.
///
/// Most of the time, the simplest way to create a future is to just use
/// one of the [Future] constructors to capture the result of a single
/// asynchronous computation:
/// ```dart
/// Future(() { doSomething(); return result; });
/// ```
/// or, if the future represents the result of a sequence of asynchronous
/// computations, they can be chained using [Future.then] or similar functions
/// on [Future]:
/// ```dart
/// Future doStuff(){
///   return someAsyncOperation().then((result) {
///     return someOtherAsyncOperation(result);
///   });
/// }
/// ```
/// If you do need to create a Future from scratch — for example,
/// when you're converting a callback-based API into a Future-based
/// one — you can use a Completer as follows:
/// ```dart
/// class AsyncOperation {
///   final Completer _completer = new Completer();
///
///   Future<T> doOperation() {
///     _startOperation();
///     return _completer.future; // Send future object back to client.
///   }
///
///   // Something calls this when the value is ready.
///   void _finishOperation(T result) {
///     _completer.complete(result);
///   }
///
///   // If something goes wrong, call this.
///   void _errorHappened(error) {
///     _completer.completeError(error);
///   }
/// }
/// ```
@vmIsolateUnsendable
abstract interface class Completer<T> {
  /// Creates a new completer.
  ///
  /// The general workflow for creating a new future is to 1) create a
  /// new completer, 2) hand out its future, and, at a later point, 3) invoke
  /// either [complete] or [completeError].
  ///
  /// The completer completes the future asynchronously. That means that
  /// callbacks registered on the future are not called immediately when
  /// [complete] or [completeError] is called. Instead the callbacks are
  /// delayed until a later microtask.
  ///
  /// Example:
  /// ```dart
  /// var completer = new Completer();
  /// handOut(completer.future);
  /// later: {
  ///   completer.complete('completion value');
  /// }
  /// ```
  factory Completer() => new _AsyncCompleter<T>();

  /// Completes the future synchronously.
  ///
  /// This constructor should be avoided unless the completion of the future is
  /// known to be the final result of another asynchronous operation. If in doubt
  /// use the default [Completer] constructor.
  ///
  /// Using an normal, asynchronous, completer will never give the wrong
  /// behavior, but using a synchronous completer incorrectly can cause
  /// otherwise correct programs to break.
  ///
  /// A synchronous completer is only intended for optimizing event
  /// propagation when one asynchronous event immediately triggers another.
  /// It should not be used unless the calls to [complete] and [completeError]
  /// are guaranteed to occur in places where it won't break `Future` invariants.
  ///
  /// Completing synchronously means that the completer's future will be
  /// completed immediately when calling the [complete] or [completeError]
  /// method on a synchronous completer, which also calls any callbacks
  /// registered on that future.
  ///
  /// Completing synchronously must not break the rule that when you add a
  /// callback on a future, that callback must not be called until the code
  /// that added the callback has completed.
  /// For that reason, a synchronous completion must only occur at the very end
  /// (in "tail position") of another synchronous event,
  /// because at that point, completing the future immediately is be equivalent
  /// to returning to the event loop and completing the future in the next
  /// microtask.
  ///
  /// Example:
  /// ```dart
  /// var completer = Completer.sync();
  /// // The completion is the result of the asynchronous onDone event.
  /// // No other operation is performed after the completion. It is safe
  /// // to use the Completer.sync constructor.
  /// stream.listen(print, onDone: () { completer.complete("done"); });
  /// ```
  /// Bad example. Do not use this code. Only for illustrative purposes:
  /// ```dart
  /// var completer = Completer.sync();
  /// completer.future.then((_) { bar(); });
  /// // The completion is the result of the asynchronous onDone event.
  /// // However, there is still code executed after the completion. This
  /// // operation is *not* safe.
  /// stream.listen(print, onDone: () {
  ///   completer.complete("done");
  ///   foo();  // In this case, foo() runs after bar().
  /// });
  /// ```
  factory Completer.sync() => new _SyncCompleter<T>();

  /// The future that is completed by this completer.
  ///
  /// The future that is completed when [complete] or [completeError] is called.
  Future<T> get future;

  /// Completes [future] with the supplied values.
  ///
  /// The value must be either a value of type [T]
  /// or a future of type `Future<T>`.
  /// If the value is omitted or `null`, and `T` is not nullable, the call
  /// to `complete` throws.
  ///
  /// If the value is itself a future, the completer will wait for that future
  /// to complete, and complete with the same result, whether it is a success
  /// or an error.
  ///
  /// Calling [complete] or [completeError] must be done at most once.
  ///
  /// All listeners on the future are informed about the value.
  void complete([FutureOr<T>? value]);

  /// Complete [future] with an error.
  ///
  /// Calling [complete] or [completeError] must be done at most once.
  ///
  /// Completing a future with an error indicates that an exception was thrown
  /// while trying to produce a value.
  ///
  /// If [error] is a [Future], the future itself is used as the error value.
  /// If you want to complete with the result of the future, you can use:
  /// ```dart
  /// thisCompleter.complete(theFuture)
  /// ```
  /// or if you only want to handle an error from the future:
  /// ```dart
  /// theFuture.catchError(thisCompleter.completeError);
  /// ```
  ///
  /// The [future] must have an error handler installed before the call to
  /// [completeError]) or [error] will be considered an uncaught error.
  ///
  /// ```dart
  /// void doStuff() {
  ///   // Outputs a message like:
  ///   // Uncaught Error: Assertion failed: "future not consumed"
  ///   Completer().completeError(AssertionError('future not consumed'));
  /// }
  /// ```
  ///
  /// You can install an error handler through [Future.catchError],
  /// [Future.then] or the `await` operation.
  ///
  /// ```dart
  /// void doStuff() {
  ///   final c = Completer();
  ///   c.future.catchError((e) {
  ///     // Handle the error.
  ///   });
  ///   c.completeError(AssertionError('future not consumed'));
  /// }
  /// ```
  ///
  /// See the
  /// [Zones article](https://dart.dev/articles/archive/zones#handling-uncaught-errors)
  /// for details on uncaught errors.
  void completeError(Object error, [StackTrace? stackTrace]);

  /// Whether the [future] has been completed.
  ///
  /// Reflects whether [complete] or [completeError] has been called.
  /// A `true` value doesn't necessarily mean that listeners of this future
  /// have been invoked yet, either because the completer usually waits until
  /// a later microtask to propagate the result, or because [complete]
  /// was called with a future that hasn't completed yet.
  ///
  /// When this value is `true`, [complete] and [completeError] must not be
  /// called again.
  bool get isCompleted;
}

// Helper function completing a _Future with error, but checking the zone
// for error replacement and missing stack trace first.
void _completeWithErrorCallback(
    _Future result, Object error, StackTrace? stackTrace) {
  AsyncError? replacement = Zone.current.errorCallback(error, stackTrace);
  if (replacement != null) {
    error = replacement.error;
    stackTrace = replacement.stackTrace;
  } else {
    stackTrace ??= AsyncError.defaultStackTrace(error);
  }
  result._completeError(error, stackTrace);
}

// Like [_completeWithErrorCallback] but completes asynchronously.
void _asyncCompleteWithErrorCallback(
    _Future result, Object error, StackTrace? stackTrace) {
  AsyncError? replacement = Zone.current.errorCallback(error, stackTrace);
  if (replacement != null) {
    error = replacement.error;
    stackTrace = replacement.stackTrace;
  } else {
    stackTrace ??= AsyncError.defaultStackTrace(error);
  }
  result._asyncCompleteError(error, stackTrace);
}
