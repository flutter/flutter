# Flutter Tools

This section of the Flutter repository contains the command line developer tools
for building Flutter applications.

## Working on Flutter Tools

Be sure to follow the instructions on [CONTRIBUTING.md](../../CONTRIBUTING.md)
to set up your development environment. Further, familiarize yourself with the
[style guide](https://github.com/flutter/flutter/wiki/Style-guide-for-Flutter-repo),
which we follow.

### Setting up

First, ensure that the Dart SDK and other necessary artifacts are available by
invoking the Flutter Tools wrapper script. In this directory run:
```shell
$ ../../bin/flutter --version
```

### Running the Tool

To run Flutter Tools from source, in this directory run:
```shell
$ ../../bin/cache/dart-sdk/bin/dart bin/flutter_tools.dart
```
followed by command-line arguments, as usual.


### Running the analyzer

To run the analyzer on Flutter Tools, in this directory run:
```shell
$ ../../bin/flutter analyze
```

### Writing tests

As with other parts of the Flutter repository, all changes in behavior [must be
tested](https://github.com/flutter/flutter/wiki/Style-guide-for-Flutter-repo#write-test-find-bug).
Tests live under the `test/` subdirectory.
- Hermetic unit tests of tool internals go under `test/general.shard`.
- Tests of tool commands go under `test/commands.shard`. Hermetic tests go under
  its `hermetic/` subdirectory. Non-hermetic tests go under its `permeable`
  sub-directory.
- Integration tests (e.g. tests that run the tool in a subprocess) go under
  `test/integration.shard`.

In general, the tests for the code in a file called `file.dart` should go in a
file called `file_test.dart` in the subdirectory that matches the behavior of
the test.

We measure [test coverage](https://codecov.io/gh/flutter/flutter) post-submit.
A change that deletes code might decrease test coverage, however, most changes
that add new code should aim to increase coverage. In particular, the coverage
of the diff should be close to the average coverage, and should ideally be
better.

### Running the tests

To run the tests in the `test/` directory, first ensure that there are no
connected devices. Then, in this directory run:
```shell
$ ../../bin/cache/dart-sdk/bin/pub run test
```

The tests in `test/integration.shard` are slower to run than the tests in
`test/general.shard`. To run only the tests in `test/general.shard`, in this
directory run:
```shell
$ ../../bin/cache/dart-sdk/bin/pub run test test/general.shard
```

To run the tests in a specific file, run:
```shell
$ ../../bin/cache/dart-sdk/bin/pub run test test/general.shard/utils_test.dart
```

### Forcing snapshot regeneration

To force the Flutter Tools snapshot to be regenerated, delete the following
files:
```shell
$ rm ../../bin/cache/flutter_tools.stamp ../../bin/cache/flutter_tools.snapshot
```
