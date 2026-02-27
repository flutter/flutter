# The `flutter` tool

The `flutter` command-line tool is how developers (or IDEs on behalf of developers) interact
with Flutter.

`flutter --help` lists the developer-facing commands that `flutter` supports.

`flutter --help --verbose` lists _all_ the commands that `flutter` supports, in particular, it also lists the
features that are of use to Flutter contributors.

These include:

- `flutter update-packages`, which downloads all the Dart dependencies for all
  Dart packages in the Flutter repository.
- `flutter analyze --flutter-repo`, as described on [Using the Dart analyzer](../contributing/Using-the-Dart-analyzer.md).

When contributing to Flutter, use `git pull --rebase` or `git rebase upstream/main`
rather than `flutter upgrade`.

The `flutter` tool itself is built when you run `flutter` for the first time and each time
you run `git pull --rebase` (or `flutter upgrade`, or anything that changes the current commit).

## Documentation

The rest of this document assumes that `flutter` and `dart` on your path resolve
to the scripts inside [`/path/to/flutter/bin`](https://github.com/flutter/flutter/tree/main/bin). If either `flutter` or `dart`
on your path resolves to another binary, you should either prepend the Flutter SDK
`bin` dir to the _front_ of your `$PATH`, or ensure each invocation uses the path
to the Flutter SDK controlled `flutter` and `dart` binaries.

Markdown documentation can be found for some commands in [flutter/packages/flutter_tools/doc/](https://github.com/flutter/flutter/tree/main/packages/flutter_tools/doc).

## Analysis

To run dart analysis on the Flutter tool codebase, run:

```shell
cd flutter/packages/flutter_tools
dart analyze .
```

To format:

```shell
cd flutter/packages/flutter_tools
dart format .
```

Note, if relying on in editor analysis and you check out a new Flutter SDK commit,
you may need to restart your editor so that a new analyzer instance is started from
the new Dart version.

On CI, some additional ad hoc tests are run in the `Linux analyze` CI build. To verify
a failing `Linux analyze` build when Dart analysis is passing locally, you can run
the full script that CI runs:

```shell
dart --enable-asserts dev/bots/analyze.dart
```

## Making changes to the `flutter` tool

You can run the tool from source by running `bin/flutter-dev`.

Alternatively, delete the `bin/cache/flutter_tools.snapshot` file or locally commit
your change in git and then run `flutter` again. This will rebuild the tool
from local source.

This step is not required if you are launching `flutter_tools.dart` (either by running or testing) from an IDE.

The `flutter_tools` tests run inside the Dart command line VM rather than in the
flutter shell. To run the tests, run:

```shell
dart test test_file_or_directory_path
```

or

```shell
flutter test test_file_or_directory_path
```

To run or debug the tests in IDE, make sure `FLUTTER_ROOT` directory is set up.
For example, in Android Studio, select the configuration for the test, click "Edit Configurations...",
under "Environment Variables" section, enter `FLUTTER_ROOT=directory_to_your_flutter_framework_repo`.

The pre-built flutter tool runs in release mode with the Dart VM service off by default.
To enable debugging mode and Dart DevTools for the `flutter` tool, uncomment the
`FLUTTER_TOOL_ARGS` line in the `bin/flutter` (or `bin/flutter-dev`) shell script.

## Debugging the `flutter` command-line tool in VS Code

The following `launch.json` config will allow you to debug the Flutter tool:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "flutter_tools",
      "request": "launch",
      "type": "dart",
      "program": "${workspaceFolder}/bin/flutter_tools.dart",
      "env": {
        "FLUTTER_ROOT": "${workspaceFolder}/../../"
      },
      "args": ["doctor", "-v"]
    }
  ]
}
```

Note that:

1. The current workspace directory is assumed to be the [root of the flutter_tools package](https://github.com/flutter/flutter/tree/main/packages/flutter_tools).
2. Update `args` to be whatever arguments you want passed to the tool (i.e. which sub-command you want to debug).
3. To debug the `flutter` command-line tool while running a `flutter` project, add `cwd` to the configuration with the path of the project.

```
"configurations": [
        {
            "name": "flutter_tools",
            ...
            "cwd": "/path/to/flutter/project",
        }
]
```

Also, ensure `flutter_tools (flutter)` is selected on the Debug tab.

![Screenshot 2023-03-22 at 3 08 34 PM](https://user-images.githubusercontent.com/15619084/227027470-a50661bc-98fd-4b6d-afc6-8b6cc7e399ca.png)

With this configured, set a breakpoint(s) inline in a source file, and start debugging from the menu with Run -> Start Debugging.

For more on debugging, including detailed information on `launch.json`, in VS Code refer to the VS Code [documentation](https://code.visualstudio.com/docs/editor/debugging).

## Debugging the `flutter` command-line tool in Android Studio

Developers are expected to be able to run `flutter` commands without needing in-depth knowledge of the tool. However, there are some cases in which you may find it useful to debug `flutter` commands, especially when it's difficult to reproduce your issue.

The `flutter` command is just a wrapper and it will finally run `$FLUTTER_ROOT/bin/cache/flutter_tools.snapshot` generated by flutter_tools package.

That's to say, you can debug `flutter` command as a Dart Command Line App.
Let's take `flutter doctor -vv` as an example. You can debug it following the steps below:

a. Open the flutter_tools package in Android Studio

b. Create a new Dart Command Line App by `Add Configurations` and configure it as below:

![Dart Command Line App](https://user-images.githubusercontent.com/817851/60478095-0f860b00-9cb4-11e9-9e14-71d2e0e13494.png)
The Dart file refers to bin/flutter_tools.dart where the main function is located. Program arguments refers to the arguments for flutter command, it's passed to main method directly. Working directory is which flutter project you want to run the flutter command, and is not always necessary.

c. The dart sdk is used to run the bin/flutter_tools.dart and expected to configure as below:
![Dart SDK Configuration](https://user-images.githubusercontent.com/817851/60479048-09455e00-9cb7-11e9-9f6d-bbf6cabafdd1.png)

d. If you make some changes to the flutter_tools package, you may need to do as 'Making changes to the `flutter` tool' says above because flutter command might be triggered implicitly by gradle, etc.

Though those steps given above are under Android Studio, the logic also works for other IDEs.

## Adding, removing, or making changes to Dart dependencies

Once you've edited a `pubspec.yaml` file in the Flutter repository to change a package's dependencies,
run `flutter update-packages --force-upgrade` to resynchronize all the `pubspec.yaml` files.
This does a full cross-package version solve for the entire repository.

If you need to pin a particular version, edit the table at the top of the `update_packages.dart` file.

## Using a locally-built engine with the `flutter` tool

To allow the tool to be used with a locally-built engine, the `flutter` tool accepts three
global parameters:

- `local-engine`, which specifies which build of the engine to run
- `local-engine-host`, which specifies which build of the engine to use for host artifacts like the dart compiler
- `local-engine-src-path` (optional), which specifies the path to your engine sources

A typical invocation would be: `--local-engine=android_debug_unopt --local-engine-host=host_debug_unopt`.

If your engine is in a directory other than the `engine` directory that is a peer to the
framework repository's `flutter` directory, then you must specify `--local-engine-src-path` as well.

You can also set the environment variable `$FLUTTER_ENGINE` instead of specifying `--local-engine-src-path`.

The `--local-engine` should specify the build of the engine to use, e.g. a profile build for Android, a debug build for Android, or whatever. It must match the other arguments provided to the tool, e.g. don't use the `android_debug_unopt` build when you specify `--release`, since the Debug build expects to compile and run Dart code in a JIT environment, while `--release` implies a Release build which uses AOT compilation.

If you've modified the public API of `dart:ui` in your local build of the engine
and you need to be able to analyze the framework code with the new API,
you will need to add a `dependency_overrides` section pointing to your
modified `package:sky_engine` to the
`pubspec.yaml` for the flutter app you're using the custom engine
with. A typical example would be:

```yaml
dependency_overrides:
  sky_engine:
    path: /path/to/flutter/engine/src/out/host_debug/gen/dart-pkg/sky_engine
```

Replace `host_debug` with the actual build that you want to use (similar to `--local-engine`, but typically
a host build rather than a device build).

If you do this, you can omit `--local-engine-src-path` and not bother to set `$FLUTTER_ENGINE`, as
the `flutter` tool will use these paths to determine the engine also! The tool tries really hard to
figure out where your local build of the engine is if you specify `--local-engine`.

Similar to the [dwds debugging workflow](https://github.com/dart-lang/webdev/blob/main/dwds/CONTRIBUTING.md#with-flutter-tools-recommended), the Flutter tool can also be debugged with DevTools by invoking the tool with `flutter/bin/dart --observe flutter/packages/flutter_tools/bin/flutter_tools.dart` and then using the **first** DevTools URL that is printed to the console.

## Adding dependencies to the Flutter Tool

Each dependency we add to Flutter and the Flutter Tool makes the repo more difficult to update and requires additional work from our clients to update.

Only packages which are developed by the Dart and/or Flutter teams should be permitted into the Flutter Tool. Any third party packages that are currently in use are exempt for historical reasons, but their versions must be pinned in [update_packages.dart](https://github.com/flutter/flutter/blob/main/packages/flutter_tools/lib/src/commands/update_packages.dart#L23) . These packages should only be updated after a human review of the new version. If a Dart and/or Flutter team package depends transitively on an un-maintained or unknown package, we should work with the owners to remove or replace that transitive dependency.

Instead of adding a new package, ask yourself the following questions:

- Does the functionality already exist in the SDK or an already depended on package?
- Could I develop the same functionality myself in a few hours of work?
- Is the package actively developed and maintained by a trusted party?
