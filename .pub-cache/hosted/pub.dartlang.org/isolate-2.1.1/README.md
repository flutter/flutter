[![Dart CI](https://github.com/dart-lang/isolate/actions/workflows/test-package.yml/badge.svg)](https://github.com/dart-lang/isolate/actions/workflows/test-package.yml)

# DISCONTINUED

This package has been discontinued, and will no longer be maintained.

------------


Helps with isolates and isolate communication in Dart.
Requires the `dart:isolate` library being available.
Isolates are not available for Dart on the web.

The package contains individual libraries with different purposes.

### Creating send ports and responding to messages.

The "ports.dart" sub-library contains functionality
for creating `SendPort`s and reacting to values sent to those ports.

### Working with isolates and running functions in other isolates.

The "isolate_runner.dart" sub-library introduces an `IsolateRunner` class
that gives easy access to the `Isolate` functionality, and also
gives a way to run new functions in the isolate repeatedly, instead of
just on the initial `spawn` call.

### A central registry for values that can be used across isolates.

The "registry.dart" sub-library provides a way to create an
object registry, and give access to it across different isolates.

### Balancing load across several isolates.

The "load_balancer.dart" sub-library can manage multiple `Runner` objects,
including `IsolateRunner`, and run functions on the currently least loaded
runner.

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/dart-lang/isolate/issues
