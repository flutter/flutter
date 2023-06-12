A package to help in building Dart command-line apps.

In particular, `cli_util` provides a simple, standardized way to get the current
SDK directory.  Useful, especially, when building client applications that
interact with the Dart SDK (such as the [analyzer][analyzer]).

[![Build Status](https://github.com/dart-lang/cli_util/workflows/Dart/badge.svg)](https://github.com/dart-lang/cli_util/actions)
[![Pub](https://img.shields.io/pub/v/cli_util.svg)](https://pub.dev/packages/cli_util)

## Locating the Dart SDK

```dart
import 'dart:io';

import 'package:cli_util/cli_util.dart';
import 'package:path/path.dart' as path;

main(args) {
  // Get sdk dir from cli_util.
  String sdkPath = getSdkPath();
  
  // Do stuff... For example, print version string
  File versionFile = File(path.join(sdkPath, 'version'));
  print(versionFile.readAsStringSync());
}
```

## Displaying output and progress

`package:cli_util` can also be used to help CLI tools display output and progress.
It has a logging mechanism which can help differentiate between regular tool
output and error messages, and can facilitate having a more verbose (`-v`) mode for
output.

In addition, it can display an indeterminate progress spinner for longer running
tasks, and optionally display the elapsed time when finished: 

```dart
import 'package:cli_util/cli_logging.dart';

void main(List<String> args) async {
  bool verbose = args.contains('-v');
  Logger logger = verbose ? Logger.verbose() : Logger.standard();

  logger.stdout('Hello world!');
  logger.trace('message 1');
  await Future.delayed(Duration(milliseconds: 200));
  logger.trace('message 2');
  logger.trace('message 3');

  Progress progress = logger.progress('doing some work');
  await Future.delayed(Duration(seconds: 2));
  progress.finish(showTiming: true);

  logger.stdout('All ${logger.ansi.emphasized('done')}.');
  logger.flush();
}
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[analyzer]: https://pub.dev/packages/analyzer
[tracker]: https://github.com/dart-lang/cli_util/issues
