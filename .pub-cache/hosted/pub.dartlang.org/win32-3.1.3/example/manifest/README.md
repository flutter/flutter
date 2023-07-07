# Application Manifests

This example demonstrates the use of app manifests in Windows.

By default, Windows emphasizes maximum backwards compatibility, even to the
point of modeling older behavior on newer systems. For example, if you call the
`GetVersionEx()` function to ask Windows what version it is, it will return the
same version information, regardless of whether you are running Windows 8,
Windows 8.1, or Windows 10.

You can tell Windows that your app is aware of later versions with an [app
manifest](https://docs.microsoft.com/en-us/windows/win32/sysinfo/targeting-your-application-at-windows-8-1),
which opts your app into new behavior.

You can see this behavior in action by running `version.dart` (which calls
`GetVersionEx()`) in a few different configurations. The documented behavior
below assumes that you are running Windows 10.

Note that Windows 11 reports itself as 10.0.22000.0, so these APIs cannot be
used to differentiate between Windows 10 and Windows 11. For that, you should
check the build number. An example of that can be found in `sysinfo.dart`.

## 1. Running a Dart file directly

```cmd
dart version.dart
```

In this scenario, the Dart command-line utility is called to run the Dart file.
Since no app manifest exists, this command returns `Windows 6.2` (which
is the version number reported by Windows 8).

## 2. Compiling with an app manifest

Run this command to compile `version.dart`:

```cmd
dart compile exe -o version.exe version.dart
```

Supplied in this folder is `version.exe.manifest`, which is an app compat
manifest that expressly identifies that this app is designed for Windows 10.

Now, you should see the same app code respond with `Windows 10.0`.

## 3. Executing without an app manifest

If you copy or rename the executable to something else and run it again:

```cmd
copy version.exe version2.exe
version2.exe
```

You'll see that the same executable, in the absence of a matching app manifest,
reports `Windows 6.2` as before.
