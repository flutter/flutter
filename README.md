# <img src="https://flutter.dev/images/flutter-mark-square-100.png" alt="Flutter" width="40" height="40" /> Flutter [![Join Gitter Chat Channel -](https://badges.gitter.im/flutter/flutter.svg)](https://gitter.im/flutter/flutter?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![Build Status - Cirrus](https://api.cirrus-ci.com/github/flutter/flutter.svg)](https://cirrus-ci.com/github/flutter/flutter/master)
[![Coverage Status -](https://coveralls.io/repos/github/flutter/flutter/badge.svg?branch=master)](https://coveralls.io/github/flutter/flutter?branch=master)


# Build beautiful native apps in record time

Flutter is Google’s mobile app SDK for crafting high-quality native interfaces on iOS and Android in record time. Flutter works with existing code, is used by developers and organizations around the world, and is free and open source.

### Documentation

* **Main site: [flutter.dev][]**
* [Install](https://flutter.dev/get-started/install/)
* [Get started](https://flutter.dev/get-started/)
* [Contribute](https://github.com/flutter/flutter/blob/master/CONTRIBUTING.md#contributing-to-flutter)

## Fast development

Flutter's <em>hot reload</em> helps you quickly
and easily experiment, build UIs, add features, and fix
bugs. Experience sub-second reload times,
without losing state, on
emulators, simulators, and hardware for iOS
and Android.

<img src="https://raw.githubusercontent.com/flutter/website/master/src/images/intellij/hot-reload.gif" alt="Make a change in your code, and your app changes instantly.">

## Expressive and flexible UI
Quickly ship features with a focus on native end-user experiences.
Layered architecture allows full customization, which results in incredibly
fast rendering and expressive and flexible designs.


Delight your users with Flutter's built-in
beautiful Material Design and
Cupertino (iOS-flavor) widgets, rich motion APIs,
smooth natural scrolling, and platform awareness.

[<img src="https://github.com/flutter/website/blob/master/src/images/homepage/screenshot-1.png" width="270" height="480" alt="Brand-first shopping design" align="left">](https://github.com/flutter/flutter/tree/master/examples/flutter_gallery/lib/demo/animation)
[<img src="https://github.com/flutter/website/blob/master/src/images/homepage/screenshot-2.png" width="270" height="480" alt="Fitness app design">](https://github.com/flutter/posse_gallery)

[<img src="https://github.com/flutter/website/blob/master/src/images/homepage/screenshot-3.png" width="270" height="480" alt="Contact app design" align="left">](https://github.com/flutter/flutter/blob/master/examples/flutter_gallery/lib/demo/contacts_demo.dart)
[<img src="https://github.com/flutter/website/blob/master/src/images/homepage/ios-friendlychat.png" width="270" height="480" alt="iOS chat app design">](https://codelabs.developers.google.com/codelabs/flutter/)

Browse the <a href="https://flutter.dev/widgets/">widget catalog</a>.

## Modern, reactive framework

Easily compose your UI with Flutter's
modern functional-reactive framework and
rich set of platform, layout, and foundation widgets.
Solve your tough UI challenges with
powerful and flexible APIs for 2D, animation, gestures,
effects, and more.

```dart
class CounterState extends State<Counter> {
  int counter = 0;

  void increment() {
    // Tells the Flutter framework that state has changed,
    // so the framework can run build() and update the display.
    setState(() {
      counter++;
    });
  }

  Widget build(BuildContext context) {
    // This method is rerun every time setState is called.
    // The Flutter framework has been optimized to make rerunning
    // build methods fast, so that you can just rebuild anything that
    // needs updating rather than having to individually change
    // instances of widgets.
    return new Row(
      children: <Widget>[
        new RaisedButton(
          onPressed: increment,
          child: new Text('Increment'),
        ),
        new Text('Count: $counter'),
      ],
    );
  }
}
```

Browse the <a href="https://flutter.dev/widgets/">widget catalog</a>
and learn more about the
<a href="https://flutter.dev/widgets-intro/">functional-reactive framework</a>.

## Access native features and SDKs

Make your app come to life
with platform APIs, 3rd party SDKs,
and native code.
Flutter lets you reuse your existing Java/Kotlin and ObjC/Swift code,
and access native features and SDKs on Android and iOS.

Accessing platform features is easy. Here is a snippet from our <a href="https://github.com/flutter/flutter/tree/master/examples/platform_channel">interop example</a>:

```dart
Future<Null> getBatteryLevel() async {
  var batteryLevel = 'unknown';
  try {
    int result = await methodChannel.invokeMethod('getBatteryLevel');
    batteryLevel = 'Battery level: $result%';
  } on PlatformException {
    batteryLevel = 'Failed to get battery level.';
  }
  setState(() {
    _batteryLevel = batteryLevel;
  });
}
```

Learn how to use <a href="https://flutter.dev/using-packages/">packages</a>, or
write <a href="https://flutter.dev/platform-channels/">platform channels</a>,
to access native code, APIs, and SDKs.

## Unified app development

Flutter has the tools and libraries to help you easily
bring your ideas to life on iOS and Android.
If you don't have any mobile development experience, Flutter
is an easy and fast way to build beautiful mobile apps.
If you are an experienced iOS or Android developer,
you can use Flutter for your views and leverage much of your
existing Java/Kotlin/ObjC/Swift investment.

### Build

* **Beautiful app UIs**
    * Rich 2D GPU-accelerated APIs
    * Reactive framework
    * Animation/motion APIs
    * Material Design and iOS widgets
* **Fluid coding experience**
    * Sub-second, stateful hot reload
    * IntelliJ: refactor, code completion, etc
    * Dart language and core libs
    * Package manager
* **Full-featured apps**
    * Interop with mobile OS APIs & SDKs
    * Gradle/Java/Kotlin
    * Cocoapods/ObjC/Swift

### Optimize

* **Test**
    * Unit testing
    * Integration testing
    * On-device testing
* **Debug**
    * IDE debugger
    * Web-based debugger
    * async/await aware
    * Expression evaluator
* **Profile**
    * Timeline
    * CPU and memory
    * In-app perf charts

### Deploy

* **Compile**
    * Native ARM code
    * Dead code elimination
* **Distribution**
    * App Store
    * Play Store

Learn more about what makes Flutter special in the
<a href="https://flutter.dev/technical-overview/">technical overview</a>.

Join us in our [Gitter chat room](https://gitter.im/flutter/flutter) or join our public mailing list,
[flutter-dev@googlegroups.com](https://groups.google.com/forum/#!forum/flutter-dev).

[flutter.dev]: https://flutter.dev/
