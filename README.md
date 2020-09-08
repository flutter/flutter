# <img src="https://flutter.io/images/flutter-mark-square-100.png" alt="Flutter" width="40" height="40" /> Flutter [![Join Gitter Chat Channel -](https://badges.gitter.im/flutter/flutter.svg)](https://gitter.im/flutter/flutter?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge) [![Build Status - Travis](https://travis-ci.org/flutter/flutter.svg?branch=master)](https://travis-ci.org/flutter/flutter) [![Build Status - AppVeyor](https://ci.appveyor.com/api/projects/status/meyi9evcny64a2mg/branch/master?svg=true)](https://ci.appveyor.com/project/flutter/flutter/branch/master) [![Build Status - Cirrus](https://api.cirrus-ci.com/github/flutter/flutter.svg)](https://cirrus-ci.com/github/flutter/flutter) [![Coverage Status -](https://coveralls.io/repos/github/flutter/flutter/badge.svg?branch=master)](https://coveralls.io/github/flutter/flutter?branch=master)

A new mobile app SDK to help developers and designers build modern mobile apps for iOS and Android. Flutter is an open-source project currently in beta.

### Documentation

* **Main site: [flutter.io][]**
* [Install](https://flutter.io/setup/)
* [Get started](https://flutter.io/getting-started/)
* [Contribute](CONTRIBUTING.md)

## Fast development

Flutter's <em>hot reload</em> helps you quickly
and easily experiment, build UIs, add features, and fix
bugs faster. Experience sub-second reload times,
without losing state, on
emulators, simulators, and hardware for iOS
and Android.

<img src="https://user-images.githubusercontent.com/919717/28131204-0f8c3cda-66ee-11e7-9428-6a0513eac75d.gif" alt="Make a change in your code, and your app is changed instantly.">

## Expressive, Beautiful UIs

Delight your users with Flutter's built-in
beautiful Material Design and
Cupertino (iOS-flavor) widgets, rich motion APIs,
smooth natural scrolling, and platform awareness.

[<img src="https://github.com/flutter/website/blob/master/images/homepage/screenshot-1.png" width="270" height="480" alt="Brand-first shopping design" align="left">](https://github.com/flutter/flutter/tree/master/examples/flutter_gallery/lib/demo/animation)
[<img src="https://github.com/flutter/website/blob/master/images/homepage/screenshot-2.png" width="270" height="480" alt="Fitness app design">](https://github.com/flutter/posse_gallery)

[<img src="https://github.com/flutter/website/blob/master/images/homepage/screenshot-3.png" width="270" height="480" alt="Contact app design" align="left">](https://github.com/flutter/flutter/blob/master/examples/flutter_gallery/lib/demo/contacts_demo.dart)
[<img src="https://github.com/flutter/website/blob/master/images/homepage/ios-friendlychat.png" width="270" height="480" alt="iOS chat app design">](https://codelabs.developers.google.com/codelabs/flutter-firebase)

Browse the <a href="https://flutter.io/widgets/">widget catalog</a>.

## Modern, Reactive Framework

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

Browse the <a href="https://flutter.io/widgets/">widget catalog</a>
and learn more about the
<a href="https://flutter.io/widgets-intro/">functional-reactive framework</a>.

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

Learn how to use <a href="https://flutter.io/using-packages/">packages</a>, or
write <a href="https://flutter.io/platform-channels/">platform channels</a>,
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
<a href="https://flutter.io/technical-overview/">technical overview</a>.

Join us in our [Gitter chat room](https://gitter.im/flutter/flutter) or join our public mailing list,
[flutter-dev@googlegroups.com](https://groups.google.com/forum/#!forum/flutter-dev).

[flutter.io]: https://flutter.io/
