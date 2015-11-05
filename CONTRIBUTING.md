Contributing to Flutter
=======================

[![Build Status](https://travis-ci.org/flutter/engine.svg)](https://travis-ci.org/flutter/engine)

Things you will need
--------------------

 * Linux or Mac OS X. (Windows is not yet supported.)
 * git (used for source version control).
 * An IDE. We recommend [Atom](https://github.com/flutter/engine/wiki/Using-Atom-with-Flutter).
 * An ssh client (used to authenticate with GitHub).
 * Chromium's [depot_tools](http://www.chromium.org/developers/how-tos/install-depot-tools) (make sure it's in your path). We use the `gclient` tool from depot_tools.
 * Python (used by many of our tools, including 'gclient').
 * curl (used by `gclient sync`).

You do not need [Dart](https://www.dartlang.org/downloads/linux.html) installed, as a Dart tool chain is automatically downloaded as part of the "getting the code" step. Similarly for the Android SDK, it's downloaded by the build step below where you run `download_android_tools.py`.

Getting the code and configuring your environment
-------------------------------------------------

 * Ensure all the dependencies described in the previous section, in particular git, ssh, depot_tools, python, and curl, are installed.
 * Fork `https://github.com/flutter/engine` into your own GitHub account. If you already have a fork, and are now installing a development environment on a new machine, make sure you've updated your fork so that you don't use stale configuration options from long ago.
 * If you haven't configured your machine with an SSH key that's known to github then
   follow the directions here: https://help.github.com/articles/generating-ssh-keys/.
 * Create an empty directory for your copy of the repository. Call it what you like. For
   the sake of the instructions that follow, we'll call it `flutter`.
 * Create a `.gclient` file in the `flutter` directory with the following contents, replacing
   `<your_name_here>` with your GitHub account name:

```
solutions = [
  {
    "managed": False,
    "name": "src",
    "url": "git@github.com:<your_name_here>/engine.git",
    "custom_deps": {},
    "deps_file": "DEPS",
    "safesync_url": "",
  },
]
target_os = ["android"]
```
 * `cd flutter` (Change to the directory in which you put the `.gclient` file.)
 * `gclient sync` This will fetch all the source code that Flutter depends on. Avoid interrupting this script, it can leave your repository in an inconsistent state that is tedious to clean up.
 * `cd src` (Change to the directory that `gclient sync` created in your `flutter` directory.)
 * `git remote add upstream git@github.com:flutter/engine.git` (So that you fetch from the master repository, not your clone, when running `git fetch` et al.)
 * Run `./tools/android/download_android_tools.py` .
 * Add `.../flutter/src/third_party/dart-sdk/dart-sdk/bin/` to your path so that you can run the `pub` tool more easily.
 * Add `.../flutter/src/third_party/android_tools/sdk/platform-tools` to your path so that you can run the `adb` tool more easily. This is also required by the `flutter` tool, which is used to run Flutter apps.
 * Add `$HOME/.pub-cache/bin` to your path if it's not already there. (It will already be there if you've ever set up Dart's `pub` tool before.)
 * Make sure you are still in the 'src' directory that the `gclient sync` step created earlier.
 * If you're on Linux, run `sudo ./build/install-build-deps-android.sh` .
 * If you're on Linux, run `sudo ./build/install-build-deps.sh` .
 * If you're on Mac, install Oracle's Java JDK, version 1.7 or later.
 * If you're on Mac, install "ant": `brew install ant` .
 * Run `pub global activate flutter` . This installs the 'flutter' tool.


Building and running the code
-----------------------------

### Android (cross-compiling from Mac or Linux)

Run the following steps, from the 'src' directory created in the steps above:

 * `gclient sync` to update your dependencies.
 * `./sky/tools/gn --android` to prepare your build files.
 * `ninja -C out/android_Debug` to build an Android Debug binary.

To run an example with your locally built minary, switch to that example's directory, run `pub get` to make sure its dependencies have been downloaded, and use `flutter start` with an explicit `--engine-src-path` pointing at the `src` directory. Make sure you have a device connected over USB and debugging enabled on that device.

 * `cd examples/hello_world/; flutter start --engine-src-path ../../`

You can also specify a particular Dart file to run if you want to run an example that doesn't have a `lib/main.dart` file using the `-t` command-line option. For example, to run the `tabs.dart` example in the `examples/widgets` directory on a connected Android device, from that directory you would run:

 * `flutter start --engine-src-path ../../ -t tabs.dart`

When running code from the `src/examples` directory, any changes you make to the example code, as well as any changes to Dart code in the `src/sky/packages/sky` directory and subdirectories, will automatically be picked when you relaunch the app.  You can do the same for your own code by mimicking the `pubspec.yaml` files in the `examples` subdirectories.

You can also use `flutter listen` in the various example directories (or your own Flutter apps) to listen for changes you are making to the app and automatically update the running SkyShell instance on your Android device.  iOS device and simulator support for this are coming soon.

The `flutter` tool also lets you run release builds, upload the binary without running it, and various other things. Run `flutter -h` for further information.


### Desktop (Mac and Linux), for tests

 * `gclient sync` to update your dependencies.
 * `./sky/tools/gn` to prepare your build files.
 * `ninja -C out/Debug` to build a desktop Debug binary.

To run the tests:

 * `./sky/tools/run_tests --debug` runs the tests on the host machine using `out/Debug`.

If you want to run the run a test directly:
 * `./sky/tools/run_tests --debug test/harness/trivial_test.dart`

Note: The tests are headless, you won't see any UI. You can use `print` to generate console output or you can interact with the DartVM via observatory at [http://localhost:8181/](http://localhost:8181/).

Contributing code
-----------------

The Flutter engine repository gladly accepts contributions via GitHub pull requests.

To start working on a patch:

 * `git fetch upstream`
 * `git checkout upstream/master -b name_of_your_branch`
 * Hack away. Please peruse our [style guides](sky/specs/style-guide.md) and [design
   principles](sky/specs/design.md) before working on anything non-trivial. These
   guidelines are intended to keep the code consistent and avoid common pitfalls.
 * `git commit -a -m "<your brief but informative commit message>"`
 * `git push origin name_of_your_branch`

To send us a pull request:

 * `git pull-request` (if you are using [Hub](http://github.com/github/hub/)) or go to `https://github.com/<your_name_here>/sky_engine` and click the
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

Adding a test
-------------

To add a test, simply create a file whose name ends with `_test.dart` in the `sky/unit/test` directory.
The test should have a `main` function and use `package:test`.
