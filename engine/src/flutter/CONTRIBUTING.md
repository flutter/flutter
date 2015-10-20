Contributing to Sky
===================

[![Build Status](https://travis-ci.org/flutter/engine.svg)](https://travis-ci.org/flutter/engine)

Things you will need
--------------------

 * git (used for source version control).
 * An IDE. We recommend [Atom](https://github.com/flutter/engine/wiki/Using-Atom-with-Flutter).
 * An ssh client (used to authenticate with GitHub).
 * Chromium's [depot_tools](http://www.chromium.org/developers/how-tos/install-depot-tools) (make sure it's in your path). We use the 'gclient' tool from depot_tools.
 * Python (used by many of our tools, including 'gclient').
 * curl (used by `gclient sync`).

You do not need [Dart](https://www.dartlang.org/downloads/linux.html) installed, as a Dart tool chain is automatically downloaded as part of the "getting the code" step. Similarly for the Android SDK, it's downloaded by the build step below where you run `download_android_tools.py`.

Getting the code
----------------

To get the code:

 * Fork `https://github.com/flutter/engine` into your own GitHub account. If you already have a fork, and are now installing a development environment on a new machine, make sure you've updated your fork so that you don't use stale configuration options from long ago.
 * If you haven't configured your machine with an SSH key that's shared by github then
   follow the directions here: https://help.github.com/articles/generating-ssh-keys/.
 * Create an empty directory for your copy of the repository. Call it what you like. For
   the sake of the instructions that follow, we'll call it `flutter`.
 * Create a `.gclient` in the `flutter` directory with the following contents, replacing
   `<your_name_here`> with your GitHub account name:

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
 * `cd flutter` (Change to the directory in which you put the `.gclient` file)
 * `gclient sync` This will fetch all the source code that Flutter depends on. Avoid interrupting this script, it can leave your repository in an inconsistent state that is tedious to clean up.
 * `cd src` (Change to the directory that `gclient sync` created in your `flutter` directory)
 * `git remote add upstream git@github.com:flutter/engine.git` (So that you fetch from the master repository, not your clone, when running `git fetch` et al)
 * Add `.../flutter/src/third_party/dart-sdk/dart-sdk/bin/` to your path so that you can run the `pub` tool more easily.

Building the code
-----------------

Currently we support building on Linux only, for an Android target and for a headless Linux
target. Building on MacOS for Android, iOS, and a head-less MacOS target is coming soon.

### Android (cross-compiling from Mac or Linux)

#### The first time

From the 'src' directory that the `gclient sync` step created earlier:

* Run `./tools/android/download_android_tools.py`
* On Linux: Run `sudo ./build/install-build-deps-android.sh`
* On Mac: Install Oracle's Java JDK, version 1.7 or later.
* On Mac: Install "ant": `brew install ant`.

#### Building

Run the following steps, again from the aforementioned 'src' directory:
* `./sky/tools/gn --android`
* `ninja -C out/android_Debug`
* `./sky/tools/shelldb start out/android_Debug/ examples/hello_world/lib/main.dart`

### Desktop (Mac and Linux)

* (Linux, only the first time) `sudo ./build/install-build-deps.sh`
* `./sky/tools/gn`
* `ninja -C out/Debug`

Running the tests
-----------------

* `./sky/tools/run_tests --debug` runs the tests on the host machine using `out/Debug`.
* If you want to run the run a test directly:
  - (Linux) `./out/Debug/sky_shell --package-root=sky/unit/packages sky/unit/test/harness/trivial_test.dart`
  - (Mac) `./sky/tools/run_tests --debug test/harness/trivial_test.dart`

Note: The tests are headless, you won't see any UI. You can use `print` to generate console output or you can interact with the DartVM via observatory at [http://localhost:8181/](http://localhost:8181/).

Adding a test
-------------

To add a test, simply create a file whose name ends with `_test.dart` in the `sky/unit/test` directory.
The test should have a `main` function and use `package:test`.

Running the examples
--------------------

* Before running the examples, you'll need to set up your path to include the Dart SDK directory, like so (starting in the src directory of your code tree):
 - ``$ export PATH=$PATH:`pwd`/third_party/dart-sdk/dart-sdk/bin``
* You can find example code in subdirectories of the `examples` directory, for example `examples/stocks`.
* Once you have a local build, run `pub get` from the example folder of your choice to make sure that you have all of the Dart dependencies.
* Then, to run the current example locally, you can run:
 - `$ ./packages/sky/sky_tool --local-build start`
* The `--local-build` parameter attempts to determine the location of your local build directory. You can override it by specifying the `--sky-src-path` and `--android-debug-build-path` parameters. These parameters should not normally be needed, though. Run `$ ./packages/sky/sky_tool -h` to see details about the parameters.
* You can also specify a particular Dart file to run if you want to run an example that doesn't have a `lib/main.dart` file.  For example, to run the `tabs.dart` example in the `examples/widgets` directory on a connected Android device, from that directory you would run:
 - `$ ./packages/sky/sky_tool --local-build start tabs.dart`
* When running code from the `examples` directory, any changes you make to the example code, as well as any changes to Dart code in the `sky` directory and subdirectories will automatically be picked when you relaunch the app.  You can do the same for your own code by mimicking the `pubspec.yaml` files in the `examples` subdirectories.
* You can also use `$ ./packages/sky/sky_tool --local-build listen` in the various example directories (or your own Sky apps) to listen for changes you are making to the app and automatically update the running SkyShell instance on your Android device.  iOS device and simulator support are coming soon.
* You can replace `--local-build` in any of the above commands with `--release` if you have made release builds and want to test with them.  E.g., `$ ./packages/sky/sky_tool --release start` will attempt to use your release build of the Android SkyShell.apk.
* If you just need to install SkyShell on a device, you can run `$ ./packages/sky/sky_tool --local-build install`.

Contributing code
-----------------

The Sky engine repository gladly accepts contributions via GitHub pull requests.

To start working on a patch:

 * `git fetch upstream`
 * `git checkout upstream/master -b name_of_your_branch`
 * Hack away
 * `git commit -a -m "<your brief but informative commit message>"`
 * `git push origin name_of_your_branch`

To send us a pull request:

 * `git pull-request` (if you are using [Hub](http://github.com/github/hub/)) or go to `https://github.com/<your_name_here>/sky_engine` and click the
   "Compare & pull request" button

Please peruse our [style guides](sky/specs/style-guide.md) and
[design principles](sky/specs/design.md) before working on anything
non-trivial. These guidelines are intended to keep the code consistent
and avoid common pitfalls.

Please make sure all your checkins have detailed commit messages explaining the patch.
If you made multiple commits for a single pull request, either make sure each one has a detailed
message explaining that specific commit, or squash your commits into one single checkin with a
detailed message before sending the pull request.

You must complete the
[Contributor License Agreement](https://cla.developers.google.com/clas).
You can do this online, and it only takes a minute.
If you've never submitted code before, you must add your (or your
organization's) name and contact info to the [AUTHORS](AUTHORS) file.
