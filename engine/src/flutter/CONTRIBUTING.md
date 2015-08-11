Contributing to Sky
===================

[![Build Status](https://travis-ci.org/domokit/sky_engine.svg)](https://travis-ci.org/domokit/sky_engine)

Getting the code
----------------

To get the code:

 * Fork https://github.com/domokit/sky_engine into your own GitHub account.
 * [Download depot_tools](http://www.chromium.org/developers/how-tos/install-depot-tools)
   and make sure it is in your path.
 * If you haven't configured your machine with an SSH key that's shared by github then
   follow the directions here: https://help.github.com/articles/generating-ssh-keys/.
 * Create a `.gclient` file in an empty directory with the following contents, replacing
   `<your_name_here`> with your GitHub account name:

```
solutions = [
  {
    "managed": False,
    "name": "src",
    "url": "git@github.com:<your_name_here>/sky_engine.git",
    "custom_deps": {},
    "deps_file": "DEPS",
    "safesync_url": "",
  },
]
target_os = ["android"]
```

 * `gclient sync`
 * `cd src`
 * `git remote add upstream git@github.com:domokit/sky_engine.git`

Building the code
-----------------

Currently we support building on Linux only, for an Android target and for a headless Linux
target. Building on MacOS for Android, iOS, and a head-less MacOS target is coming soon.

### Android (cross-compiling from Linux)

* (Only the first time) `./tools/android/download_android_tools.py`
* (Only the first time) `sudo ./build/install-build-deps-android.sh`
* `./sky/tools/gn --android`
* `ninja -C out/android_Debug`
* `./sky/tools/shelldb start out/android_Debug/ examples/hello_world/lib/main.dart`

### Desktop (Mac and Linux)

* (Linux, only the first time) `sudo ./build/install-build-deps.sh`
* `./sky/tools/gn`
* `ninja -C out/Debug`

Running the tests
-----------------

* `./sky/tools/test_sky --debug` runs the tests on the host machine using `out/Debug`.
* If you want to run the run a test directly:
  - (Linux) `./out/Debug/sky_shell --package-root=sky/packages/workbench/packages sky/tests/lowlevel/trivial.dart`
  - (Mac) `./out/Debug/SkyShell.app/Contents/MacOS/SkyShell --package-root=sky/packages/workbench/packages sky/tests/lowlevel/trivial.dart`

Note: The tests are headless, you won't see any UI. You can use `print` to generate console output or you can interact with the DartVM via observatory at [http://localhost:8181/](http://localhost:8181/).

Running the examples
--------------------

* You can find example code in subdirectories of the `examples` directory, for example `examples/stocks`.
* Once you have a local build, run `pub get` from the example folder of your choice to make sure that you have all of the Dart dependencies.
* Then, to run the current example locally, you can run:
 - `$ ./packages/sky/sky_tool start --build-path ../../out/Debug/`
* The `--build-path` parameter is the path to your build directory for the build you want to run.  To run on a connected Android device, you could set it to `../../out/android_Debug/`, assuming your output directory is set up normally.
* You can also specify a particular Dart file to run if you want to run an example that doesn't have a `lib/main.dart` file.  For example, to run the `tabs.dart` example in the `examples/widgets` directory on a connected Android device, from that directory you would run:
 - `$ ./packages/sky/sky_tool start tabs.dart --build-path ../../out/android_Debug/`
* When running code from the `examples` directory, any changes you make to the example code, as well as any changes to Dart code in the `sky` directory and subdirectories will automatically be picked when you relaunch the app.  You can do the same for your own code by mimicking the `pubspec.yaml` files in the `examples` subdirectories.

Contributing code
-----------------

The Sky engine repository gladly accepts contributions via GitHub pull requests:

 * `git fetch upstream`
 * `git checkout upstream/master -b name_of_your_branch`
 * Hack away
 * `git commit -a`
 * `git push origin name_of_your_branch`
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
