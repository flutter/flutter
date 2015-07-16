Contributing to Sky Engine
==========================

Getting the code
----------------

To get the code:

 * Fork https://github.com/domokit/sky_engine into your own GitHub account.
 * [Download depot_tools](http://www.chromium.org/developers/how-tos/install-depot-tools)
   and make sure it is in your path.
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

 * `svn ls https://dart.googlecode.com/` and accept the certificate permanently.
 * `gclient sync`
 * `cd src`
 * `git remote add upstream git@github.com:domokit/sky_engine.git`

Building the code
-----------------

Currently we support building for an Android target and for a headless Linux
target.

### Android

* (Only the first time) `./build/install-build-deps-android.sh`
* `./sky/tools/gn --android`
* `ninja -C out/android_Debug`

### Linux

* (Only the first time) `./build/install-build-deps.sh`
* `./sky/tools/gn`
* `ninja -C out/Debug`

Contributing code
-----------------

The Sky engine repository gladly accepts contributions via GitHub pull requests:

 * `git fetch upstream`
 * `git checkout upstream/master -b name_of_your_branch`
 * Hack away
 * `git commit -a`
 * `git push origin name_of_your_branch`
 * Go to `https://github.com/<your_name_here>/sky_engine` and click the
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
