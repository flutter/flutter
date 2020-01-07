# Flutter Tools

Command line developer tools for building Flutter applications.

## Working on Flutter Tools

Be sure to follow the instructions on [CONTRIBUTING.md](../../CONTRIBUTING.md)
to set up your development environment.

### Setup

First, ensure that the Dart SDK and other necessary artifacts are available by
invoking the Flutter Tools wrapper script. In this directory run:
```shell
$ ../../bin/flutter --version
```

### Running

To run Flutter Tools from source, in this directory run:
```shell
$ ../../bin/cache/dart-sdk/bin/dart bin/flutter_tools.dart
```
followed by command line arguments, as usual.


### Analyzing

To run the analyzer on Flutter Tools, in this directory run:
```shell
$ ../../bin/flutter analyze
```

### Testing

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

When running all of the tests, it is a bit faster to use `build_runner`. First,
set `FLUTTER_ROOT` to the root of your Flutter checkout. Then, in this directory
run:
```shell
$ ../../bin/cache/dart-sdk/bin/pub run build_runner test
```
This is what we do in the continuous integration bots.


### Forcing snapshot regeneration

To force the Flutter Tools snapshot to be regenerated, delete the following
files:
```shell
$ rm ../../bin/cache/flutter_tools.stamp ../../bin/cache/flutter_tools.snapshot
```
