import 'dart:async';

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
class CompositeSubscription {
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
  bool get allPaused => _subscriptionsList.isNotEmpty
      ? _subscriptionsList.every((it) => it.isPaused)
      : false;

  /// Adds new subscription to this composite.
  ///
  /// Throws an exception if this composite was disposed
  StreamSubscription<T> add<T>(StreamSubscription<T> subscription) {
    assert(subscription != null, 'Subscription cannot be null');
    if (isDisposed) {
      throw ('This composite was disposed, try to use new instance instead');
    }
    _subscriptionsList.add(subscription);
    return subscription;
  }

  /// Cancels subscription and removes it from this composite.
  void remove(StreamSubscription<dynamic> subscription) {
    subscription.cancel();
    _subscriptionsList.remove(subscription);
  }

  /// Cancels all subscriptions added to this composite. Clears subscriptions collection.
  ///
  /// This composite can be reused after calling this method.
  void clear() {
    _subscriptionsList.forEach((it) => it.cancel());
    _subscriptionsList.clear();
  }

  /// Cancels all subscriptions added to this composite. Disposes this.
  ///
  /// This composite can't be reused after calling this method.
  void dispose() {
    clear();
    _isDisposed = true;
  }

  /// Pauses all subscriptions added to this composite.
  void pauseAll([Future<void> resumeSignal]) =>
      _subscriptionsList.forEach((it) => it.pause(resumeSignal));

  /// Resumes all subscriptions added to this composite.
  void resumeAll() => _subscriptionsList.forEach((it) => it.resume());
}

/// Extends the [StreamSubscription] class with the ability to be added to [CompositeSubscription] container.
extension AddToCompositeSubscriptionExtension<T> on StreamSubscription<T> {
  /// Adds this subscription to composite container for subscriptions.
  void addTo(CompositeSubscription compositeSubscription) =>
      compositeSubscription.add(this);
}
