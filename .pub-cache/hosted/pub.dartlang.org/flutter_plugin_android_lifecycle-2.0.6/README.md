# Flutter Android Lifecycle Plugin

[![pub package](https://img.shields.io/pub/v/flutter_plugin_android_lifecycle.svg)](https://pub.dev/packages/flutter_plugin_android_lifecycle)

A Flutter plugin for Android to allow other Flutter plugins to access  Android `Lifecycle` objects
in the plugin's binding.

The purpose of having this plugin instead of exposing an Android `Lifecycle` object in the engine's
Android embedding plugins API is to force plugins to have a pub constraint that signifies the
major version of the Android `Lifecycle` API they expect.

|             | Android |
|-------------|---------|
| **Support** | SDK 16+ |

## Installation

Add `flutter_plugin_android_lifecycle` as a [dependency in your pubspec.yaml file](https://flutter.dev/using-packages/).

## Example

Use a `FlutterLifecycleAdapter` within another Flutter plugin's Android implementation, as shown
below:

```java
import androidx.lifecycle.Lifecycle;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding;
import io.flutter.embedding.engine.plugins.lifecycle.FlutterLifecycleAdapter;

public class MyPlugin implements FlutterPlugin, ActivityAware {
  @Override
  public void onAttachedToActivity(ActivityPluginBinding binding) {
    Lifecycle lifecycle = FlutterLifecycleAdapter.getActivityLifecycle(binding);
    // Use lifecycle as desired.
  }

  //...
}
```

[Feedback welcome](https://github.com/flutter/flutter/issues) and
[Pull Requests](https://github.com/flutter/plugins/pulls) are most welcome!
