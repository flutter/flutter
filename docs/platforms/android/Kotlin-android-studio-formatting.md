# Setting up Kotlin formatting in Android Studio

Kotlin code in this repository is formatted and linted with [`ktlint`](https://github.com/pinterest/ktlint).
If you
1. have submitted Kotlin code only to learn this when the analyzer check fails
2. use Android Studio


then there is good news! Android Studio can be configured to use `ktlint` to automatically apply formatting and highlight issues. To do this:


1. Install the `ktlint` extension for Android Studio

   a. On Mac, this is `Android Studio > Settings > Plugins > ` Search for `ktlint`.

2. Set the ruleset to be the same as the version used in [`.ci.yaml`](../../../.ci.yaml) (as of writing this is 1.5), and the baseline to be `dev/bots/test/analyze-test-input/ktlint-baseline.xml`.

   a. Both of these options should be available under `Android Studio > Settings > Tools > ktlint`.

3. Additionally, Kotlin code in the Flutter repository currently uses some additional rules for compatibility with older versions of Kotlin.
These rules can only be configured by an `.editorconfig` file in the directory from which Android Studio was opened. To configure these rules, create a copy of the [`.editorconfig`](../../../dev/bots/test/analyze-test-input/.editorconfig) that is used by tests in the root directory you intend to open with Android Studio.
