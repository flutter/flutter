typedef VoidCallback = void Function();

/// An object that maintains a list of listeners.
///
/// The listeners are typically used to notify clients that the object has been
/// updated.
///
/// There are two variants of this interface:
///
///  * [ValueListenable], an interface that augments the [Listenable] interface
///    with the concept of a _current value_.
///
///  * [Animation], an interface that augments the [ValueListenable] interface
///    to add the concept of direction (forward or reverse).
///
/// Many classes in the Flutter API use or implement these interfaces. The
/// following subclasses are especially relevant:
///
///  * [ChangeNotifier], which can be subclassed or mixed in to create objects
///    that implement the [Listenable] interface.
///
///  * [ValueNotifier], which implements the [ValueListenable] interface with
///    a mutable value that triggers the notifications when modified.
///
/// The terms "notify clients", "send notifications", "trigger notifications",
/// and "fire notifications" are used interchangeably.
///
/// See also:
///
///  * [AnimatedBuilder], a widget that uses a builder callback to rebuild
///    whenever a given [Listenable] triggers its notifications. This widget is
///    commonly used with [Animation] subclasses, hence its name, but is by no
///    means limited to animations, as it can be used with any [Listenable]. It
///    is a subclass of [AnimatedWidget], which can be used to create widgets
///    that are driven from a [Listenable].
///  * [ValueListenableBuilder], a widget that uses a builder callback to
///    rebuild whenever a [ValueListenable] object triggers its notifications,
///    providing the builder with the value of the object.
///  * [InheritedNotifier], an abstract superclass for widgets that use a
///    [Listenable]'s notifications to trigger rebuilds in descendant widgets
///    that declare a dependency on them, using the [InheritedWidget] mechanism.
///  * [Listenable.merge], which creates a [Listenable] that triggers
///    notifications whenever any of a list of other [Listenable]s trigger their
///    notifications.
abstract class Listenable {
  /// This constructor enables subclasses to provide const constructors so that
  /// they can be used in const expressions.
  const Listenable();

  /// Return a [Listenable] that triggers when any of the given [Listenable]s
  /// themselves trigger.
  ///
  /// Once the factory is called, items must not be added or removed from the iterable.
  /// Doing so will lead to memory leaks or exceptions.
  ///
  /// The iterable may contain nulls; they are ignored.
  factory Listenable.merge(Iterable<Listenable?> listenables) = _MergingListenable;

  /// Register a closure to be called when the object notifies its listeners.
  void addListener(VoidCallback listener);

  /// Remove a previously registered closure from the list of closures that the
  /// object notifies.
  void removeListener(VoidCallback listener);
}

class _MergingListenable extends Listenable {
  _MergingListenable(this._children);

  final Iterable<Listenable?> _children;

  @override
  void addListener(VoidCallback listener) {
    for (final Listenable? child in _children) {
      child?.addListener(listener);
    }
  }

  @override
  void removeListener(VoidCallback listener) {
    for (final Listenable? child in _children) {
      child?.removeListener(listener);
    }
  }

  @override
  String toString() {
    return 'Listenable.merge([${_children.join(", ")}])';
  }
}

/// An interface for subclasses of [Listenable] that expose a [value].
///
/// This interface is implemented by [ValueNotifier<T>] and [Animation<T>], and
/// allows other APIs to accept either of those implementations interchangeably.
///
/// See also:
///
///  * [ValueListenableBuilder], a widget that uses a builder callback to
///    rebuild whenever a [ValueListenable] object triggers its notifications,
///    providing the builder with the value of the object.
abstract class ValueListenable<T> extends Listenable {
  /// This constructor enables subclasses to provide const constructors so that
  /// they can be used in const expressions.
  const ValueListenable();

  /// The current value of the object.
  ///
  /// When the value changes, the callbacks registered with [addListener] will be
  /// invoked.
  @override
  T get value;
}

/// A [ValueListenable] that can be modified.
class ListenableModifier<T> extends ValueListenable<T> {
  /// Sets the value of the observable and notifies its listeners.
  // ignore: avoid_setters_without_getters, there is getter in the parent class
  set value(T value) => throw UnimplementedError();

  @override
  T get value => throw UnimplementedError();

  @override
  void addListener(VoidCallback listener) => throw UnimplementedError();

  @override
  void removeListener(VoidCallback listener) => throw UnimplementedError();
}
