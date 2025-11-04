## Things you will need

 * A working [Flutter](https://docs.flutter.dev/get-started) installation.
 * git (used for source version control).
 * An ssh client (used to authenticate with GitHub).

## Getting the code and configuring your repository

 * Ensure all the dependencies described in the previous section are installed.
 * Fork `https://github.com/flutter/packages` into your own GitHub account. If
   you already have a fork, and are now installing a development environment on
   a new machine, make sure you've updated your fork so that you don't use stale
   configuration options from long ago.
 * If you haven't configured your machine with an SSH key that's known to GitHub, then
   follow [GitHub's directions](https://help.github.com/articles/generating-ssh-keys/)
   to generate an SSH key.
 * `git clone git@github.com:<your_name_here>/packages.git`
 * `cd packages`
 * `git remote add upstream git@github.com:flutter/packages.git` (So that you
   fetch from the master repository, not your clone, when running `git fetch`
   et al.)

## Setting up tools

### Repository tools

There are scripts for many common tasks (testing, formatting, etc.) that will likely be useful in preparing a PR.
See [the tools README](https://github.com/flutter/packages/blob/main/script/tool/README.md) for more details.

You will need to [set up the tools](https://github.com/flutter/packages/blob/main/script/tool/README.md#getting-started)
before using them for the first time.

### Android tooling

The repository is configured to treat warnings as errors in most cases; on Android that includes enforcing many Java and Android lint options. Not all of these are configured to show up by default in Android Studio, so if you are working on Android plugin implementations consider [enabling all of the Android lint options in Android Studio](https://developer.android.com/studio/write/lint#cis) (by checking the box by Android > Lint).

There are warnings that show up in Android Studio that are not enforced in CI, so it's not always necessary to fix every warning. You can check if warnings you see need to be addressed by running the `lint-android` repository tool command. (In general, we encourage fixing warnings that show up in Android Studio even when they are not enforced; the IDE has an extra linting options that unfortunately aren't accessible via CI. If you aren't sure if a specific unenforced warning needs to be addressed, please ask your reviewer.)
