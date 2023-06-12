import 'dart:async';

import 'package:rxdart/src/utils/subscription.dart';

/// Acts as a container for multiple subscriptions that can be canceled at once
/// e.g. view subscriptions in Flutter that need to be canceled on view disposal
///
/// Can be cleared or disposed. When disposed, cannot be used again.
/// ### Example
/// // init your subscriptions
/// composite.add(stream1.listen(listener1))
/// ..add(stream2.listen(listener1))
/// ..add(stream3.listen(listener1));
///
/// // clear them all at once
/// composite.clear();
class CompositeSubscription implements StreamSubscription<Never> {
  bool _isDisposed = false;

  final List<StreamSubscription<dynamic>> _subscriptionsList = [];

  /// Checks if this composite is disposed. If it is, the composite can't be used again
  /// and will throw an error if you try to add more subscriptions to it.
  bool get isDisposed => _isDisposed;

  /// Returns the total amount of currently added [StreamSubscription]s
  int get length => _subscriptionsList.length;

  /// Checks if there currently are no [StreamSubscription]s added
  bool get isEmpty => _subscriptionsList.isEmpty;

  /// Checks if there currently are [StreamSubscription]s added
  bool get isNotEmpty => _subscriptionsList.isNotEmpty;

  /// Whether all managed [StreamSubscription]s are currently paused.
  bool get allPaused =>
      _subscriptionsList.isNotEmpty &&
      _subscriptionsList.every((s) => s.isPaused);

  /// Adds new subscription to this composite.
  ///
  /// Throws an exception if this composite was disposed
  StreamSubscription<T> add<T>(StreamSubscription<T> subscription) {
    if (isDisposed) {
      throw StateError(
          'This $runtimeType was disposed, consider checking `isDisposed` or try to use new instance instead');
    }
    _subscriptionsList.add(subscription);
    return subscription;
  }

  /// Remove the subscription from this composite and cancel it if it has been removed.
  Future<void>? remove(
    StreamSubscription<dynamic> subscription, {
    bool shouldCancel = true,
  }) =>
      _subscriptionsList.remove(subscription) && shouldCancel
          ? subscription.cancel()
          : null;

  /// Cancels all subscriptions added to this composite. Clears subscriptions collection.
  ///
  /// This composite can be reused after calling this method.
  Future<void>? clear() {
    final cancelAllDone = _subscriptionsList.cancelAll();
    _subscriptionsList.clear();
    return cancelAllDone;
  }

  /// Cancels all subscriptions added to this composite. Disposes this.
  ///
  /// This composite can't be reused after calling this method.
  Future<void>? dispose() {
    final clearDone = clear();
    _isDisposed = true;
    return clearDone;
  }

  /// Pauses all subscriptions added to this composite.
  void pauseAll([Future<void>? resumeSignal]) =>
      _subscriptionsList.pauseAll(resumeSignal);

  /// Resumes all subscriptions added to this composite.
  void resumeAll() => _subscriptionsList.resumeAll();

  // implements StreamSubscription

  @override
  Future<void> cancel() => dispose() ?? Future<void>.value(null);

  @override
  bool get isPaused => allPaused;

  @override
  void pause([Future<void>? resumeSignal]) => pauseAll(resumeSignal);

  @override
  void resume() => resumeAll();

  @override
  Never asFuture<E>([E? futureValue]) => _unsupportedError();

  @override
  Never onData(void Function(Never data)? handleData) => _unsupportedError();

  @override
  Never onDone(void Function()? handleDone) => _unsupportedError();

  @override
  Never onError(Function? handleError) => _unsupportedError();

  Never _unsupportedError() => throw UnsupportedError(
      'Cannot change handlers of CompositeSubscription.');
}

/// Extends the [StreamSubscription] class with the ability to be added to [CompositeSubscription] container.
extension AddToCompositeSubscriptionExtension<T> on StreamSubscription<T> {
  /// Adds this subscription to composite container for subscriptions.
  void addTo(CompositeSubscription compositeSubscription) =>
      compositeSubscription.add(this);
}
