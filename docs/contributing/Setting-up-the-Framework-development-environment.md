## Prerequisites

 * Linux, macOS, or Windows

 * `git` (used for source version control)

 * An IDE, such as [Android Studio with the Flutter plugin](https://docs.flutter.dev/development/tools/android-studio) or [VS Code](https://docs.flutter.dev/development/tools/vs-code)

 * Android platform tools
   - Mac: `brew install --cask android-platform-tools`
   - Linux: `sudo apt-get install android-tools-adb`

   Verify that `adb` is in your [PATH](https://en.wikipedia.org/wiki/PATH_(variable)) (that `which adb` prints sensible output).

   If you're
   [also working on the Flutter engine](../../docs/engine/contributing/Setting-up-the-Engine-development-environment.md),
   you can use the copy of the Android platform tools in
   `.../engine/src/third_party/android_tools/sdk/platform-tools`.

 * Python (used by some of our tools)

## Set up your environment

1. Clone the flutter/flutter repo using either SSH or HTTPS (SSH is recommended, but requires a working [SSH key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/about-ssh) on your GitHub account):
      - SSH: `git clone git@github.com:flutter/flutter.git`
      - HTTPS: `git clone https://github.com/flutter/flutter.git`

1. Change into the directory of the cloned repository and rename the origin remote to upstream:
     1. `cd flutter`
     1. `git remote rename origin upstream`

1. [Fork the flutter/flutter repo](https://github.com/flutter/flutter/fork) into your own GitHub account.

1. Add your fork as the origin remote to your local clone either using SSH or HTTPS (SSH is recommended, but requires a working [SSH key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/about-ssh) on your GitHub account) by replacing ████████ with your GitHub account name:
     - SSH: `git remote add origin git@github.com:████████/flutter.git`
     - HTTPS: `git remote add origin https://github.com/████████/flutter.git`

1. Verify the upstream and origin repository you've specified for your clone.
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

 * [Running examples](../examples/Running-examples.md), to see if your setup works.
 * [The flutter tool](../tool/README.md), to learn about how the `flutter` command line tool works.
 * [Style guide for Flutter repo](Style-guide-for-Flutter-repo.md), to learn how to write code for Flutter.
 * [Tree hygiene](Tree-hygiene.md), to learn about how to submit patches.
 * [Signing commits](Signing-commits.md), to configure your environment to securely sign your commits.
