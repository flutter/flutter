Getting started with Sky
========================

Sky apps are written in Dart. To get started, we need to set up Dart SDK:

 - Install the [Dart SDK](https://www.dartlang.org/downloads/):
   - Mac: `brew tap dart-lang/dart && brew install dart`
   - Linux, see [https://www.dartlang.org/downloads/linux.html](https://www.dartlang.org/downloads/linux.html)
 - Ensure that `$DART_SDK` is set to the path of your Dart SDK and that the
   `dart` and `pub` executables are on your `$PATH`.

Once you have installed Dart SDK, create a new directory and add a
[pubspec.yaml](https://www.dartlang.org/tools/pub/pubspec.html):

```yaml
name: your_app_name
dependencies:
  sky: any
```

Next, create a `lib` directory (which is where your Dart code will go) and use
the `pub` tool to fetch the Sky package and its dependencies:

 - `mkdir lib`
 - `pub get && pub run sky:init`

Sky assumes the entry point for your application is a `main` function in
`lib/main.dart`:

```dart
import 'package:sky/widgets/basic.dart';

class HelloWorldApp extends App {
  Widget build() {
    return new Center(child: new Text('Hello, world!'));
  }
}

void main() {
  runApp(new HelloWorldApp());
}
```

Execution starts in `main`, which in this example runs a new instance of the `HelloWorldApp`.
The `HelloWorldApp` builds a `Text` widget containing the traditional `Hello, world!`
string and centers it on the screen using a `Center` widget. To learn more about
the widget system, please see the [widgets tutorial](lib/widgets/README.md).

Setup your Android device
-------------------------

Currently Sky requires an Android device running the Lollipop (or newer) version
of the Android operating system.

 - Install the `adb` tool from the [Android SDK](https://developer.android.com/sdk/installing/index.html?pkg=tools):
  - Mac: `brew install android-platform-tools`
  - Linux: `sudo apt-get install android-tools-adb`

 - Enable developer mode on your device by visiting `Settings > About phone`
   and tapping the `Build number` field five times.

 - Enable `Android debugging` in `Settings > Developer options`.

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

Debugging
---------

Sky uses [Observatory](https://www.dartlang.org/tools/observatory/) for
debugging and profiling. While running your Sky app using `sky_tool`, you can
access Observatory by navigating your web browser to
[http://localhost:8181/](http://localhost:8181/).

Building a standalone APK
-------------------------

Although it is possible to build a standalone APK containing your application,
doing so right now is difficult. If you're feeling brave, you can see how we
build the `Stocks.apk` in [example/stocks](example/stocks). Eventually we plan
to make this much easier and support platforms other than Android, but that work
still in progress.
