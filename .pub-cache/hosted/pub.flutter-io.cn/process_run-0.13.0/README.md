# process_run

Process run helpers for Linux/Win/Mac.

### shell

Allows to run script from Mac/Windows/Linux in a portable way. Empty lines are added for lisibility

```dart
import 'package:process_run/shell.dart';
```

Run a simple script:

```dart
var shell = Shell();

await shell.run('''

# Display some text
echo Hello

# Display dart version
dart --version

# Display pub version
pub --version

''');
```

More information [on shell here](https://github.com/tekartik/process_run.dart/blob/master/packages/process_run/doc/shell.md)

### which

Like unix `which`, it searches for installed executables

```dart
import 'package:process_run/which.dart';
```

Find `flutter` and `firebase` executables:

```dart
var flutterExectutable = whichSync('flutter');
var firebaseExectutable = whichSync('firebase');
```

### shell bin utility

Binary utility that allow changing from the command line the environment (var, path, alias) used in Shell.

More information [on shell bin here](https://github.com/tekartik/process_run.dart/blob/master/packages/process_run/doc/shell_bin_info.md)

### Flutter context

#### MacOS

If you want to run executable in a MacOS flutter context, you need to disable sandbox mode. See 
[Removing sandboxing](https://stackoverflow.com/questions/7018354/remove-sandboxing) and 
[ProcessException: Operation not permitted on macOS](https://github.com/tekartik/process_run.dart/issues/3) 

In `macos/Runner/DebugProfile.entitlements` and `macos/Runner/Release.entitlements`, change:

```
<dict>
	<key>com.apple.security.app-sandbox</key>
	<true/>
</dict>
```

to

```
<dict>
	<key>com.apple.security.app-sandbox</key>
	<false/>
</dict>
```
### Additional features

Addtional features and information are [available here](https://github.com/tekartik/process_run.dart/blob/master/packages/process_run/doc/more.md)

