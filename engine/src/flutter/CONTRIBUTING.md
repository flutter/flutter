Contributing to the Flutter engine
==================================

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
 * Create an empty directory for your copy of the repository. For best results, call it `engine`: some of the tools assume this name when working across repositories. (They can be configured to use other names too, so this isn't a strict requirement.)
 * Create a `.gclient` file in the `engine` directory with the following contents, replacing
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

 * `cd engine` (Change to the directory in which you put the `.gclient` file.)
 * `gclient sync` This will fetch all the source code that Flutter depends on. Avoid interrupting this script, it can leave your repository in an inconsistent state that is tedious to clean up.
 * `cd src` (Change to the directory that `gclient sync` created in your `engine` directory.)
 * `git remote add upstream git@github.com:flutter/engine.git` (So that you fetch from the master repository, not your clone, when running `git fetch` et al.)
 * Run `./tools/android/download_android_tools.py` to add Android dependencies to your tree. You will need to run this command again if you ever run `git clean -xdf`, since that deletes these dependencies. (`git clean -df` is fine since it skips these `.gitignore`d files.)
 * Add `.../engine/src/third_party/dart-sdk/dart-sdk/bin/` to your path so that you can run the `pub` tool more easily.
 * Add `.../engine/src/third_party/android_tools/sdk/platform-tools` to your path so that you can run the `adb` tool more easily. This is also required by the `flutter` tool, which is used to run Flutter apps.
 * Make sure you are still in the `src` directory that the `gclient sync` step created earlier.
 * If you're on Linux, run `sudo ./build/install-build-deps-android.sh`
 * If you're on Linux, run `sudo ./build/install-build-deps.sh`
 * If you're on Mac, install Oracle's Java JDK, version 1.7 or later.
 * If you're on Mac, install `ant`: `brew install ant`

Building and running the code
-----------------------------

### Android (cross-compiling from Mac or Linux)

Run the following steps, from the `src` directory created in the steps above:

 * `gclient sync` to update your dependencies.
 * `./sky/tools/gn --android` to prepare your build files.
 * `ninja -C out/android_Debug` to build an Android Debug binary.

To run an example with your locally built binary, you'll also need to clone
[the main Flutter repository](https://github.com/flutter/flutter). See
[the instructions for contributing](https://github.com/flutter/flutter/blob/master/CONTRIBUTING.md)
to the main Flutter repository for detailed instructions.

Once you've got everything set up, you can run an example using your locally
built engine by switching to that example's directory, running `pub get` to make
sure its dependencies have been downloaded, and using `flutter run` with an
explicit `--engine-src-path` pointing at the `src` directory. Make sure you have
a device connected over USB and debugging enabled on that device:

 * `cd /path/to/flutter/examples/hello_world`
 * `pub get`
 * `../../bin/flutter run --engine-src-path /path/to/engine/src`

You can also specify a particular Dart file to run if you want to run an example
that doesn't have a `lib/main.dart` file using the `-t` command-line option. For
example, to run the `tabs.dart` example in the `examples/widgets` directory on a
connected Android device, from that directory you would run:

 * `flutter run --engine-src-path /path/to/engine/src -t tabs.dart`

If you're going to be debugging crashes in the engine, make sure you add
`android:debuggable="true"` to the `<application>` element in the
`android/AndroidManifest.xml` file for the Flutter app you are using
to test the engine.

### iOS

See [this wiki page](https://github.com/flutter/engine/wiki/Flutter-Apps-on-iOS).

### Desktop (Mac and Linux), for tests

 * `gclient sync` to update your dependencies.
 * `./sky/tools/gn` to prepare your build files.
 * `ninja -C out/Debug` to build a desktop Debug binary.

To run the tests, you'll also need to clone [the main Flutter repository](https://github.com/flutter/flutter).
See [the instructions for contributing](https://github.com/flutter/flutter/blob/master/CONTRIBUTING.md)
to the main Flutter repository for detailed instructions.

Contributing code
-----------------

We gladly accept contributions via GitHub pull requests.

To start working on a patch:

 * `git fetch upstream`
 * `git checkout upstream/master -b name_of_your_branch`
 * Hack away. Please peruse our
   [style guides](https://flutter.io/style-guide/) and
   [design principles](https://flutter.io/design-principles/) before
   working on anything non-trivial. These guidelines are intended to
   keep the code consistent and avoid common pitfalls.
 * `git commit -a -m "<your brief but informative commit message>"`
 * `git push origin name_of_your_branch`

To send us a pull request:

 * `git pull-request` (if you are using [Hub](http://github.com/github/hub/)) or
   go to `https://github.com/flutter/engine` and click the
   "Compare & pull request" button

Once you've gotten an LGTM from a project maintainer, submit your changes to the
`master` branch using one of the following methods:

* Wait for one of the project maintainers to submit it for you
* Click the green "Merge pull request" button on the GitHub UI of your pull
  request (requires commit access)
* `git push upstream name_of_your_branch:master` (requires commit access)

Then, make sure it doesn't make our tree catch fire by watching [the waterfall](https://build.chromium.org/p/client.flutter/waterfall). The waterfall runs
slightly different tests than Travis, so it's possible for the tree to go red even if
Travis did not. If that happens, please immediately revert your change. Do not check
anything in while the tree is red unless you are trying to resolve the problem.

Please make sure all your checkins have detailed commit messages explaining the patch.
If you made multiple commits for a single pull request, either make sure each one has a detailed
message explaining that specific commit, or squash your commits into one single checkin with a
detailed message before sending the pull request.

You must complete the
[Contributor License Agreement](https://cla.developers.google.com/clas).
You can do this online, and it only takes a minute.
If you've never submitted code before, you must add your (or your
organization's) name and contact info to the [AUTHORS](AUTHORS) file.
