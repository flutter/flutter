import 'dart:async';

import 'package:rxdart/src/utils/future.dart';

/// When listener listens to it, creates a resource object from resource factory function,
/// and creates a [Stream] from the given factory function and resource as argument.
/// Finally when the stream finishes emitting items or stream subscription
/// is cancelled (call [StreamSubscription.cancel] or `Stream.listen(cancelOnError: true)`),
/// call the disposer function on resource object.
///
/// The [UsingStream] is a way you can instruct an Stream to create
/// a resource that exists only during the lifespan of the Stream
/// and is disposed of when the Stream terminates.
///
/// [Marble diagram](http://reactivex.io/documentation/operators/images/using.c.png)
///
/// ### Example
///
///     UsingStream<int, Queue<int>>(
///       () => Queue.of([1, 2, 3]),
///       (r) => Stream.fromIterable(r),
///       (r) => r.clear(),
///     ).listen(print); // prints 1, 2, 3
class UsingStream<T, R> extends StreamView<T> {
  /// Construct a [UsingStream] that creates a resource object from [resourceFactory],
  /// and then creates a [Stream] from [streamFactory] and resource as argument.
  /// When the Stream terminates, call [disposer] on resource object.
  UsingStream(
    FutureOr<R> Function() resourceFactory,
    Stream<T> Function(R) streamFactory,
    FutureOr<void> Function(R) disposer,
  ) : super(_buildStream(resourceFactory, streamFactory, disposer));

  static Stream<T> _buildStream<T, R>(
    FutureOr<R> Function() resourceFactory,
    Stream<T> Function(R) streamFactory,
    FutureOr<void> Function(R) disposer,
  ) {
    late StreamController<T> controller;
    var resourceCreated = false;
    late R resource;
    StreamSubscription<T>? subscription;

    void useResource(R r) {
      resource = r;
      resourceCreated = true;

      Stream<T> stream;
      try {
        stream = streamFactory(r);
      } catch (e, s) {
        controller.addError(e, s);
        controller.close();
        return;
      }

      subscription = stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
    }

    controller = StreamController<T>(
      sync: true,
      onListen: () {
        final FutureOr<R> resourceOrFuture;
        try {
          resourceOrFuture = resourceFactory();
        } catch (e, s) {
          controller.addError(e, s);
          controller.close();
          return;
        }

        if (resourceOrFuture is R) {
          useResource(resourceOrFuture);
        } else {
          resourceOrFuture.then((r) {
            // if the controller was cancelled before the resource is created,
            // we should dispose the resource
            if (!controller.hasListener) {
              disposer(r);
            } else {
              useResource(r);
            }
          }).onError<Object>((e, s) {
            controller.addError(e, s);
            controller.close();
          });
        }
      },
      onPause: () => subscription?.pause(),
      onResume: () => subscription?.resume(),
      onCancel: () {
        final futureOr = resourceCreated ? disposer(resource) : null;
        final cancelFuture = subscription?.cancel();
        return waitTwoFutures(cancelFuture, futureOr);
      },
    );

    return controller.stream;
  }
}
