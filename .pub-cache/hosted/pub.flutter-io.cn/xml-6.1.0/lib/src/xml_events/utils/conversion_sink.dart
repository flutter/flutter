/// A sink that executes [callback] for each addition.
class ConversionSink<T> implements Sink<T> {
  ConversionSink(this.callback);

  void Function(T data) callback;

  @override
  void add(T data) => callback(data);

  @override
  void close() {}
}
