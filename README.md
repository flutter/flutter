Sky
===

Sky is an experimental, high-performance UI framework for mobile apps. Sky helps
you create apps with beautiful user interfaces and high-quality interactive
design that run smoothly at 120 Hz.

Sky consists of two components:

1. *The Sky engine.* The [engine](engine) is the core of the system system.
   Written in C++, the engine provides the muscle of the Sky system. The engine
   provides several primitives, including a soft real-time scheduler and a
   hierarchial, retained-mode graphics system, that let you build high-quality
   apps.

2. *The Sky framework.* The [framework](framework) makes it easy to build apps
   using Sky by providing familiar user interface widgets, such as buttons,
   infinite lists, and animations, on top of the engine using Dart. These
   extensible components follow a functional programming style inspired by
   React.

Sky is still experimental. We're experimenting with different ideas and
exploring various approaches, many of which won't work and will need to be
discarded, but, if we're lucky, some of which might turn out to be useful.

Examples
--------

The simplest Sky app is, appropriately, HelloWorldApp:

```dart
import 'package:sky/framework/fn.dart';

class HelloWorldApp extends App {
  Node build() {
    return new Text('Hello, world!');
  }
}

void main() {
  new HelloWorldApp();
}
```

Execution starts in `main`, which creates the `HelloWorldApp`. The framework
then marks `HelloWorldApp` as dirty, which schedules it to build during the next
animation frame. Each animation frame, the framework calls `build` on all the
dirty components and diffs the virtual `Node` hierarchy returned this frame with
the hierarchy returned last frame. Any differences are then applied as mutations
to the physical heiarchy retained by the engine.

For a more featureful example, please see the
[example stocks app](examples/stocks-fn/lib/stocks_app.dart).

Services
--------

Sky apps can access services from the host operating system using Mojo. For
example, you can access the network using the `network_service.mojom` interface.
Although you can use these low-level interfaces directly, you might prefer to
access these services via libraries in the framework. For example, the
`fetch.dart` library wraps the underlying `network_service.mojom` in an
ergonomic interface:

```dart
import 'package:sky/framework/net/fetch.dart';

void foo() {
  fetch('example.txt').then((Response response) {
    print(response.bodyAsString());
  });
}
```

Supported platforms
-------------------

Currently, Sky supports the Android and Mojo operating systems.

Specifications
--------------

We're documenting Sky with a [set of technical specifications](specs) that
define precisely the behavior of the engine.  Currently both the implementation
and the specification are in flux, but hopefully they'll converge over time.

Contributing
------------

Instructions for building and testing Sky are contained in [HACKING.md](HACKING.md).
