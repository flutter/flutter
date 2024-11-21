## How to view test coverage

When you run `flutter update-packages`, we download the latest coverage data for `package:flutter` to `packages/flutter/coverage/lcov.info`. This data isn't synchronized to your git revision, so expect discrepancies between your git repo and the coverage file. Usually, this version skew isn't too harmful, but it's valuable to be aware that it might exist.

⚠️ Currently, the latest test coverage data is stale by a few years because of [flutter#81803](https://github.com/flutter/flutter/issues/81803). You will need to [recompute this data manually](#how-recompute-test-coverage-slowly) to view test coverage.

### Visual Studio Code

Here is how to show test coverage information in Visual Studio Code:

1. Install the [Coverage Gutters](https://marketplace.visualstudio.com/items?itemName=ryanluker.vscode-coverage-gutters) extension.
2. Open a `dart` file in `packages/flutter/lib/src`. You should see green and red highlights next to line numbers in the gutter. The green lines mean this line was executed in a test. The red line means that this line is a candidate for execution but was not executed in a test. The status bar at the bottom should also report the current file's code coverage percentage.

If you run into issues, check for errors in the `Output` pane under the `coverage-gutters` output stream.

### Atom

Here is how to show test coverage information in Atom:

1. Install the [lcov-info](https://atom.io/packages/lcov-info) package.  This package has a few quirks to its UI, but it generally seems to work.

2. Open `packages/flutter` in Atom.  The lcov-info plugin only seems to work if you open `packages/flutter` directly (as opposed to opening one of its parent directories).

3. Open a `dart` file in the `lib/src` directory.  For some reason, you need to have a Dart file open in order to activate the lcov-info plugin.

4. Activate the lcov-info package using the `Packages > Lcov Info > Toggle` menu command.

5. At this point, you should see green and red highlighted lines in `dart` files (hopefully more green than red) as well as a scrollable list of the coverage percentages for each file in `package:flutter`.  The green lines mean this line was executed in a test.  The red line means that this line is a candidate for execution but was not executed in a test. Lines that are highlighted are not considered candidates for execution. Some of the non-highlighted lines are a bit surprising (e.g., return statements or constant declarations), but they appear to be correct.

### Emacs

If you use Emacs, you can use the `coverlay` package. Use `coverlay-load-file` to specify the `.../packages/flutter/coverage/lcov.info` file, configure `coverlay:base-path` to point to the `.../packages/flutter`, and configure other aspects of the `coverlay` package as you desire.

### Coveralls

The easiest way to see our overall test coverage used to be using the [Flutter page on Coveralls](https://coveralls.io/github/flutter/flutter?branch=master). The graph at the top is supposed to be updated with green commit to the master branch. Unfortunately, Coveralls has been broken for Flutter for a long time and no progress has been made to resolve [the issue](https://github.com/lemurheavy/coveralls-public/issues/1103).

## How to recompute test coverage quickly

If you're using a Linux machine, you can see the updated coverage after adding a test quickly using the `--merge-coverage` option to `flutter test`. For example, suppose you added a test case to `test/material/dialog_test.dart`. You can run `flutter test --merge-coverage test/material/dialog_test.dart` to run just that one test and merge the coverage data into your view. In Atom, to get lcov-info to see the new data, sometimes you need to change tabs. In Emacs, to see new data, press `C-c C-l g`.

Merging coverage works by combining the `packages/flutter/coverage/lcov.base.info` coverage data, which `flutter update-packages` downloaded from the cloud, with the coverage data from that one test run.  The combined data is written back into `packages/flutter/coverage/lcov.info`, where it is picked up by the lcov-info plugin.

Each time you run `--merge-coverage`, the tool goes back to the original `lcov.base.info` data before adding the current run.  If you want to see the change in coverage when changing more than one test file, you'll need to pass all the test file names explicitly on the command line.

## How recompute test coverage slowly

If you want to recompute coverage data from scratch, you can use the `--coverage` flag.  For example, `cd packages/flutter && flutter test --coverage`.

The `lcov.base.info` file is generated automatically by bots and recomputing from scratch is unnecessary. It is fetched when you run `flutter update-packages`.