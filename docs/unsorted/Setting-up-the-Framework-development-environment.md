## Preqrequisites

 * Linux, Mac OS X, or Windows

 * `git` (used for source version control)

 * An IDE, such as [Android Studio with the Flutter plugin](https://docs.flutter.dev/development/tools/android-studio) or [VS Code](https://docs.flutter.dev/development/tools/vs-code)

 * Android platform tools
   - Mac: `brew install --cask android-platform-tools`
   - Linux: `sudo apt-get install android-tools-adb`

   Verify that `adb` is in your [PATH](https://en.wikipedia.org/wiki/PATH_(variable)) (that `which adb` prints sensible output).

   If you're
   [also working on the Flutter engine](https://github.com/flutter/flutter/wiki/Setting-up-the-Engine-development-environment),
   you can use the copy of the Android platform tools in
   `.../engine/src/third_party/android_tools/sdk/platform-tools`.

 * Python (used by some of our tools)

## Set up your environment

1. [Fork the flutter/flutter repo](https://github.com/flutter/flutter/fork) into your own GitHub account. If
   you already have a fork, and are now installing a development environment on
   a new machine, make sure you've updated your fork so that you don't use stale
   configuration options.

1. Clone the forked repo locally using the method of your choice. GitHub Desktop is simplest. SSH [reportedly](https://github.com/flutter/flutter/issues/148000) has issues if you're not part of the [Flutter org](https://github.com/orgs/flutter/people).

   <img width="391" alt="GitHub cloning options" src="https://user-images.githubusercontent.com/6655696/189104233-7db05feb-1543-4f8b-8a2b-cc34cd18c6b8.png">

   If you cloned the repo using HTTPS or SSH, you'll need to configure the upstream remote for `flutter/flutter`. This will allow you to sync changes made in `flutter/flutter` with the fork:

   1. `cd flutter`

   1. Specify a new remote upstream repository (`flutter/flutter`) that will be synced with the fork.
      - HTTPS: `git remote add upstream https://github.com/flutter/flutter.git`
      - SSH: `git remote add upstream git@github.com:flutter/flutter.git`
   1. Verify the new upstream repository you've specified for your fork.

      - `git remote -v`

1. Add the repo's `bin` directory to your [PATH](https://en.wikipedia.org/wiki/PATH_(variable)): e.g. on UNIX, using `export PATH="$PATH:$HOME/<path to flutter repository>/bin"`

    - If you already have a Flutter installation you will either need to remove it from your PATH, or use a full path whenever you are running `flutter` in this repository. If you have version solving errors when trying to run examples below, you are running a version of Flutter other than the one checked out here.

1. `flutter update-packages`

   This will recursively fetch all the Dart packages that
   Flutter depends on. If version solving failed, try `git fetch upstream` to update Flutter versions before `flutter update-packages`.


> **Tip**
> If you plan on using IntelliJ as your IDE, then also run
> `flutter ide-config --overwrite` to create all of the IntelliJ configuration
> files so you can open the main flutter directory as a project and run examples
> from within the IDE.


Next steps:

 * [[Running examples]], to see if your setup works.
 * [[The flutter tool]], to learn about how the `flutter` command line tool works.
 * [[Style guide for Flutter repo]], to learn how to write code for Flutter.
 * [[Tree hygiene]], to learn about how to submit patches.
 * [[Signing commits]], to configure your environment to securely sign your commits.