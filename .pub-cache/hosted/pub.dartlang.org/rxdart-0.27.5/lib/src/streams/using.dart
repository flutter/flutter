import 'dart:async';

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
    R Function() resourceFactory,
    Stream<T> Function(R) streamFactory,
    FutureOr<void> Function(R) disposer,
  ) : super(_buildStream(resourceFactory, streamFactory, disposer));

  static Stream<T> _buildStream<T, R>(
    R Function() resourceFactory,
    Stream<T> Function(R) streamFactory,
    FutureOr<void> Function(R) disposer,
  ) {
    late StreamController<T> controller;
    var resourceCreated = false;
    late R resource;
    StreamSubscription<T>? subscription;

    controller = StreamController<T>(
      sync: true,
      onListen: () {
        try {
          resource = resourceFactory();
          resourceCreated = true;
        } catch (e, s) {
          controller.addError(e, s);
          controller.close();
          return;
        }

        Stream<T> stream;
        try {
          stream = streamFactory(resource);
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
      },
      onPause: () => subscription!.pause(),
      onResume: () => subscription!.resume(),
      onCancel: () async {
        final futureOr = resourceCreated ? disposer(resource) : null;
        final cancelFuture = subscription?.cancel();

        final futures = [
          // ignore: unnecessary_cast
          if (futureOr is Future<void>) futureOr as Future<void>,
          if (cancelFuture is Future<void>) cancelFuture,
        ];
        if (futures.isNotEmpty) {
          await Future.wait(futures);
        }
      },
    );

    return controller.stream;
  }
}
