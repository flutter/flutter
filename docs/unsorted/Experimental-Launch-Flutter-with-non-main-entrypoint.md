_**Everything in this doc and linked from this doc is experimental. These details WILL change. Do not use these instructions or APIs in production code because we will break you.**_

# Launch Flutter with non-main entrypoint

Typically, a Flutter app begins execution at the Dart method called `main()`, however this is not required. Developers can specify a different Dart entrypoint:

## FlutterActivity

Two options are available to specify a non-standard Dart entrypoint for a `FlutterActivity`.

### Option 1: AndroidManifest.xml meta-data

Specify your desired Dart entrypoint as `meta-data` in your `AndroidManifest.xml`:

```xml
<application ...>
  <activity
    android:name="io.flutter.embedding.android.FlutterActivity"
    ...
    >
    <meta-data
      android:name="io.flutter.Entrypoint"
      android:value="myMainDartMethod"
      />
  </activity>
</application>
```

Option 2: Subclass `FlutterActivity` and override a method

Override the `getDartEntrypointFunctionName()` method:

```java
public class MyFlutterActivity extends FlutterActivity {
  @Override
  @NonNull
  public String getDartEntrypointFunctionName() {
    return "myMainDartMethod";
  }
}
```

## FlutterFragment

Two options are available to specify a non-standard Dart entrypoint for a `FlutterFragment`.

### Option 1: Use FlutterFragmentBuilder

```java
// Example for a FlutterFragment that creates its own FlutterEngine.
//
// Note: a Dart entrypoint cannot be set when using a cached engine because the
// cached engine has already started executing Dart.
FlutterFragment flutterFragment = new FlutterFragment
  .withNewEngine()
  .dartEntrypoint("myMainDartMethod")
  .build();
```

### Option 2: Subclass FlutterFragment

```java
public class MyFlutterFragment extends FlutterFragment {
  @Override
  @NonNull
  public String getDartEntrypointFunctionName() {
    return "myMainDartMethod";
  }
}
```

## FlutterEngine

When manually initializing a `FlutterEngine`, you take on the responsibility of
invoking the desired Dart entrypoint, even if you want the standard `main()` method.
The following examples illustrate how to execute a Dart entrypoint with a
`FlutterEngine`.

Example using standard entrypoint:

```java
// Instantiate a new FlutterEngine.
FlutterEngine flutterEngine = new FlutterEngine(context);

// Start executing Dart using a default entrypoint, which resolves to "main()".
flutterEngine
  .getDartExecutor()
  .executeDartEntrypoint(
    DartEntrypoint.createDefault();
  );
```

Example using custom entrypoint:

```java
// Instantiate a new FlutterEngine.
FlutterEngine flutterEngine = new FlutterEngine(context);

// Start executing Dart using a custom entrypoint.
flutterEngine
  .getDartExecutor()
  .executeDartEntrypoint(
    new DartEntrypoint(
      FlutterMain.findAppBundlePath(),
      "myMainDartMethod"
    )
  );
```

# Avoid Tree Shaking in Release

When you build in release mode, your Dart code is tree-shaken. This means that the compiler removes any Dart code that it thinks you're not using. This includes your special entrypoints. To avoid crashing in release mode as a result of tree-shaking, be sure to place the following `@pragma` above each of your custom entrypoints.

```dart
@pragma('vm:entry-point')
void myMainDartMethod() {
  // implementation
}
```