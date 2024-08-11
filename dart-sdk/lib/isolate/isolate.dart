// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Concurrent programming using _isolates_:
/// independent workers that are similar to threads
/// but don't share memory,
/// communicating only via messages.
///
/// *NOTE*: The `dart:isolate` library is currently only supported by the
/// [Dart Native](https://dart.dev/overview#platform) platform.
///
/// To use this library in your code:
/// ```dart
/// import 'dart:isolate';
/// ```
/// {@category VM}
library dart.isolate;

import "dart:_internal" show Since;
import "dart:async";
import "dart:typed_data" show ByteBuffer, TypedData, Uint8List;

part "capability.dart";

// Examples can assume:
// Isolate findSomeIsolate() => Isolate.current;
// void untrustedCode(Isolate isolate) {}
// RawReceivePort rawPort = RawReceivePort();
// void actualHandler() {}

/// Thrown when an isolate cannot be created.
class IsolateSpawnException implements Exception {
  /// Error message reported by the spawn operation.
  final String message;
  @pragma("vm:entry-point")
  IsolateSpawnException(this.message);
  String toString() => "IsolateSpawnException: $message";
}

/// An isolated Dart execution context.
///
/// All Dart code runs in an isolate, and code can access classes and values
/// only from the same isolate. Different isolates can communicate by sending
/// values through ports (see [ReceivePort], [SendPort]).
///
/// An `Isolate` object is a reference to an isolate, usually different from
/// the current isolate.
/// It represents, and can be used to control, the other isolate.
///
/// When spawning a new isolate, the spawning isolate receives an `Isolate`
/// object representing the new isolate when the spawn operation succeeds.
///
/// Isolates run code in its own event loop, and each event may run smaller tasks
/// in a nested microtask queue.
///
/// An `Isolate` object allows other isolates to control the event loop
/// of the isolate that it represents, and to inspect the isolate,
/// for example by pausing the isolate or by getting events when the isolate
/// has an uncaught error.
///
/// The [controlPort] identifies and gives access to controlling the isolate,
/// and the [pauseCapability] and [terminateCapability] guard access
/// to some control operations.
/// For example, calling [pause] on an `Isolate` object created without a
/// [pauseCapability], has no effect.
///
/// The `Isolate` object provided by a spawn operation will have the
/// control port and capabilities needed to control the isolate.
/// New isolate objects can be created without some of these capabilities
/// if necessary, using the [Isolate.new] constructor.
///
/// An `Isolate` object cannot be sent over a `SendPort`, but the control port
/// and capabilities can be sent, and can be used to create a new functioning
/// `Isolate` object in the receiving port's isolate.
final class Isolate {
  /// Argument to `ping` and `kill`: Ask for immediate action.
  static const int immediate = 0;

  /// Argument to `ping` and `kill`: Ask for action before the next event.
  static const int beforeNextEvent = 1;

  /// Control port used to send control messages to the isolate.
  ///
  /// The control port identifies the isolate.
  ///
  /// An `Isolate` object allows sending control messages
  /// through the control port.
  ///
  /// Some control messages require a specific capability to be passed along
  /// with the message (see [pauseCapability] and [terminateCapability]),
  /// otherwise the message is ignored by the isolate.
  final SendPort controlPort;

  /// Capability granting the ability to pause the isolate.
  ///
  /// This capability is required by [pause].
  /// If the capability is `null`, or if it is not the correct pause capability
  /// of the isolate identified by [controlPort],
  /// then calls to [pause] will have no effect.
  ///
  /// If the isolate is spawned in a paused state, use this capability as
  /// argument to the [resume] method in order to resume the paused isolate.
  final Capability? pauseCapability;

  /// Capability granting the ability to terminate the isolate.
  ///
  /// This capability is required by [kill] and [setErrorsFatal].
  /// If the capability is `null`, or if it is not the correct termination
  /// capability of the isolate identified by [controlPort],
  /// then calls to those methods will have no effect.
  final Capability? terminateCapability;

  /// The name of the [Isolate] displayed for debug purposes.
  ///
  /// This can be set using the `debugName` parameter in [spawn] and [spawnUri].
  ///
  /// This name does not uniquely identify an isolate. Multiple isolates in the
  /// same process may have the same `debugName`.
  ///
  /// For a given isolate, this value will be the same as the values returned by
  /// `Dart_DebugName` in the C embedding API and the `debugName` property in
  /// [IsolateMirror].
  @Since("2.3")
  external String? get debugName;

  /// Creates a new [Isolate] object with a restricted set of capabilities.
  ///
  /// The port should be a control port for an isolate, as taken from
  /// another `Isolate` object.
  ///
  /// The capabilities should be the subset of the capabilities that are
  /// available to the original isolate.
  /// Capabilities of an isolate are locked to that isolate, and have no effect
  /// anywhere else, so the capabilities should come from the same isolate as
  /// the control port.
  ///
  /// Can also be used to create an [Isolate] object from a control port, and
  /// any available capabilities, that have been sent through a [SendPort].
  ///
  /// Example:
  /// ```dart
  /// Isolate isolate = findSomeIsolate();
  /// Isolate restrictedIsolate = Isolate(isolate.controlPort);
  /// untrustedCode(restrictedIsolate);
  /// ```
  /// This example creates a new `Isolate` object that cannot be used to
  /// pause or terminate the isolate. All the untrusted code can do is to
  /// inspect the isolate and see uncaught errors or when it terminates.
  Isolate(this.controlPort, {this.pauseCapability, this.terminateCapability});

  /// Runs [computation] in a new isolate and returns the result.
  ///
  /// ```dart
  /// int slowFib(int n) =>
  ///     n <= 1 ? 1 : slowFib(n - 1) + slowFib(n - 2);
  ///
  /// // Compute without blocking current isolate.
  /// var fib40 = await Isolate.run(() => slowFib(40));
  /// ```
  ///
  /// If [computation] is asynchronous (returns a `Future<R>`) then
  /// that future is awaited in the new isolate, completing the entire
  /// asynchronous computation, before returning the result.
  ///
  /// ```dart
  /// int slowFib(int n) =>
  ///     n <= 1 ? 1 : slowFib(n - 1) + slowFib(n - 2);
  /// Stream<int> fibStream() async* {
  ///   for (var i = 0;; i++) yield slowFib(i);
  /// }
  ///
  /// // Returns `Future<int>`.
  /// var fib40 = await Isolate.run(() => fibStream().elementAt(40));
  /// ```
  ///
  /// If [computation] throws, the isolate is terminated and this
  /// function throws the same error.
  ///
  /// ```dart import:convert
  /// Future<int> eventualError() async {
  ///   await Future.delayed(const Duration(seconds: 1));
  ///   throw StateError("In a bad state!");
  /// }
  ///
  /// try {
  ///   await Isolate.run(eventualError);
  /// } on StateError catch (e, s) {
  ///   print(e.message); // In a bad state!
  ///   print(LineSplitter.split("$s").first); // Contains "eventualError"
  /// }
  /// ```
  /// Any uncaught asynchronous errors will terminate the computation as well,
  /// but will be reported as a [RemoteError] because [addErrorListener]
  /// does not provide the original error object.
  ///
  /// The result is sent using [exit], which means it's sent to this
  /// isolate without copying.
  ///
  /// The [computation] function and its result (or error) must be
  /// sendable between isolates. Objects that cannot be sent include open
  /// files and sockets (see [SendPort.send] for details).
  ///
  /// If [computation] is a closure then it may implicitly send unexpected
  /// state to the isolate due to limitations in the Dart implementation. This
  /// can cause performance issues, increased memory usage
  /// (see http://dartbug.com/36983) or, if the state includes objects that
  /// can't be spent between isolates, a runtime failure.
  ///
  /// ```dart import:convert import:io
  ///
  /// void serializeAndWrite(File f, Object o) async {
  ///   final openFile = await f.open(mode: FileMode.append);
  ///   Future writeNew() async {
  ///     // Will fail with:
  ///     // "Invalid argument(s): Illegal argument in isolate message"
  ///     // because `openFile` is captured.
  ///     final encoded = await Isolate.run(() => jsonEncode(o));
  ///     await openFile.writeString(encoded);
  ///     await openFile.flush();
  ///     await openFile.close();
  ///   }
  ///
  ///   if (await openFile.position() == 0) {
  ///     await writeNew();
  ///   }
  /// }
  /// ```
  ///
  /// In such cases, you can create a new function to call [Isolate.run] that
  /// takes all of the required state as arguments.
  ///
  /// ```dart import:convert import:io
  ///
  /// void serializeAndWrite(File f, Object o) async {
  ///   final openFile = await f.open(mode: FileMode.append);
  ///   Future writeNew() async {
  ///     Future<String> encode(o) => Isolate.run(() => jsonEncode(o));
  ///     final encoded = await encode(o);
  ///     await openFile.writeString(encoded);
  ///     await openFile.flush();
  ///     await openFile.close();
  ///   }
  ///
  ///   if (await openFile.position() == 0) {
  ///     await writeNew();
  ///   }
  /// }
  /// ```
  ///
  /// The [debugName] is only used to name the new isolate for debugging.
  @Since("2.19")
  static Future<R> run<R>(FutureOr<R> computation(), {String? debugName}) {
    var result = Completer<R>();
    var resultPort = RawReceivePort();
    resultPort.handler = (response) {
      resultPort.close();
      if (response == null) {
        // onExit handler message, isolate terminated without sending result.
        result.completeError(
            RemoteError("Computation ended without result", ""),
            StackTrace.empty);
        return;
      }
      var list = response as List<Object?>;
      if (list.length == 2) {
        var remoteError = list[0];
        var remoteStack = list[1];
        if (remoteStack is StackTrace) {
          // Typed error.
          result.completeError(remoteError!, remoteStack);
        } else {
          // onError handler message, uncaught async error.
          // Both values are strings, so calling `toString` is efficient.
          var error =
              RemoteError(remoteError.toString(), remoteStack.toString());
          result.completeError(error, error.stackTrace);
        }
      } else {
        assert(list.length == 1);
        result.complete(list[0] as R);
      }
    };
    try {
      Isolate.spawn(_RemoteRunner._remoteExecute,
              _RemoteRunner<R>(computation, resultPort.sendPort),
              onError: resultPort.sendPort,
              onExit: resultPort.sendPort,
              errorsAreFatal: true,
              debugName: debugName)
          .then<void>((_) {}, onError: (error, stack) {
        // Sending the computation failed asynchronously.
        // Do not expect a response, report the error asynchronously.
        resultPort.close();
        result.completeError(error, stack);
      });
    } on Object {
      // Sending the computation failed synchronously.
      // This is not expected to happen, but if it does,
      // the synchronous error is respected and rethrown synchronously.
      resultPort.close();
      rethrow;
    }
    return result.future;
  }

  /// An [Isolate] object representing the current isolate.
  ///
  /// The current isolate for code using [current]
  /// is the isolate running the code.
  ///
  /// The isolate object provides the capabilities required to inspect,
  /// pause or kill the isolate, and allows granting these capabilities
  /// to others.
  ///
  /// It is possible to pause the current isolate, but doing so *without*
  /// first passing the ability to resume it again to another isolate,
  /// is a sure way to hang your program.
  external static Isolate get current;

  /// The location of the package configuration file of the current isolate.
  ///
  /// If the isolate was spawned without specifying its package configuration
  /// file then the returned value is `null`.
  ///
  /// Otherwise, the returned value is an absolute URI specifying the location
  /// of isolate's package configuration file.
  ///
  /// The package configuration file is usually named `package_config.json`,
  /// and you can use [`package:package_config`](https://pub.dev/documentation/package_config/latest/)
  /// to read and parse it.
  external static Future<Uri?> get packageConfig;

  /// The location of the package configuration file of the current isolate.
  ///
  /// If the isolate was spawned without specifying its package configuration
  /// file then the returned value is `null`.
  ///
  /// Otherwise, the returned value is an absolute URI specifying the location
  /// of isolate's package configuration file.
  ///
  /// The package configuration file is usually named `package_config.json`,
  /// and you can use [`package:package_config`](https://pub.dev/documentation/package_config/latest/)
  /// to read and parse it.
  @Since('3.2')
  external static Uri? get packageConfigSync;

  /// Resolves a `package:` URI to its actual location.
  ///
  /// Returns the actual location of the file or directory specified by the
  /// [packageUri] `package:` URI.
  ///
  /// If the [packageUri] is not a `package:` URI, it's returned as-is.
  ///
  /// Returns `null` if [packageUri] is a `package:` URI, but either
  /// the current package configuration does not have a configuration
  /// for the package name of the URI, or
  /// the URI is not valid (doesn't start with `package:valid_package_name/`),
  ///
  /// A `package:` URI is resolved to its actual location based on
  /// a package resolution configuration (see [packageConfig])
  /// which specifies how to find the actual location of the file or directory
  /// that the `package:` URI points to.
  ///
  /// The actual location corresponding to a `package:` URI is always a
  /// non-`package:` URI, typically a `file:` or possibly `http:` URI.
  ///
  /// A program may be run in a way where source files are not available,
  /// and if so, the returned URI may not correspond to the actual file or
  /// directory or be `null`.
  external static Future<Uri?> resolvePackageUri(Uri packageUri);

  /// Resolves a `package:` URI to its actual location.
  ///
  /// Returns the actual location of the file or directory specified by the
  /// [packageUri] `package:` URI.
  ///
  /// If the [packageUri] is not a `package:` URI, it's returned as-is.
  ///
  /// Returns `null` if [packageUri] is a `package:` URI, but either
  /// the current package configuration does not have a configuration
  /// for the package name of the URI, or
  /// the URI is not valid (doesn't start with `package:valid_package_name/`),
  ///
  /// A `package:` URI is resolved to its actual location based on
  /// a package resolution configuration (see [packageConfig])
  /// which specifies how to find the actual location of the file or directory
  /// that the `package:` URI points to.
  ///
  /// The actual location corresponding to a `package:` URI is always a
  /// non-`package:` URI, typically a `file:` or possibly `http:` URI.
  ///
  /// A program may be run in a way where source files are not available,
  /// and if so, the returned URI may not correspond to the actual file or
  /// directory or be `null`.
  @Since('3.2')
  external static Uri? resolvePackageUriSync(Uri packageUri);

  /// Creates and spawns an isolate that shares the same code as the current
  /// isolate.
  ///
  /// The argument [entryPoint] specifies the initial function to call
  /// in the spawned isolate.
  /// The entry-point function is invoked in the new isolate with [message]
  /// as the only argument.
  ///
  /// The [entryPoint] function must be able to be called with a single
  /// argument, that is, a function which accepts at least one positional
  /// parameter and has at most one required positional parameter.
  /// The function may accept any number of optional parameters,
  /// as long as it *can* be called with just a single argument. If
  /// [entryPoint] is a closure then it may implicitly send unexpected state
  /// to the isolate due to limitations in the Dart implementation. This can
  /// cause performance issues, increased memory usage
  /// (see http://dartbug.com/36983) or, if the state includes objects that
  /// can't be spent between isolates, a runtime failure. See [run] for an
  /// example.
  ///
  /// [message] must be sendable between isolates. Objects that cannot be sent
  /// include open files and sockets (see [SendPort.send] for details). Usually
  /// the initial [message] contains a [SendPort] so that the spawner and
  /// spawnee can communicate with each other.
  ///
  /// If the [paused] parameter is set to `true`,
  /// the isolate will start up in a paused state,
  /// just before calling the [entryPoint] function with the [message],
  /// as if by an initial call of `isolate.pause(isolate.pauseCapability)`.
  /// To resume the isolate, call `isolate.resume(isolate.pauseCapability)`.
  ///
  /// If the [errorsAreFatal], [onExit] and/or [onError] parameters are provided,
  /// the isolate will act as if, respectively, [setErrorsFatal],
  /// [addOnExitListener] and [addErrorListener] were called with the
  /// corresponding parameter and was processed before the isolate starts
  /// running.
  ///
  /// If [debugName] is provided, the spawned [Isolate] will be identifiable by
  /// this name in debuggers and logging.
  ///
  /// If [errorsAreFatal] is omitted, the platform may choose a default behavior
  /// or inherit the current isolate's behavior.
  ///
  /// You can also call the [setErrorsFatal], [addOnExitListener] and
  /// [addErrorListener] methods on the returned isolate, but unless the
  /// isolate was started as [paused], it may already have terminated
  /// before those methods can complete.
  ///
  /// Returns a future which will complete with an [Isolate] instance if the
  /// spawning succeeded. It will complete with an error otherwise.
  ///
  /// One can expect the base memory overhead of an isolate to be in the order
  /// of 30 kb.
  external static Future<Isolate> spawn<T>(
      void entryPoint(T message), T message,
      {bool paused = false,
      bool errorsAreFatal = true,
      SendPort? onExit,
      SendPort? onError,
      @Since("2.3") String? debugName});

  /// Creates and spawns an isolate that runs the code from the library with
  /// the specified URI.
  ///
  /// The isolate starts executing the top-level `main` function of the library
  /// with the given URI.
  ///
  /// The target `main` must be callable with zero, one or two arguments.
  /// Examples:
  ///
  /// * `main()`
  /// * `main(args)`
  /// * `main(args, message)`
  ///
  /// When present, the parameter `args` is set to the provided [args] list.
  /// When present, the parameter `message` is set to the initial [message].
  ///
  /// If the [paused] parameter is set to `true`,
  /// the isolate will start up in a paused state,
  /// as if by an initial call of `isolate.pause(isolate.pauseCapability)`.
  /// To resume the isolate, call `isolate.resume(isolate.pauseCapability)`.
  ///
  /// If the [errorsAreFatal], [onExit] and/or [onError] parameters are provided,
  /// the isolate will act as if, respectively, [setErrorsFatal],
  /// [addOnExitListener] and [addErrorListener] were called with the
  /// corresponding parameter and was processed before the isolate starts
  /// running.
  ///
  /// You can also call the [setErrorsFatal], [addOnExitListener] and
  /// [addErrorListener] methods on the returned isolate, but unless the
  /// isolate was started as [paused], it may already have terminated
  /// before those methods can complete.
  ///
  /// If the [checked] parameter is set to `true` or `false`,
  /// the new isolate will run code in checked mode (enabling asserts and type
  /// checks), respectively in production mode (disabling asserts and type
  /// checks), if possible. If the parameter is omitted, the new isolate will
  /// inherit the value from the current isolate.
  ///
  /// In Dart2 strong mode, the `checked` parameter only controls asserts, but
  /// not type checks.
  ///
  /// It may not always be possible to honor the `checked` parameter.
  /// If the isolate code was pre-compiled, it may not be possible to change
  /// the checked mode setting dynamically.
  /// In that case, the `checked` parameter is ignored.
  ///
  /// WARNING: The [checked] parameter is not implemented on all platforms yet.
  ///
  /// If the [packageConfig] parameter is provided, then it is used to find the
  /// location of a package resolution configuration file for the spawned
  /// isolate.
  ///
  /// If the [automaticPackageResolution] parameter is provided, then the
  /// location of the package sources in the spawned isolate is automatically
  /// determined.
  ///
  /// The [environment] is a mapping from strings to strings which the
  /// spawned isolate uses when looking up [String.fromEnvironment] values.
  /// The system may add its own entries to environment as well.
  /// If `environment` is omitted, the spawned isolate has the same environment
  /// declarations as the spawning isolate.
  ///
  /// WARNING: The [environment] parameter is not implemented on all
  /// platforms yet.
  ///
  /// If [debugName] is provided, the spawned [Isolate] will be identifiable by
  /// this name in debuggers and logging.
  ///
  /// Returns a future that will complete with an [Isolate] instance if the
  /// spawning succeeded. It will complete with an error otherwise.
  external static Future<Isolate> spawnUri(
      Uri uri, List<String> args, var message,
      {bool paused = false,
      SendPort? onExit,
      SendPort? onError,
      bool errorsAreFatal = true,
      bool? checked,
      Map<String, String>? environment,
      @Deprecated('The packages/ dir is not supported in Dart 2')
      Uri? packageRoot,
      Uri? packageConfig,
      bool automaticPackageResolution = false,
      @Since("2.3") String? debugName});

  /// Requests the isolate to pause.
  ///
  /// When the isolate receives the pause command, it stops
  /// processing events from the event loop queue.
  /// It may still add new events to the queue in response to, e.g., timers
  /// or receive-port messages. When the isolate is resumed,
  /// it starts handling the already enqueued events.
  ///
  /// The pause request is sent through the isolate's command port,
  /// which bypasses the receiving isolate's event loop.
  /// The pause takes effect when it is received, pausing the event loop
  /// as it is at that time.
  ///
  /// The [resumeCapability] is used to identity the pause,
  /// and must be used again to end the pause using [resume].
  /// If [resumeCapability] is omitted, a new capability object is created
  /// and used instead.
  ///
  /// If an isolate is paused more than once using the same capability,
  /// only one resume with that capability is needed to end the pause.
  ///
  /// If an isolate is paused using more than one capability,
  /// each pause must be individually ended before the isolate resumes.
  ///
  /// Returns the capability that must be used to end the pause.
  /// This is either [resumeCapability], or a new capability when
  /// [resumeCapability] is omitted.
  ///
  /// If [pauseCapability] is `null`, or it's not the pause capability
  /// of the isolate identified by [controlPort],
  /// the pause request is ignored by the receiving isolate.
  Capability pause([Capability? resumeCapability]) {
    resumeCapability ??= Capability();
    _pause(resumeCapability);
    return resumeCapability;
  }

  /// Internal implementation of [pause].
  external void _pause(Capability resumeCapability);

  /// Resumes a paused isolate.
  ///
  /// Sends a message to an isolate requesting that it ends a pause
  /// that was previously requested.
  ///
  /// When all active pause requests have been cancelled, the isolate
  /// will continue processing events and handling normal messages.
  ///
  /// If the [resumeCapability] is not one that has previously been used
  /// to pause the isolate, or it has already been used to resume from
  /// that pause, the resume call has no effect.
  external void resume(Capability resumeCapability);

  /// Requests an exit message on [responsePort] when the isolate terminates.
  ///
  /// The isolate will send [response] as a message on [responsePort] as the last
  /// thing before it terminates. It will run no further code after the message
  /// has been sent.
  ///
  /// Adding the same port more than once will only cause it to receive one exit
  /// message, using the last response value that was added,
  /// and it only needs to be removed once using [removeOnExitListener].
  ///
  /// If the isolate has terminated before it can receive this request,
  /// no exit message will be sent.
  ///
  /// The [response] object must follow the same restrictions as enforced by
  /// [SendPort.send] when sending to an isolate from another isolate group;
  /// only simple values that can be sent to all isolates, like `null`,
  /// booleans, numbers or strings, are allowed.
  ///
  /// Since isolates run concurrently, it's possible for it to exit before the
  /// exit listener is established, and in that case no response will be
  /// sent on [responsePort].
  /// To avoid this, either use the corresponding parameter to the spawn
  /// function, or start the isolate paused, add the listener and
  /// then resume the isolate.
  /* TODO(lrn): Can we do better? Can the system recognize this message and
   * send a reply if the receiving isolate is dead?
   */
  external void addOnExitListener(SendPort responsePort, {Object? response});

  /// Stops listening for exit messages from the isolate.
  ///
  /// Requests for the isolate to not send exit messages on [responsePort].
  /// If the isolate isn't expecting to send exit messages on [responsePort],
  /// because the port hasn't been added using [addOnExitListener],
  /// or because it has already been removed, the request is ignored.
  ///
  /// If the same port has been passed via [addOnExitListener] more than once,
  /// only one call to `removeOnExitListener` is needed to stop it from receiving
  /// exit messages.
  ///
  /// Closing the receive port that is associated with the [responsePort] does
  /// not stop the isolate from sending uncaught errors, they are just going to
  /// be lost.
  ///
  /// An exit message may still be sent if the isolate terminates
  /// before this request is received and processed.
  external void removeOnExitListener(SendPort responsePort);

  /// Sets whether uncaught errors will terminate the isolate.
  ///
  /// If errors are fatal, any uncaught error will terminate the isolate
  /// event loop and shut down the isolate.
  ///
  /// This call requires the [terminateCapability] for the isolate.
  /// If the capability is absent or incorrect, no change is made.
  ///
  /// Since isolates run concurrently, it's possible for the receiving isolate
  /// to exit due to an error, before a request, using this method, has been
  /// received and processed.
  /// To avoid this, either use the corresponding parameter to the spawn
  /// function, or start the isolate paused, set errors non-fatal and
  /// then resume the isolate.
  external void setErrorsFatal(bool errorsAreFatal);

  /// Requests the isolate to shut down.
  ///
  /// The isolate is requested to terminate itself.
  /// The [priority] argument specifies when this must happen.
  ///
  /// The [priority], when provided, must be one of [immediate] or
  /// [beforeNextEvent] (the default).
  /// The shutdown is performed at different times depending on the priority:
  ///
  /// * `immediate`: The isolate shuts down as soon as possible.
  ///     Control messages are handled in order, so all previously sent control
  ///     events from this isolate will all have been processed.
  ///     The shutdown should happen no later than if sent with
  ///     `beforeNextEvent`.
  ///     It may happen earlier if the system has a way to shut down cleanly
  ///     at an earlier time, even during the execution of another event.
  /// * `beforeNextEvent`: The shutdown is scheduled for the next time
  ///     control returns to the event loop of the receiving isolate,
  ///     after the current event, and any already scheduled control events,
  ///     are completed.
  ///
  /// If [terminateCapability] is `null`, or it's not the terminate capability
  /// of the isolate identified by [controlPort],
  /// the kill request is ignored by the receiving isolate.
  external void kill({int priority = beforeNextEvent});

  /// Requests that the isolate send [response] on the [responsePort].
  ///
  /// The [response] object must follow the same restrictions as enforced by
  /// [SendPort.send] when sending to an isolate from another isolate group;
  /// only simple values that can be sent to all isolates, like `null`,
  /// booleans, numbers or strings, are allowed.
  ///
  /// If the isolate is alive, it will eventually send `response`
  /// (defaulting to `null`) on the response port.
  ///
  /// The [priority] must be one of [immediate] or [beforeNextEvent].
  /// The response is sent at different times depending on the ping type:
  ///
  /// * `immediate`: The isolate responds as soon as it receives the
  ///     control message. This is after any previous control message
  ///     from the same isolate has been received and processed,
  ///     but may be during execution of another event.
  /// * `beforeNextEvent`: The response is scheduled for the next time
  ///     control returns to the event loop of the receiving isolate,
  ///     after the current event, and any already scheduled control events,
  ///     are completed.
  external void ping(SendPort responsePort,
      {Object? response, int priority = immediate});

  /// Requests that uncaught errors of the isolate are sent back to [port].
  ///
  /// The errors are sent back as two-element lists.
  /// The first element is a `String` representation of the error, usually
  /// created by calling `toString` on the error.
  /// The second element is a `String` representation of an accompanying
  /// stack trace, or `null` if no stack trace was provided.
  /// To convert this back to a [StackTrace] object, use [StackTrace.fromString].
  ///
  /// Listening using the same port more than once does nothing.
  /// A port will only receive each error once,
  /// and will only need to be removed once using [removeErrorListener].
  ///
  /// Closing the receive port that is associated with the port does not stop
  /// the isolate from sending uncaught errors, they are just going to be lost.
  /// Instead use [removeErrorListener] to stop receiving errors on [port].
  ///
  /// Since isolates run concurrently, it's possible for it to exit before the
  /// error listener is established. To avoid this, start the isolate paused,
  /// add the listener and then resume the isolate.
  external void addErrorListener(SendPort port);

  /// Stops listening for uncaught errors from the isolate.
  ///
  /// Requests for the isolate to not send uncaught errors on [port].
  /// If the isolate isn't expecting to send uncaught errors on [port],
  /// because the port hasn't been added using [addErrorListener],
  /// or because it has already been removed, the request is ignored.
  ///
  /// If the same port has been passed via [addErrorListener] more than once,
  /// only one call to `removeErrorListener` is needed to stop it from receiving
  /// uncaught errors.
  ///
  /// Uncaught errors message may still be sent by the isolate
  /// until this request is received and processed.
  external void removeErrorListener(SendPort port);

  /// Returns a broadcast stream of uncaught errors from the isolate.
  ///
  /// Each error is provided as an error event on the stream.
  ///
  /// The actual error object and stackTraces will not necessarily
  /// be the same object types as in the actual isolate, but they will
  /// always have the same [Object.toString] result.
  ///
  /// This stream is based on [addErrorListener] and [removeErrorListener].
  Stream get errors {
    StreamController controller = StreamController.broadcast(sync: true);
    RawReceivePort? port;
    void handleError(Object? message) {
      var listMessage = message as List<Object?>;
      var errorDescription = listMessage[0] as String;
      var stackDescription = listMessage[1] as String;
      var error = RemoteError(errorDescription, stackDescription);
      controller.addError(error, error.stackTrace);
    }

    controller.onListen = () {
      RawReceivePort receivePort = RawReceivePort(handleError);
      port = receivePort;
      this.addErrorListener(receivePort.sendPort);
    };
    controller.onCancel = () {
      var listenPort = port!;
      port = null;
      this.removeErrorListener(listenPort.sendPort);
      listenPort.close();
    };
    return controller.stream;
  }

  /// Terminates the current isolate synchronously.
  ///
  /// This operation is potentially dangerous and should be used judiciously.
  /// The isolate stops operating *immediately*. It throws if the optional
  /// [message] does not adhere to the limitations on what can be sent from one
  /// isolate to another (see [SendPort.send] for more details). It also throws
  /// if a [finalMessagePort] is associated with an isolate spawned outside of
  /// current isolate group, spawned via [spawnUri].
  ///
  /// If successful, a call to this method does not return. Pending `finally`
  /// blocks are not executed, control flow will not go back to the event loop,
  /// scheduled asynchronous asks will never run, and even pending isolate
  /// control commands may be ignored. (The isolate will send messages to ports
  /// already registered using [Isolate.addOnExitListener], but no further Dart
  /// code will run in the isolate.)
  ///
  /// If [finalMessagePort] is provided, and the [message] can be sent through
  /// it (see [SendPort.send] for more details), then the message is sent
  /// through that port as the final operation of the current isolate. The
  /// isolate terminates immediately after that [SendPort.send] call returns.
  ///
  /// If the port is a native port -- one provided by [ReceivePort.sendPort] or
  /// [RawReceivePort.sendPort] -- the system may be able to send this final
  /// message more efficiently than normal port communication between live
  /// isolates. In these cases this final message object graph will be
  /// reassigned to the receiving isolate without copying. Further, the
  /// receiving isolate will in most cases be able to receive the message
  /// in constant time.
  external static Never exit([SendPort? finalMessagePort, Object? message]);
}

/// Sends messages to its [ReceivePort]s.
///
/// [SendPort]s are created from [ReceivePort]s. Any message sent through
/// a [SendPort] is delivered to its corresponding [ReceivePort]. There might be
/// many [SendPort]s for the same [ReceivePort].
///
/// [SendPort]s can be transmitted to other isolates, and they preserve equality
/// when sent.
@pragma("vm:entry-point")
abstract interface class SendPort implements Capability {
  /// Sends an asynchronous [message] through this send port, to its
  /// corresponding [ReceivePort].
  ///
  /// If the sending and receiving isolates do not share the same code
  /// (an isolate created using [Isolate.spawnUri] does not share the code
  /// of the isolate that spawned it), the transitive object graph of [message]
  /// can **only** contain the following kinds of objects:
  ///
  ///   - `null`
  ///   - `true` and `false`
  ///   - Instances of [int], [double], [String]
  ///   - Instances created through list, map and set literals
  ///   - Instances created by constructors of:
  ///     - [List], [Map], [LinkedHashMap], [Set] and [LinkedHashSet]
  ///     - [TransferableTypedData]
  ///     - [Capability]
  ///   - [SendPort] instances from [ReceivePort.sendPort] or
  ///     [RawReceivePort.sendPort] where the receive ports are created
  ///     using those classes' constructors.
  ///   - Instances of [Type] representing one of the types mentioned above,
  ///     `Object`, `dynamic`, `void` and `Never` as well as nullable variants
  ///     of all these types. For generic types type arguments must be sendable
  ///     types for the whole type to be sendable.
  ///
  /// If the sender and receiver isolate share the same code (e.g. isolates
  /// created via [Isolate.spawn]), the transitive object graph of [message] can
  /// contain any object, with the following exceptions:
  ///
  ///   - Objects with native resources (subclasses of e.g.
  ///     `NativeFieldWrapperClass1`). A [Socket] object for example refers
  ///     internally to objects that have native resources attached and can
  ///     therefore not be sent.
  ///   - [ReceivePort]
  ///   - [DynamicLibrary]
  ///   - [Finalizable]
  ///   - [Finalizer]
  ///   - [NativeFinalizer]
  ///   - [Pointer]
  ///   - [UserTag]
  ///   - `MirrorReference`
  ///
  /// Instances of classes that either themselves are marked with
  /// `@pragma('vm:isolate-unsendable')`, extend or implement such classes
  /// cannot be sent through the ports.
  ///
  /// Apart from those exceptions any object can be sent. Objects that are
  /// identified as immutable (e.g. strings) will be shared whereas all other
  /// objects will be copied.
  ///
  /// The send happens immediately and may have a linear time cost to copy the
  /// transitive object graph. The send itself doesn't block (i.e. doesn't wait
  /// until the receiver has received the message). The corresponding receive
  /// port can receive the message as soon as its isolate's event loop is ready
  /// to deliver it, independently of what the sending isolate is doing.
  ///
  /// Note: Due to an implementation choice the Dart VM made for how closures
  /// represent captured state, closures can currently capture more state than
  /// they need, which can cause the transitive closure to be larger than
  /// needed. Open bug to address this: http://dartbug.com/36983
  void send(Object? message);

  /// Tests whether [other] is a [SendPort] pointing to the same
  /// [ReceivePort] as this one.
  bool operator ==(var other);

  /// A hash code for this send port that is consistent with the == operator.
  int get hashCode;
}

/// Together with [SendPort], the only means of communication between isolates.
///
/// [ReceivePort]s have a `sendPort` getter which returns a [SendPort].
/// Any message that is sent through this [SendPort]
/// is delivered to the [ReceivePort] it has been created from. There, the
/// message is dispatched to the `ReceivePort`'s listener.
///
/// A [ReceivePort] is a non-broadcast stream. This means that it buffers
/// incoming messages until a listener is registered. Only one listener can
/// receive messages. See [Stream.asBroadcastStream] for transforming the port
/// to a broadcast stream.
///
/// A [ReceivePort] may have many [SendPort]s.
abstract interface class ReceivePort implements Stream<dynamic> {
  /// Opens a long-lived port for receiving messages.
  ///
  /// A [ReceivePort] is a non-broadcast stream. This means that it buffers
  /// incoming messages until a listener is registered. Only one listener can
  /// receive messages. See [Stream.asBroadcastStream] for transforming the port
  /// to a broadcast stream.
  ///
  /// The optional `debugName` parameter can be set to associate a name with
  /// this port that can be displayed in tooling.
  ///
  /// A receive port is closed by canceling its subscription.
  external factory ReceivePort([String debugName = '']);

  /// Creates a [ReceivePort] from a [RawReceivePort].
  ///
  /// The handler of the given [rawPort] is overwritten during the construction
  /// of the result.
  external factory ReceivePort.fromRawReceivePort(RawReceivePort rawPort);

  /// Listen for events from [Stream].
  ///
  /// See [Stream.listen].
  ///
  /// Note that [onError] and [cancelOnError] are ignored since a [ReceivePort]
  /// will never receive an error.
  ///
  /// The [onDone] handler will be called when the stream closes.
  /// The stream closes when [close] is called.
  StreamSubscription<dynamic> listen(void onData(var message)?,
      {Function? onError, void onDone()?, bool? cancelOnError});

  /// Closes the receive port.
  ///
  /// No further events will be received by the receive port,
  /// or emitted as stream events.
  ///
  /// If [listen] has been called and the [StreamSubscription] has not
  /// been canceled yet, the subscription will be closed with a "done"
  /// event.
  ///
  /// If the stream has already been canceled this method has no effect.
  void close();

  /// A [SendPort] which sends messages to this receive port.
  SendPort get sendPort;
}

/// A low-level asynchronous message receiver.
///
/// A [RawReceivePort] is low level feature, and is not [Zone] aware.
/// The [handler] will always be invoked  in the [Zone.root] zone.
///
/// The port cannot be paused. The data-handler must be set before the first
/// message is received, otherwise the message is lost.
///
/// Messages can be sent to this port using [sendPort].
abstract interface class RawReceivePort {
  /// Opens a long-lived port for receiving messages.
  ///
  /// A [RawReceivePort] is low level and does not work with [Zone]s. It
  /// cannot be paused. The data-handler must be set before the first
  /// message is received, otherwise the message is lost.
  ///
  /// If [handler] is provided, it's set as the [RawReceivePort.handler].
  ///
  /// The optional `debugName` parameter can be set to associate a name with
  /// this port that can be displayed in tooling.
  external factory RawReceivePort([Function? handler, String debugName = '']);

  /// Sets the handler that is invoked for every incoming message.
  ///
  /// The handler is invoked in the [Zone.root] zone.
  /// If the handler should be invoked in the current zone, do:
  /// ```dart import:async
  /// rawPort.handler = Zone.current.bindCallback(actualHandler);
  /// ```
  ///
  /// The handler must be a function which can accept one argument
  /// of the type of the messages sent to this port.
  /// This means that if it is known that messages will all be [String]s,
  /// a handler of type `void Function(String)` can be used.
  /// The function is invoked dynamically with the actual messages,
  /// and if this invocation fails,
  /// the error becomes a top-level uncaught error in the [Zone.root] zone.
  // TODO(44659): Change parameter type to `void Function(Never)` to only
  // accept functions which can be called with one argument.
  void set handler(Function? newHandler);

  /// Closes the port.
  ///
  /// After a call to this method, any incoming message is silently dropped.
  /// The [handler] will never be called again.
  void close();

  /// Returns a [SendPort] that sends messages to this raw receive port.
  SendPort get sendPort;

  /// Whether this [RawReceivePort] keeps its [Isolate] alive.
  ///
  /// By default, receive ports keep the [Isolate] that created them alive until
  /// [close] is called. If [keepIsolateAlive] is set to `false`, the isolate
  /// may close while the port is still open. The port is closed when the
  /// isolate closes, and further messages sent by the [sendPort] are ignored.
  abstract bool keepIsolateAlive;
}

/// Description of an error from another isolate.
///
/// This error has the same `toString()` and `stackTrace.toString()` behavior
/// as the original error, but has no other features of the original error.
final class RemoteError implements Error {
  final String _description;
  final StackTrace stackTrace;
  RemoteError(String description, String stackDescription)
      : _description = description,
        stackTrace = StackTrace.fromString(stackDescription);
  String toString() => _description;
}

/// An efficiently transferable sequence of byte values.
///
/// A [TransferableTypedData] is created from a number of bytes.
/// This will take time proportional to the number of bytes.
///
/// The [TransferableTypedData] can be moved between isolates, so
/// sending it through a send port will only take constant time.
///
/// When sent this way, the local transferable can no longer be materialized,
/// and the received object is now the only way to materialize the data.
@Since("2.3.2")
abstract final class TransferableTypedData {
  /// Creates a new [TransferableTypedData] containing the bytes of [list].
  ///
  /// It must be possible to create a single [Uint8List] containing the
  /// bytes, so if there are more bytes than what the platform allows in
  /// a single [Uint8List], then creation fails.
  external factory TransferableTypedData.fromList(List<TypedData> list);

  /// Creates a new [ByteBuffer] containing the bytes stored in this [TransferableTypedData].
  ///
  /// The [TransferableTypedData] is a cross-isolate single-use resource.
  /// This method must not be called more than once on the same underlying
  /// transferable bytes, even if the calls occur in different isolates.
  ByteBuffer materialize();
}

/// Parameter object used by [Isolate.run].
///
/// The [_remoteExecute] function is run in a new isolate with a
/// [_RemoteRunner] object as argument.
final class _RemoteRunner<R> {
  /// User computation to run.
  final FutureOr<R> Function() computation;

  /// Port to send isolate computation result on.
  ///
  /// Only one object is ever sent on this port.
  /// If the value is `null`, it is sent by the isolate's "on-exit" handler
  /// when the isolate terminates without otherwise sending value.
  /// If the value is a list with one element,
  /// then it is the result value of the computation.
  /// Otherwise it is a list with two elements representing an error.
  /// If the error is sent by the isolate's "on-error" uncaught error handler,
  /// then the list contains two strings. This also terminates the isolate.
  /// If sent manually by this class, after capturing the error,
  /// the list contains one non-`null` [Object] and one [StackTrace].
  final SendPort resultPort;

  _RemoteRunner(this.computation, this.resultPort);

  /// Run in a new isolate to get the result of [computation].
  ///
  /// The result is sent back on [resultPort] as a single-element list.
  /// A two-element list sent on the same port is an error result.
  /// When sent by this function, it's always an object and a [StackTrace].
  /// (The same port listens on uncaught errors from the isolate, which
  /// sends two-element lists containing [String]s instead).
  static void _remoteExecute(_RemoteRunner<Object?> runner) {
    runner._run();
  }

  void _run() async {
    R result;
    try {
      var potentiallyAsyncResult = computation();
      if (potentiallyAsyncResult is Future<R>) {
        result = await potentiallyAsyncResult;
      } else {
        result = potentiallyAsyncResult;
      }
    } catch (e, s) {
      // If sending fails, the error becomes an uncaught error.
      Isolate.exit(resultPort, _list2(e, s));
    }
    Isolate.exit(resultPort, _list1(result));
  }

  /// Helper function to create a one-element non-growable list.
  static List<Object?> _list1(Object? value) => List.filled(1, value);

  /// Helper function to create a two-element non-growable list.
  static List<Object?> _list2(Object? value1, Object? value2) =>
      List.filled(2, value1)..[1] = value2;
}
