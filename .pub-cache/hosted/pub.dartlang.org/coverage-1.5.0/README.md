Coverage provides coverage data collection, manipulation, and formatting for
Dart.

[![Build Status](https://github.com/dart-lang/coverage/workflows/Dart%20CI/badge.svg)](https://github.com/dart-lang/coverage/actions?query=workflow%3A"Dart+CI"+branch%3Amaster)
[![Coverage Status](https://coveralls.io/repos/dart-lang/coverage/badge.svg?branch=master)](https://coveralls.io/r/dart-lang/coverage)
[![Pub](https://img.shields.io/pub/v/coverage.svg)](https://pub.dev/packages/coverage)


Tools
-----
`collect_coverage` collects coverage JSON from the Dart VM Service.
`format_coverage` formats JSON coverage data into either
[LCOV](http://ltp.sourceforge.net/coverage/lcov.php) or pretty-printed format.

#### Install coverage

    dart pub global activate coverage

Consider adding the `dart pub global run` executables directory to your path.
See [Running a script from your PATH](https://dart.dev/tools/pub/cmd/pub-global#running-a-script-from-your-path)
for more details.


#### Running tests with coverage

For the common use case where you just want to run all your tests, and generate
an lcov.info file, you can use the test_with_coverage script:

```
dart pub global run coverage:test_with_coverage
```

By default, this script assumes it's being run from the root directory of a
package, and outputs a coverage.json and lcov.info file to ./coverage/

This script is essentially the same as running:

```
dart run --pause-isolates-on-exit --disable-service-auth-codes --enable-vm-service=8181 test &
dart pub global run coverage:collect_coverage --wait-paused --uri=http://127.0.0.1:8181/ -o coverage/coverage.json --resume-isolates --scope-output=foo
dart pub global run coverage:format_coverage --packages=.dart_tool/package_config.json --lcov -i coverage/coverage.json -o coverage/lcov.info
```

For more complicated use cases, where you want to control each of these stages,
see the sections below.

#### Collecting coverage from the VM

```
dart --pause-isolates-on-exit --disable-service-auth-codes --enable-vm-service=NNNN script.dart
dart pub global run coverage:collect_coverage --uri=http://... -o coverage.json --resume-isolates
```

or if the `dart pub global run` executables are on your PATH,

```
collect_coverage --uri=http://... -o coverage.json --resume-isolates
```

where `--uri` specifies the Dart VM Service URI emitted by the VM.

If `collect_coverage` is invoked before the script from which coverage is to be
collected, it will wait until it detects a VM observatory to which it can
connect. An optional `--connect-timeout` may be specified (in seconds).  The
`--wait-paused` flag may be enabled, causing `collect_coverage` to wait until
all isolates are paused before collecting coverage.

#### Formatting coverage data

```
dart pub global run coverage:format_coverage --package=app_package -i coverage.json
```

or if the `dart pub global run` exectuables are on your PATH,

```
format_coverage --package=app_package -i coverage.json
```

where `app_package` is the path to the package whose coverage is being
collected (defaults to the current working directory). If `--sdk-root` is set,
Dart SDK coverage will also be output.

#### Ignore lines from coverage

- `// coverage:ignore-line` to ignore one line.
- `// coverage:ignore-start` and `// coverage:ignore-end` to ignore range of lines inclusive.
- `// coverage:ignore-file` to ignore the whole file.

#### Function and branch coverage

To gather function level coverage information, pass `--function-coverage` to
collect_coverage:

```
dart --pause-isolates-on-exit --disable-service-auth-codes --enable-vm-service=NNNN script.dart
dart pub global run coverage:collect_coverage --uri=http://... -o coverage.json --resume-isolates --function-coverage
```

To gather branch level coverage information, pass `--branch-coverage` to *both*
collect_coverage and the Dart command you're gathering coverage from:

```
dart --pause-isolates-on-exit --disable-service-auth-codes --enable-vm-service=NNNN --branch-coverage script.dart
dart pub global run coverage:collect_coverage --uri=http://... -o coverage.json --resume-isolates --branch-coverage
```

Branch coverage requires Dart VM 2.17.0, with service API v3.56. Function,
branch, and line coverage can all be gathered at the same time, by combining
those flags:

```
dart --pause-isolates-on-exit --disable-service-auth-codes --enable-vm-service=NNNN --branch-coverage script.dart
dart pub global run coverage:collect_coverage --uri=http://... -o coverage.json --resume-isolates --function-coverage --branch-coverage
```

These flags can also be passed to test_with_coverage:

```
pub global run coverage:test_with_coverage --branch-coverage --function-coverage
```
