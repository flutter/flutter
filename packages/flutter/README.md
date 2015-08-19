Getting Started with Sky
========================

Sky apps are written in Dart. To get started, we need to set up Dart SDK:

 - Install the [Dart SDK](https://www.dartlang.org/downloads/):
   - Mac: `brew tap dart-lang/dart && brew install dart`
   - Linux: See [https://www.dartlang.org/downloads/linux.html](https://www.dartlang.org/downloads/linux.html)
 - Ensure that `$DART_SDK` is set to the path of your Dart SDK and that the
   `dart` and `pub` executables are on your `$PATH`.

Once you have installed Dart SDK, create a new directory and add a
[pubspec.yaml](https://www.dartlang.org/tools/pub/pubspec.html):

```yaml
name: your_app_name
dependencies:
  sky: any
  sky_tools: any
```

Next, create a `lib` directory (which is where your Dart code will go) and use
the `pub` tool to fetch the Sky package and its dependencies:

 - `mkdir lib`
 - `pub upgrade`

Sky assumes the entry point for your application is a `main` function in
`lib/main.dart`:

```dart
import 'package:sky/widgets.dart';

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
the widget system, please see the
[widgets tutorial](https://github.com/domokit/sky_engine/blob/master/sky/packages/sky/lib/widgets/README.md).

Setting up your Android device
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
Sky applications inside the `SkyShell.apk` harness.  The `sky_tool` script
expects to be run from the root directory of your application's package (i.e.,
the same directory that contains the `pubspec.yaml` file). To run your app,
follow these instructions:

 - The first time: `./packages/sky/sky_tool start --install --checked && adb logcat -s sky chromium`

 - Subsequent times: `./packages/sky/sky_tool start --checked && adb logcat -s sky chromium`

The `sky_tool start` command starts the dev server and uploads your app to the device.
The `--install` flag installs `SkyShell.apk` if it is not already installed on the device.
The `--checked` flag triggers checked mode, in which types are checked, asserts are run, and
various [debugging features](lib/base/debug.dart) are enabled.
The `adb logcat` command logs errors and Dart `print()` output from the app. The `-s sky chromium`
argument limits the output to just output from Sky Dart code and the Sky Engine C++ code (which
for historical reasons currently uses the tag `chromium`.)

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
build the `Stocks.apk` in
[examples/stocks](https://github.com/domokit/sky_engine/tree/master/examples/stocks).
Eventually we plan to make this much easier and support platforms other than
Android, but that work still in progress.
