# The Engine Tool

This is a command line Dart program that automates workflows in the
`flutter/engine` repository.

### Prerequisites

The tool requires an initial `gclient sync -D` as described in the [repo setup
steps](https://github.com/flutter/flutter/wiki/Setting-up-the-Engine-development-environment#getting-the-source)
before it will work.

## Status

The tool has the following commands.

* `help` - Prints helpful information about commands and usage.
* `build` - Builds the Flutter engine.
* `fetch` - Downloads Flutter engine dependencies.
* `format` - Formats files in the engine tree using various off-the-shelf
formatters.
* `run` - Runs a flutter application with a local build of the engine.
* `query builds` - Lists the CI builds described under `ci/builders` that the
host platform is capable of executing.

### Missing features

There are currently many missing features. Some overall goals are listed in the
GitHub issue [here](https://github.com/flutter/flutter/issues/132807). Some
desirable new features would do the following:

* Add a `doctor` command.
* Update the engine checkout so that engine developers no longer have to remember
to run `gclient sync -D`.
* Build and test the engine using CI configurations locally, with the
possibility to override or add new build options and targets.
* Build engines using options coming only from the command line.
* List tests and run them locally, automatically building their dependencies
first. Automatically start emulators or simulators if they're needed to run a
test.
* Spawn individual builders remotely using `led` from `depot_tools`.
* Encapsulate all code formatters, checkers, linters, etc. for all languages.
* Find a compatible version of the flutter/flutter repo, check it out, and spawn
tests from that repo with a locally built engine to run on an emulator,
simulator or device.
* Use a real logging package for prettier terminal output.
* Wire the tool up to a package providing autocomplete like
[cli_completion](https://pub.dev/packages/cli_completion.).

The way the current tooling in the engine repo works may need to be rewritten,
especially tests spawned by `run_tests.py`, in order to provide this interface.

## Contributing

* Follow the [Flutter style guide](https://github.com/flutter/flutter/wiki/Style-guide-for-Flutter-repo)
for Dart code that are relevant outside of the framework repo. It contains
conventions that go beyond code formatting, which
we'll follow even if using `dart format` in the future.
* Do not call directly into `dart:io` except from `main.dart`. Instead access
the system only through the `Enviroment` object.
* All commands must have unit tests. If some functionality needs a fake
implementation, then write a fake implementation.
* When adding or changing functionality, update this README.md file.
* *Begin with the end in mind* - Start working from what the interface provided
by this tool *should* be, then modify underlying scripts and tools to provide
APIs to support that.

Run tests using `//flutter/testing/run_tests.py`:

```shell
testing/run_tests.py --type dart-host --dart-host-filter flutter/tools/engine_tool
```
