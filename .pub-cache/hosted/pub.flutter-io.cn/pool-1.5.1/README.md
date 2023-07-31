[![Dart CI](https://github.com/dart-lang/pool/actions/workflows/ci.yml/badge.svg)](https://github.com/dart-lang/pool/actions/workflows/ci.yml)
[![pub package](https://img.shields.io/pub/v/pool.svg)](https://pub.dev/packages/pool)
[![package publisher](https://img.shields.io/pub/publisher/pool.svg)](https://pub.dev/packages/pool/publisher)

The pool package exposes a `Pool` class which makes it easy to manage a limited
pool of resources.

The easiest way to use a pool is by calling `withResource`. This runs a callback
and returns its result, but only once there aren't too many other callbacks
currently running.

```dart
// Create a Pool that will only allocate 10 resources at once. After 30 seconds
// of inactivity with all resources checked out, the pool will throw an error.
final pool = new Pool(10, timeout: new Duration(seconds: 30));

Future<String> readFile(String path) {
  // Since the call to [File.readAsString] is within [withResource], no more
  // than ten files will be open at once.
  return pool.withResource(() => new File(path).readAsString());
}
```

For more fine-grained control, the user can also explicitly request generic
`PoolResource` objects that can later be released back into the pool. This is
what `withResource` does under the covers: requests a resource, then releases it
once the callback completes.

`Pool` ensures that only a limited number of resources are allocated at once.
It's the caller's responsibility to ensure that the corresponding physical
resource is only consumed when a `PoolResource` is allocated.

```dart
class PooledFile implements RandomAccessFile {
  final RandomAccessFile _file;
  final PoolResource _resource;

  static Future<PooledFile> open(String path) {
    return pool.request().then((resource) {
      return new File(path).open().then((file) {
        return new PooledFile._(file, resource);
      });
    });
  }

  PooledFile(this._file, this._resource);

  // ...

  Future<RandomAccessFile> close() {
    return _file.close.then((_) {
      _resource.release();
      return this;
    });
  }
}
```
