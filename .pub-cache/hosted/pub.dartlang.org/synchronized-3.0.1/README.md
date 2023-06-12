# synchronized

Basic lock mechanism to prevent concurrent access to asynchronous code.

[![pub package](https://img.shields.io/pub/v/synchronized.svg)](https://pub.dev/packages/synchronized)

## Goal

You were missing hard to debug deadlocks, here it is! 

The goal is to propose a solution similar to critical sections and offer a simple `synchronized` API à la Java style.
It provides a basic Lock/Mutex solution to allow features like transactions.

The name is biased as we are single threaded in Dart. However since we write asychronous code (await) like we would
write synchronous code, it makes the overall API feel the same.

The goal is to ensure for a single process (single isolate) that some asynchronous operations can run
without conflict. It won't solve cross-process (or cross-isolate) synchronization.

For single process (single isolate) accessing some resources (database..), it can help to
 * Provide transaction on database system that don't have transaction mechanism (mongodb, file system)
 * In html application make sure some asynchronous UI operation are not conflicting (login, transition)

## Feature

 * By default a lock is not reentrant
 * Timeout support
 * Support for reentrant lock (using Zone)
 * Consistent behavior (i.e. if it is unlocked calling synchronized grab the lock)
 * Values and Errors are properly reported to the caller
 * Work on Browser, DartVM and Flutter
 * No dependencies (other than the sdk itself)
 
It differs from the `pool` package used with a resource count of 1 by supporting a reentrant option

## Usage

A simple usage example:

```dart
import 'package:synchronized/synchronized.dart';

main() async {
  // Use this object to prevent concurrent access to data
  var lock = new Lock();
  ...
  await lock.synchronized(() async {
    // Only this block can run (once) until done 
    ...
  });
}
```
    
If you need a re-entrant lock you can use

```dart
var lock = new Lock(reentrant: true);
// ...
await lock.synchronized(() async {
  // do some stuff
  // ... 
  
  await lock.synchronized(() async {
    // other stuff
  }
});
```
        
A basic lock is not reentrant by default and does not use Zone. It behaves like an async executor with a pool capacity
of 1

```dart
var lock = Lock();
// ...
lock.synchronized(() async {
  // do some stuff
  // ...
});
```
    
The return value is preserved

```dart
int value = await lock.synchronized(() {
  return 1;
});
```

Using the `package:synchronized/extension.dart` import, you can turn any object into a lock. `synchronized()` can then be called on any
object

```dart
import 'package:synchronized/extension.dart';

class MyClass {

  /// Perform a long action that won't be called more than one at a time.
  Future performAction() {
    // Lock at the instance level
    return synchronized(() async {
      // ...uninterrupted action
    });
  }
}
```
    
## How it works

The next tasks is executed once the previous one is done

Re-entrant locks uses `Zone` to know in which context a block is running in order to be reentrant. It maintains a list
of inner tasks to be awaited for.

## Example

Consider the following dummy code

```dart
Future writeSlow(int value) async {
  await Future.delayed(new Duration(milliseconds: 1));
  stdout.write(value);
}

Future write(List<int> values) async {
  for (int value in values) {
    await writeSlow(value);
  }
}

Future write1234() async {
  await write([1, 2, 3, 4]);
}
```

Doing 

```dart
write1234();
write1234();
```
would print

    11223344
    
while doing

```dart
lock.synchronized(write1234);
lock.synchronized(write1234);
```

would print

    12341234

## The Lock instance

Have in mind that the `Lock` instance must be shared between calls in order to effectively prevent concurrent execution. For instance, in the example below the lock instance is the same between all `myMethod()` calls.

```dart
class MyClass {
  final _lock = new Lock();

  Future<void> myMethod() async {
    await _lock.synchronized(() async {
      step1();
      step2();
      step3();
    });
  }
}
```

Typically you would create a global or static instance Lock to prevent concurrent access to
a global resource or a class instance Lock to prevent concurrent modifications of
class instance data and resources.

## Features and bugs

Please feel free to: 
* file feature requests and bugs at the [issue tracker][tracker]
* or [contact me][contact_me]
* [How to][how_to] guide


[tracker]: https://github.com/tekartik/synchronized.dart/issues
[contact_me]: https://contact.tekartik.com/
[how_to]: https://github.com/tekartik/synchronized.dart/blob/master/synchronized/doc/how_to.md

