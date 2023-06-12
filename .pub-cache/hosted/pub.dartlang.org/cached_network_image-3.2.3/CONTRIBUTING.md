Contributing to CachedNetworkImage
=============================================

What you will need
------------------

 * A Linux, Mac OS X, or Windows machine (note: to run and compile iOS specific parts you'll need access to a Mac OS X machine);
 * git (used for source version control, installation instruction can be found [here](https://git-scm.com/));
 * The Flutter SDK (installation instructions can be found [here](https://flutter.io/get-started/install/));
 * A personal GitHub account (if you don't have one, you can sign-up for free [here](https://github.com/))

Setting up your development environment
---------------------------------------

 * Fork `https://github.com/baseflow/flutter_cached_network_image` into your own GitHub account. If you already have a fork and moving to a new computer, make sure you update you fork.
 * If you haven't configured your machine with an SSH key that's known to github, then
   follow [GitHub's directions](https://help.github.com/articles/generating-ssh-keys/)
   to generate an SSH key.
 * Clone your forked repo on your local development machine: `git clone git@github.com:<your_name_here>/flutter_cached_network_image.git`
 * Change into the `flutter_cached_network_image` directory: `cd flutter_cached_network_image`
 * Add an upstream to the original repo, so that fetch from the master repository and not your clone: `git remote add upstream git@github.com:baseflow/flutter_cached_network_image.git`

Running the example project
---------------------------

 * Change into the example directory: `cd example`
 * Run the App: `flutter run`

Contribute
----------

We really appreciate contributions via GitHub pull requests. To contribute take the following steps:

 * Make sure you are up to date with the latest code on the master: 
   * `git fetch upstream`
   * `git checkout upstream/develop -b <name_of_your_branch>`
 * Apply your changes
 * Verify your changes and fix potential warnings/ errors:
   * Check formatting: `flutter format .`
   * Run static analyses: `flutter analyze`
   * Run unit-tests: `flutter test`
 * Commit your changes: `git commit -am "<your informative commit message>"`
 * Push changes to your fork: `git push origin <name_of_your_branch>`

Send us your pull request:

 * Go to `https://github.com/baseflow/flutter_cached_network_image` and click the "Compare & pull request" button.

 Please make sure you solved all warnings and errors reported by the static code analyses and that you fill in the full pull request template. Failing to do so will result in us asking you to fix it.
