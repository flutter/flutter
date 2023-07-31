# Synchronized guide

* [Development notes](synchronized_development.md)

## Development guide

### basic usage

```dart
var lock = new Lock();
// ...
await lock.synchronized(() async {
  // do you stuff
  // await ...
});
```

Have in mind that the `Lock` instance must be shared between calls in order to effectively prevent concurrent execution. For instance, in the example below the lock instance is the same between all `myMethod()` calls.

```
class MyClass {
  Lock _lock = new Lock();

  Future<void> myMethod() async {
    await _lock.synchronized(() async {
      step1();
      step2();
      step3();
    });
  }
}
```

### Turn any object into a lock

Add lock ability to any object.

```dart
import 'package:synchronized/extension.dart';
```

Then you can simple call on any object.

 ```dart
myObject.synchronized(() async {
  // ...uninterrupted action
});

class MyClass {
  /// Perform a long action that won't be called more than once at a time.
  /// 
  Future performAction() {
    // Lock at the instance level
    return synchronized(() async {
      // ...uninterrupted action
    });
  }
}
```

Or you can synchronize at the class level

 ```dart
class MyClass {
  /// Perform a long action that won't be called more than once at a time.
  Future performClassAction() {
    // Lock at the class level
    return runtimeType.synchronized(() async {
      // ...uninterrupted action
    });
  }
}
```