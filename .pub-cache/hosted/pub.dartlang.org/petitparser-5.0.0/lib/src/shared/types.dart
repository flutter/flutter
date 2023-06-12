/// A generic callback function type returning a value of type [R] for a given
/// input of type [T].
typedef Callback<T, R> = R Function(T value);

/// A generic predicate function type returning `true` or `false` for a given
/// input of type [T].
typedef Predicate<T> = Callback<T, bool>;

/// A generic void callback with an argument of type [T], but not return value.
typedef VoidCallback<T> = Callback<T, void>;
