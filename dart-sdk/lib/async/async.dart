// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Support for asynchronous programming,
/// with classes such as Future and Stream.
///
/// [Future]s and [Stream]s are the fundamental building blocks
/// of asynchronous programming in Dart. They are supported
/// directly in the language through `async` and `async*`
/// functions, and are available to all libraries through
/// the `dart:core` library.
///
/// This library provides further tools for creating, consuming
/// and transforming futures and streams, as well as direct access to
/// other asynchronous primitives like [timers][Timer],
/// [microtasks][scheduleMicrotask] and [zones][Zone].
///
/// To use this library in your code:
/// ```dart
/// import 'dart:async';
/// ```
/// ## Future
///
/// A Future object represents a computation whose return value
/// might not yet be available.
/// The Future returns the value of the computation
/// when it completes at some time in the future.
/// Futures are often used for APIs that are implemented using a
/// different thread or isolate (e.g., the asynchronous I/O
/// operations of `dart:io` or HTTP requests of `dart:html`).
///
/// Many methods in the Dart libraries return `Future`s when
/// performing tasks. For example, when binding an `HttpServer`
/// to a host and port, the `bind()` method returns a Future.
/// ```dart import:io
///  HttpServer.bind('127.0.0.1', 4444)
///      .then((server) => print('${server.isBroadcast}'))
///      .catchError(print);
/// ```
/// [Future.then] registers a callback function that runs
/// when the Future's operation, in this case the `bind()` method,
/// completes successfully.
/// The value returned by the operation
/// is passed into the callback function.
/// In this example, the `bind()` method returns the HttpServer
/// object. The callback function prints one of its properties.
/// [Future.catchError] registers a callback function that
/// runs if an error occurs within the Future.
///
/// ## Stream
///
/// A Stream provides an asynchronous sequence of data.
/// Examples of data sequences include individual events, like mouse clicks,
/// or sequential chunks of larger data, like multiple byte lists with the
/// contents of a file
/// such as mouse clicks, and a stream of byte lists read from a file.
/// The following example opens a file for reading.
/// [Stream.listen] registers callback functions that run
/// each time more data is available, an error has occurred, or
/// the stream has finished.
/// Further functionality is provided on [Stream], implemented by calling
/// [Stream.listen] to get the actual data.
/// ```dart import:io import:convert
/// Stream<List<int>> stream = File('quotes.txt').openRead();
/// stream.transform(utf8.decoder).forEach(print);
/// ```
/// This stream emits a sequence of lists of bytes.
/// The program must then handle those lists of bytes in some way.
/// Here, the code uses a UTF-8 decoder (provided in the `dart:convert` library)
/// to convert the sequence of bytes into a sequence
/// of Dart strings.
///
/// Another common use of streams is for user-generated events
/// in a web app: The following code listens for mouse clicks on a button.
/// ```dart import:html
/// querySelector('#myButton')!.onClick.forEach((_) => print('Click.'));
/// ```
/// ## Other resources
///
/// * The [dart:async section of the library tour][asynchronous-programming]:
///   A brief overview of asynchronous programming.
///
/// * [Use Future-Based APIs][futures-tutorial]: A closer look at Futures and
///   how to use them to write asynchronous Dart code.
///
/// * [Futures and Error Handling][futures-error-handling]: Everything you
///   wanted to know about handling errors and exceptions when working with
///   Futures (but were afraid to ask).
///
/// * [The Event Loop and Dart](https://dart.dev/articles/event-loop/):
///   Learn how Dart handles the event queue and microtask queue, so you can
///   write better asynchronous code with fewer surprises.
///
/// * [test package: Asynchronous Tests][test-readme]: How to test asynchronous
///   code.
///
/// [asynchronous-programming]: https://dart.dev/guides/libraries/library-tour#dartasync---asynchronous-programming
/// [futures-tutorial]: https://dart.dev/codelabs/async-await
/// [futures-error-handling]: https://dart.dev/guides/libraries/futures-error-handling
/// [test-readme]: https://pub.dev/packages/test
///
/// {@category Core}
library dart.async;

import "dart:collection" show HashMap;
import "dart:_internal"
    show
        CastStream,
        CastStreamTransformer,
        checkNotNullable,
        IterableElementError,
        nullFuture,
        printToZone,
        printToConsole,
        Since,
        typeAcceptsNull,
        unsafeCast,
        vmIsolateUnsendable;

part 'async_error.dart';
part 'broadcast_stream_controller.dart';
part 'deferred_load.dart';
part 'future.dart';
part 'future_extensions.dart';
part 'future_impl.dart';
part 'schedule_microtask.dart';
part 'stream.dart';
part 'stream_controller.dart';
part 'stream_impl.dart';
part 'stream_pipe.dart';
part 'stream_transformers.dart';
part 'timer.dart';
part 'zone.dart';
