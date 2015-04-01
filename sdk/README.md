Sky
===

Sky is an experimental, high-performance UI framework for mobile apps. Sky helps
you create apps with beautiful user interfaces and high-quality interactive
design that run smoothly at 120 Hz.

Sky consists of two components:

1. *The Sky engine.* The engine is the core of the system. Written in C++, the
   engine provides the muscle of the Sky system. The engine provides
   several primitives, including a soft real-time scheduler and a hierarchial,
   retained-mode graphics system, that let you build high-quality apps.

2. *The Sky framework.* The [framework](packages/sky/lib/framework) makes it
   easy to build apps using Sky by providing familiar user interface widgets,
   such as buttons, infinite lists, and animations, on top of the engine using
   Dart. These extensible components follow a functional programming style
   inspired by [React](http://facebook.github.io/react/).

We're still iterating on Sky heavily, which means the framework and underlying
engine are both likely to change in incompatible ways several times, but if
you're interested in trying out the system, this document can help you get
started.

Examples
--------

The simplest Sky app is, appropriately, HelloWorldApp:

```dart
import 'package:sky/framework/fn.dart';

class HelloWorldApp extends App {
  UINode build() {
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
dirty components and diffs the virtual `UINode` hierarchy returned this frame with
the hierarchy returned last frame. Any differences are then applied as mutations
to the physical hierarchy retained by the engine.

For more examples, please see the [examples directory](examples/).

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

void main() {
  fetch('example.txt').then((Response response) {
    print(response.bodyAsString());
  });
}
```

Set up your computer
--------------------

1. Install the Dart SDK:
  - https://www.dartlang.org/tools/download.html

2. Install the ``adb`` tool from the Android SDK:
  - https://developer.android.com/sdk/installing/index.html

3. Install the Sky SDK:
  - ``git clone https://github.com/domokit/sky_sdk.git``

4. Ensure sure $DART_SDK is set to the path of your Dart SDK and 'adb'
   (inside 'platform-tools' in the android sdk) is in your $PATH.

Set up your device
------------------

Currently Sky requires an Android device running the Lollipop (or newer) version
of the Android operating system.

1. Enable developer mode on your device by visiting ``Settings > About phone``
   and tapping the ``Build number`` field five times.

2. Enable ``USB debugging`` in ``Settings > Developer options``.

3. Using a USB cable, plug your phone into your computer. If prompted on your
   device, authorize your computer to access your device.

Running a Sky application
-------------------------

1. ``packages/sky/lib/sky_tool --install examples/stocks/main.sky``
   The --install flag is only necessary the first time to install SkyDemo.apk.

2.  Use ``adb logcat`` to view any errors or Dart print() output from the app.
