Contributing to Flutter
=======================

[![Build Status](https://travis-ci.org/flutter/flutter.svg)](https://travis-ci.org/flutter/flutter)

Things you will need
--------------------

 * Linux or Mac OS X. (Windows is not yet supported.)
 * git (used for source version control).
 * An IDE. We recommend [Atom](https://github.com/flutter/engine/wiki/Using-Atom-with-Flutter).
 * An ssh client (used to authenticate with GitHub).
 * Python (used by some of our tools).
 * The Dart SDK (see [Issue #54](https://github.com/flutter/flutter/issues/54)
   about downloading the Dart SDK automatically). Note: If you're also
   working on the Flutter engine, you can use the copy of the Dart SDK
   in `.../engine/src/third_party/dart-sdk/dart-sdk`.
   - [https://www.dartlang.org/downloads/archive/](https://www.dartlang.org/downloads/archive/)
 * The Android platform tools (see [Issue #55](https://github.com/flutter/flutter/issues/55)
   about downloading the Android platform tools automatically).
   Note: If you're also working on the Flutter engine, you can use the
   copy of the Android platform tools in
   `.../engine/src/third_party/android_tools/sdk/platform-tools`.
   - Mac: `brew install android-platform-tools`
   - Linux: `sudo apt-get install android-tools-adb`

Getting the code and configuring your environment
-------------------------------------------------

 * Ensure all the dependencies described in the previous section, in particular
   git, ssh, and python are installed. Ensure that `dart`, `pub`, and `adb`
   (from the Dart SDK and the Android platform tools) are in your path (e.g.,
   that `which dart` and `which adb` print sensible output).
 * Fork `https://github.com/flutter/flutter` into your own GitHub account. If
   you already have a fork, and are now installing a development environment on
   a new machine, make sure you've updated your fork so that you don't use stale
   configuration options from long ago.
 * If you haven't configured your machine with an SSH key that's known to github then
   follow the directions here: https://help.github.com/articles/generating-ssh-keys/.
 * `git clone git@github.com:<your_name_here>/flutter.git`
 * `cd flutter`
 * `git remote add upstream git@github.com:flutter/flutter.git` (So that you
   fetch from the master repository, not your clone, when running `git fetch`
   et al.)
 * Run `dart ./dev/update_packages.dart` This will fetch all the Dart packages that
   Flutter depends on. You can replicate what this script does by running
   `pub get` in each directory that contains a `pubspec.yaml` file.
 * Add this repository's `bin` directory to your path. That will let you use the
   `flutter` command in this directory more easily. (If you have previously
   activated the `flutter` package using `pub`, you should deactivate it and use
   the script in `bin` instead: `pub global deactivate flutter`.)

Running the examples
--------------------

To run an example with a prebuilt binary from the cloud, switch to that
example's directory, run `pub get` to make sure its dependencies have been
downloaded, and use `flutter start`. Make sure you have a device connected over
USB and debugging enabled on that device.

 * `cd examples/hello_world; flutter start`

You can also specify a particular Dart file to run if you want to run an example
that doesn't have a `lib/main.dart` file using the `-t` command-line option. For
example, to run the `tabs.dart` example in the [examples/widgets](examples/widgets)
directory on a connected Android device, from that directory you would run:

 * `flutter start -t tabs.dart`

When running code from the examples directory, any changes you make to the
example code, as well as any changes to Dart code in the
[packages/flutter](packages/flutter) directory and subdirectories, will
automatically be picked when you relaunch the app.  You can do the same for your
own code by mimicking the `pubspec.yaml` files in the `examples` subdirectories.

Running the tests
-----------------

To automatically find all files named `_test.dart` inside a package and run them inside the flutter shell as a test use the `flutter test` command, e.g:

 * `cd examples/stocks`
 * `flutter test`

Individual tests can also be run directly, e.g. `flutter test lib/my_app_test.dart`

Flutter tests use [package:flutter_test](https://github.com/flutter/flutter/tree/master/packages/flutter_test) which provides flutter-specific extensions on top of [package:test](https://pub.dartlang.org/packages/test).

`flutter test` runs tests inside the flutter shell.  Some packages inside the flutter repository can be run inside the dart command line VM as well as the flutter shell, `packages/newton` and `packages/flutter_tools` are two such examples:

 * `cd packages/newton`
 * `pub run test`

`flutter test --flutter-repo` is a shortcut for those working on the flutter repository itself which finds and runs all tests inside the flutter repository regardless of the current working directory.

If you've built [your own flutter engine](#working-on-the-engine-and-the-framework-at-the-same-time), you can pass `--debug` or `--release` to change what flutter shell `flutter test` uses.

Note: Flutter tests are headless, you won't see any UI. You can use
`print` to generate console output or you can interact with the DartVM
via observatory at [http://localhost:8181/](http://localhost:8181/).

Adding a test
-------------

To add a test, simply create a file whose name ends with `_test.dart`
in the `packages/unit/test` directory. The test should have a `main`
function and use the `test` package.

Contributing code
-----------------

We gladly accept contributions via GitHub pull requests.

To start working on a patch:

 * `git fetch upstream`
 * `git checkout upstream/master -b name_of_your_branch`
 * Hack away. Please peruse our [style guides](https://github.com/flutter/engine/blob/master/sky/specs/style-guide.md)
 and [design principles](https://github.com/flutter/engine/blob/master/sky/specs/design.md)
 before working on anything non-trivial. These guidelines are intended to keep
 the code consistent and avoid common pitfalls.
 * `git commit -a -m "<your informative commit message>"`
 * `git push origin name_of_your_branch`

To send us a pull request:

* `git pull-request` (if you are using [Hub](http://github.com/github/hub/)) or
  go to `https://github.com/flutter/flutter` and click the
  "Compare & pull request" button

Please make sure all your checkins have detailed commit messages explaining the patch.
If you made multiple commits for a single pull request, either make sure each one has a detailed
message explaining that specific commit, or squash your commits into one single checkin with a
detailed message before sending the pull request.

You must complete the
[Contributor License Agreement](https://cla.developers.google.com/clas).
You can do this online, and it only takes a minute.
If you've never submitted code before, you must add your (or your
organization's) name and contact info to the [AUTHORS](AUTHORS) file.

Working on the engine and the framework at the same time
--------------------------------------------------------

You can work both with this repository (flutter.git) and the Flutter
[engine repository](https://github.com/flutter/engine) at the same time using
the following steps.

1. Follow the instructions above for creating a working copy of this repository.

2. Follow the [contributing instructions](https://github.com/flutter/engine/blob/master/CONTRIBUTING.md)
   for the engine repository to create a working copy of the engine. When you
   create the `.gclient` file for the engine, be sure to create it in a
   directory named `engine` that is a sibling of the directory in which you
   cloned this repository. For example, if you cloned this repository into the
   `/foo/bar/flutter` directory, you should create the `.gclient` file in the
   `/foo/bar/engine` directory. The actual code from the engine repository will
   end up in `/foo/bar/engine/src` because `gclient` creates a `src` directory
   underneath the directory that contains the `.gclient` file.

3. To run tests on your host machine, build one of the host configurations
   (e.g., `out/Debug`). To run examples on Android, build one of the Android
   configurations (e.g., `out/android_Debug`).

You should now be able to run the tests against your locally built
engine using the `flutter test --debug` command. To run one of the
examples on your device using your locally built engine, use the
`--debug` option to the `flutter` tool:

 * `flutter start --debug`

If you want to test the release version instead of the debug version,
use `--release` instead of `--debug`.

Making a breaking change to the engine
--------------------------------------

If you make a breaking change to the engine, you'll need to land you change in a
few steps:

1. Land your change in the engine repository.

2. Publish a new version of the engine that contains your change. See the
   engine's [release process](https://github.com/flutter/engine/wiki/Release-process)
   for instructions about how to publish a new version of the engine. Publishing
   a new version is important in order to not break folks using prebuilt
   binaries in their workflow (e.g., our customers).

3. Land a change that update our dependency on the `sky_engine` and
   `sky_services` packages to point to the new version of the engine that you
   just published. These dependencies are defined by [packages/flutter/pubspec.yaml](packages/flutter/pubspec.yaml).
   After changing the `pubspec.yaml` file, you'll need to run
   `./dev/update_packages.dart` to update all the packages in this repository to
   see the new dependency. As part of landing this change, you should make
   whatever other changes are needed in this repository to account for your
   breaking change.
