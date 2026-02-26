typedef VoidCallback = void Function();

abstract class ObservableInterface<T> {
  /// Register a closure to be called when the object notifies its listeners.
  void addListener(VoidCallback listener);

  /// Remove a previously registered closure from the list of closures that the
  /// object notifies.
  void removeListener(VoidCallback listener);

  /// The current value of the observable.
  T get value;
}

abstract class ObservableModifierInterface<T> extends ObservableInterface<T> {
  /// Sets the value of the observable and notifies its listeners.
  // ignore: avoid_setters_without_getters, there is getter in the parent class
  set value(T value);
}

final class Observable<T> implements ObservableInterface<T> {
  Observable(this.value);
  T value;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}

final class ObservableModifier<T> implements ObservableModifierInterface<T> {
  ObservableModifier(this.value);
  T value;

  @override
  void addListener(VoidCallback listener) {
    // TODO: implement addListener
  }

  @override
  void removeListener(VoidCallback listener) {
    // TODO: implement removeListener
  }
}
