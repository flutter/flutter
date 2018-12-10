# Flutter's Build Infrastructure

This directory exists to support building Flutter on our build infrastructure.

The results of such builds are viewable at:
* https://cirrus-ci.com/github/flutter/flutter/master
  - Testing done on PRs and submitted changes on GitHub.
* https://build.chromium.org/p/client.flutter/console
  - Additional testing and processing done after changes are submitted.

The Chromium infra bots do not allow forcing new builds from outside
the Google network. Contact @eseidelGoogle or another Google member of
the Flutter team if you need to do that.

The [Cirrus](https://cirrus-ci.org)-based bots run the
[`test.dart`](test.dart) script for each PR and submission. This does
testing for the tools, for the framework, and (for submitted changes
only) rebuilds and updates the master branch API docs
[staging site](https://master-docs-flutter-io.firebaseapp.com).
For tagged dev and beta builds, it also builds and deploys the gallery
app to the app stores. It is configured by the
[.cirrus.yml](/.cirrus.yml).

We also have post-commit testing with actual devices, in what we call
our [devicelab](../dev/devicelab/README.md).

## Chromium infra bots

This part of our infrastructure is broken into two parts. A buildbot
master specified by our
[builders.pyl](https://chromium.googlesource.com/chromium/tools/build.git/+/master/masters/master.client.flutter/builders.pyl)
file, and a [set of
recipes](https://chromium.googlesource.com/chromium/tools/build.git/+/master/scripts/slave/recipes/flutter)
which we run on that master. Both of these technologies are highly
specific to Google's Chromium project. We're just borrowing some of
their infrastructure.

### Prerequisites

To work on this infrastructure you will need:

- [depot_tools](http://www.chromium.org/developers/how-tos/install-depot-tools)
- Python package installer: `sudo apt-get install python-pip`
- Python coverage package (only needed for `training_simulation`): `sudo pip install coverage`

### Getting the code

The following will get way more than just recipe code, but it _will_ get the recipe code:

```bash
mkdir chrome_infra
cd chrome_infra
fetch infra
```

More detailed instructions can be found [here](https://chromium.googlesource.com/infra/infra/+/master/doc/source.md).

Most of the functionality for recipes comes from `recipe_modules`, which are
unfortunately spread to many separate repositories.  After checking out the code
search for files named `api.py` or `example.py` under `infra/build`.

### Editing a recipe

Flutter has one recipe per repository. Currently
[flutter/flutter](https://chromium.googlesource.com/chromium/tools/build.git/+/master/scripts/slave/recipes/flutter/flutter.py)
and
[flutter/engine](https://chromium.googlesource.com/chromium/tools/build.git/+/master/scripts/slave/recipes/flutter/engine.py):

- build/scripts/slave/recipes/flutter/flutter.py
- build/scripts/slave/recipes/flutter/engine.py

Recipes are just Python.  They are
[documented](https://github.com/luci/recipes-py/blob/master/doc/user_guide.md)
by the [luci/recipes-py github project](https://github.com/luci/recipes-py).

The typical cycle for editing a recipe is:

1. Make your edits (probably to files in
   `//chrome_infra/build/scripts/slave/recipes/flutter`).
2. Update the tests. Run `build/scripts/slave/recipes.py --use-bootstrap test
   train` to update existing expected output to match the new output. Verify
   completely new test cases by altering the `GenTests` method of the recipe.
   The recipe is required to have 100% test coverage.
3. Run `build/scripts/slave/recipes.py run flutter/<repo> slavename=<slavename>
   mastername=client.flutter buildername=<buildername> buildnumber=1234` where `<repo>` is one
   of `flutter` or `engine`, and `slavename` and `buildername` can be looked up
   from the *Build Properties* section of a [recent
   build](https://build.chromium.org/p/client.flutter/one_line_per_build).
4. Upload the patch (`git commit`, `git cl upload`) and send it to someone in
   the `recipes/flutter/OWNERS` file for review.

### Editing the client.flutter buildbot master

Flutter uses Chromium's fancy
[builders.pyl](https://chromium.googlesource.com/infra/infra/+/master/doc/users/services/buildbot/builders.pyl.md)
master generation system.  Chromium hosts 100s (if not 1000s) of buildbot
masters and thus has lots of infrastructure for turning them up and down.
Eventually all of buildbot is planned to be replaced by other infrastructure,
but for now flutter has its own client.flutter master.

You would need to edit client.flutter's master in order to add slaves (talk to
@eseidelGoogle), add builder groups, or to change the html layout of
https://build.chromium.org/p/client.flutter.  Carefully follow the [builders.pyl
docs](https://chromium.googlesource.com/infra/infra/+/master/doc/users/services/buildbot/builders.pyl.md)
to do so.

### Future Directions

We would like to host our own recipes instead of storing them in
[build](https://chromium.googlesource.com/chromium/tools/build.git/+/master/scripts/slave/recipes/flutter).
Support for [cross-repository
recipes](https://github.com/luci/recipes-py/blob/master/doc/cross_repo.md) is
in-progress.  If you view the git log of this directory, you'll see we initially
tried, but it's not quite ready.


### Android Tools

The Android SDK and NDK used by Flutter's Chrome infra bots are stored in Google Cloud. During the build a bot runs the
`download_android_tools.py` script that downloads the required version of the Android SDK into `dev/bots/android_tools`.

To check which components are currently installed, download the current SDK stored in Google Cloud using the
`download_android_tools.py` script, then `dev/bots/android_tools/sdk/tools/bin/sdkmanager --list`. If you find that some
components need to be updated or installed, follow the steps below:

#### How to update Android SDK on Google Cloud Storage

1. Run Android SDK Manager and update packages
   `$ dev/bots/android_tools/sdk/tools/android update sdk`
   Use `android.bat` on Windows.

2. Use the UI to choose the packages you want to install and/or update.

3. Run `dev/bots/android_tools/sdk/tools/bin/sdkmanager --update`. On Windows, run `sdkmanager.bat` instead. If the
   process fails with an error saying that it is unable to move files (Windows makes files and directories read-only
   when another process is holding them open), make a copy of the `dev/bots/android_tools/sdk/tools` directory, run
   the `sdkmanager.bat` from the copy, and use the `--sdk_root` option pointing at `dev/bots/android_tools/sdk`.

4. Run `dev/bots/android_tools/sdk/tools/bin/sdkmanager --licenses` and accept the licenses for the newly installed
   components. It also helps to run this command a second time and make sure that it prints "All SDK package licenses
   accepted".

5. Run upload_android_tools.py -t sdk
   `$ dev/bots/upload_android_tools.py -t sdk`

#### How to update Android NDK on Google Cloud Storage

1. Download a new NDK binary (e.g. android-ndk-r10e-linux-x86_64.bin)
2. cd dev/bots/android_tools
   `$ cd dev/bots/android_tools`

3. Remove the old ndk directory
   `$ rm -rf ndk`

4. Run the new NDK binary file
   `$ ./android-ndk-r10e-linux-x86_64.bin`

5. Rename the extracted directory to ndk
   `$ mv android-ndk-r10e ndk`

6. Run upload_android_tools.py -t ndk
   `$ cd ../..`
   `$ dev/bots/upload_android_tools.py -t ndk`


## Flutter codelabs build test

The Flutter codelabs exercise Material Components in the form of a
demo application. The code for the codelabs is similar to, but
distinct from, the code for the Shrine demo app in Flutter Gallery.

The Flutter codelabs build test ensures that the final version of the
[Material Components for Flutter
Codelabs](https://github.com/material-components/material-components-flutter-codelabs)
can be built. This test serves as a smoke test for the Flutter
framework and should not fail. If it does, please address any issues
in your PR and rerun the test. If you feel that the test failing is
not a direct result of changes made in your PR or that breaking this
test is absolutely necessary, escalate this issue by [submitting an
issue](https://github.com/material-components/material-components-flutter-codelabs/issues/new?title=%5BURGENT%5D%20Flutter%20Framework%20breaking%20PR)
to the MDC-Flutter Team.
