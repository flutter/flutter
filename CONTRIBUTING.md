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
 * Create a `.gclient` file in an empty directory with the following contents:

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

 * If you're on a Mac then: `svn ls https://dart.googlecode.com/` and accept the certificate permanently.
 * `gclient sync`
 * `cd src`
 * `git remote add upstream git@github.com:domokit/sky_engine.git`

Building the code
-----------------

Currently we support building for an Android target and for a headless Linux
target.

### Android

* (Only the first time) `sudo ./build/install-build-deps-android.sh`
* (Only the first time) `./tools/android/download_android_tools.py`
* `./sky/tools/gn --android`
* `ninja -C out/android_Debug`
* `./sky/tools/shelldb start out/android_Debug/ sky/sdk/example/hello_world/lib/main.dart`

### Linux

* (Only the first time) `sudo ./build/install-build-deps.sh`
* `./sky/tools/gn`
* `ninja -C out/Debug`
* `./out/Debug/sky_shell --package-root=out/Debug/gen/dart-pkg/packages sky/sdk/example/hello_world/lib/main.dart`
  Note: Because Linux is headless, you won't see any UI. You can use `print` to generate console output or you can interact with the DartVM via observatory at [http://localhost:8181/](http://localhost:8181/).

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

You must complete the
[Contributor License Agreement](https://cla.developers.google.com/clas).
You can do this online, and it only takes a minute.
If you've never submitted code before, you must add your (or your
organization's) name and contact info to the [AUTHORS](AUTHORS) file.

Running tests
-------------

Tests are only supported on Linux currently.

 * ``sky/tools/test_sky --debug``
   * This runs the tests against ``//out/Debug``. If you want to run against
     ``//out/Release``, omit the ``--debug`` flag.
