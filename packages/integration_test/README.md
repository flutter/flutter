# integration_test

This package enables self-driving testing of Flutter code on devices and emulators.
It adapts flutter_test results into a format that is compatible with `flutter drive`
and native Android instrumentation testing.

## Usage

Add a dependency on the `integration_test` and `flutter_test` package in the
`dev_dependencies` section of `pubspec.yaml`. For plugins, do this in the
`pubspec.yaml` of the example app.

Create a `integration_test/` directory for your package. In this directory,
create a `<name>_test.dart`, using the following as a starting point to make
assertions.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("failing test example", (WidgetTester tester) async {
    expect(2 + 2, equals(5));
  });
}
```

### Driver Entrypoint

An accompanying driver script will be needed that can be shared across all
integration tests. Create a file named `integration_test.dart` in the
`test_driver/` directory with the following contents:

```dart
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
```

You can also use different driver scripts to customize the behavior of the app
under test. For example, `FlutterDriver` can also be parameterized with
different [options](https://api.flutter.dev/flutter/flutter_driver/FlutterDriver/connect.html).
See the [extended driver](https://github.com/flutter/plugins/tree/master/packages/integration_test/example/test_driver/integration_test_extended_driver.dart) for an example.

### Package Structure

Your package should have a structure that looks like this:

```
lib/
  ...
integration_test/
  foo_test.dart
  bar_test.dart
test/
  # Other unit tests go here.
test_driver/
  integration_test.dart
```

[Example](https://github.com/flutter/plugins/tree/master/packages/integration_test/example)

## Using Flutter Driver to Run Tests

These tests can be launched with the `flutter drive` command.

To run the `integration_test/foo_test.dart` test with the
`test_driver/integration_test.dart` driver, use the following command:

```sh
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/foo_test.dart
```

### Web

Make sure you have [enabled web support](https://flutter.dev/docs/get-started/web#set-up)
then [download and run](https://flutter.dev/docs/cookbook/testing/integration/introduction#6b-web)
the web driver in another process.

Use following command to execute the tests:

```sh
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/foo_test.dart \
  -d web-server
```

## Android Device Testing

Create an instrumentation test file in your application's
**android/app/src/androidTest/java/com/example/myapp/** directory (replacing
com, example, and myapp with values from your app's package name). You can name
this test file `MainActivityTest.java` or another name of your choice.

```java
package com.example.myapp;

import androidx.test.rule.ActivityTestRule;
import dev.flutter.plugins.integration_test.FlutterTestRunner;
import org.junit.Rule;
import org.junit.runner.RunWith;

@RunWith(FlutterTestRunner.class)
public class MainActivityTest {
  @Rule
  public ActivityTestRule<MainActivity> rule = new ActivityTestRule<>(MainActivity.class, true, false);
}
```

Update your application's **myapp/android/app/build.gradle** to make sure it
uses androidx's version of `AndroidJUnitRunner` and has androidx libraries as a
dependency.

```gradle
android {
  ...
  defaultConfig {
    ...
    testInstrumentationRunner "androidx.test.runner.AndroidJUnitRunner"
  }
}

dependencies {
    testImplementation 'junit:junit:4.12'

    // https://developer.android.com/jetpack/androidx/releases/test/#1.2.0
    androidTestImplementation 'androidx.test:runner:1.2.0'
    androidTestImplementation 'androidx.test.espresso:espresso-core:3.2.0'
}
```

To run `integration_test/foo_test.dart` on a local Android device (emulated or
physical):

```sh
./gradlew app:connectedAndroidTest -Ptarget=`pwd`/../integration_test/foo_test.dart
```

## Firebase Test Lab

If this is your first time testing with Firebase Test Lab, you'll need to follow
the guides in the [Firebase test lab
documentation](https://firebase.google.com/docs/test-lab/?gclid=EAIaIQobChMIs5qVwqW25QIV8iCtBh3DrwyUEAAYASAAEgLFU_D_BwE)
to set up a project.

To run a test on Android devices using Firebase Test Lab, use gradle commands to build an
instrumentation test for Android, after creating `androidTest` as suggested in the last section.

```bash
pushd android
# flutter build generates files in android/ for building the app
flutter build apk
./gradlew app:assembleAndroidTest
./gradlew app:assembleDebug -Ptarget=<path_to_test>.dart
popd
```

Upload the build apks Firebase Test Lab, making sure to replace <PATH_TO_KEY_FILE>,
<PROJECT_NAME>, <RESULTS_BUCKET>, and <RESULTS_DIRECTORY> with your values.

```bash
gcloud auth activate-service-account --key-file=<PATH_TO_KEY_FILE>
gcloud --quiet config set project <PROJECT_NAME>
gcloud firebase test android run --type instrumentation \
  --app build/app/outputs/apk/debug/app-debug.apk \
  --test build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk\
  --timeout 2m \
  --results-bucket=<RESULTS_BUCKET> \
  --results-dir=<RESULTS_DIRECTORY>
```

You can pass additional parameters on the command line, such as the
devices you want to test on. See
[gcloud firebase test android run](https://cloud.google.com/sdk/gcloud/reference/firebase/test/android/run).

## iOS Device Testing

You need to change `iOS/Podfile` to avoid test target statically linking to the plugins. One way is to
link all of the plugins dynamically:

```
target 'Runner' do
  use_frameworks!
  ...
end
```

To run `integration_test/foo_test.dart` on your iOS device, rebuild your iOS
targets with Flutter tool.

```sh
# Pass --simulator if building for the simulator.
flutter build ios integration_test/foo_test.dart
```

Open Xcode project (by default, it's `ios/Runner.xcodeproj`). Create a test target
(navigating `File > New > Target...` and set up the values) and a test file `RunnerTests.m` and
change the code. You can change `RunnerTests.m` to the name of your choice.

```objective-c
#import <XCTest/XCTest.h>
#import <integration_test/IntegrationTestIosTest.h>

INTEGRATION_TEST_IOS_RUNNER(RunnerTests)
```

Now you can start RunnerTests to kick-off integration tests!
