Getting Started with Sky
========================

Sky apps are written in Dart. To get started, we need to set up Dart SDK:

 - Install the [Dart SDK](https://www.dartlang.org/downloads/).
 - Ensure that `$DART_SDK` is set to the path of your Dart SDK.

Once we have the Dart SDK, we can creating a new directory and
adding a [pubspec.yaml](https://www.dartlang.org/tools/pub/pubspec.html):

```yaml
name: your_app_name
dependencies:
  sky: any
```

Once the pubspec is in place, create a `lib` directory (where your dart code
will go) ensure that the 'dart' and 'pub' executables are on your $PATH and
run the following:

 - `mkdir lib`
 - `pub get && pub run sky:init`

Currently the Sky Engine assumes the entry point for your application is a
`main` function in `lib/main.dart`:

```dart
import 'package:sky/widgets/basic.dart';

class HelloWorldApp extends App {
  Widget build() {
    return new Center(
      child: new Text('Hello, world!')
    );
  }
}

void main() {
  runApp(new HelloWorldApp());
}
```

Execution starts in `main`, which instructs the framework to run a new
instance of the `HelloWorldApp`. The framework then calls the `build()`
function on `HelloWorldApp` to create a tree of widgets, some of which might
be other `Components`, which in turn have `build()` functions that generate
more widgets iteratively to create the widget hierarchy. To learn more about
the widget system, please see the [widgets tutorial](lib/widgets/README.md).

Setup your Android device
-------------------------

Currently Sky requires an Android device running the Lollipop (or newer) version
of the Android operating system.

 - Install the `adb` tool from the [Android SDK](https://developer.android.com/sdk/installing/index.html)
   and ensure that `adb (inside `platform-tools` in the Android SDK) is in your
   `$PATH`.

 - Enable developer mode on your device by visiting `Settings > About phone`
   and tapping the `Build number` field five times.

 - Enable `USB debugging` in `Settings > Developer options`.

 - Using a USB cable, plug your phone into your computer. If prompted on your
   device, authorize your computer to access your device.

Running a Sky application
-------------------------

The `sky` pub package includes a `sky_tool` script to assist in running
Sky applications inside the `SkyDemo.apk` harness.  The `sky_tool` script
expects to be run from the root directory of your application's package (i.e.,
the same directory that contains the `pubspec.yaml` file). To run your app,
follow these instructions:

 - `./packages/sky/sky_tool start` to start the dev server and upload your
   app to the device.
   (NOTE: add a `--install` flag to install `SkyDemo.apk` if it is not already
   installed on the device.)

 - Use `adb logcat` to view any errors or Dart `print()` output from the app.
   `adb logcat -s sky` can be used to filter only adb messages from
   `SkyDemo.apk`.

 Building a standalone APK
 -------------------------

 Although it is possible to build a standalone APK containing your application,
 doing so right now is difficult. If you're feeling brave, you can see how we
 build the `Stocks.apk` in [example/stocks](example/stocks). Eventually we plan
 to make this much easier and support platforms other than Android, but that work
 still in progress.

Debugging
---------

Sky uses [Observatory](https://www.dartlang.org/tools/observatory/) for
debugging and profiling. While running your Sky app using `sky_tool`, you can
access Observatory by navigating your web browser to
[http://localhost:8181/](http://localhost:8181/).
