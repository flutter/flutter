// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:cli_util/cli_logging.dart';

Future<void> main(List<String> args) async {
  var verbose = args.contains('-v');
  var logger = verbose ? Logger.verbose() : Logger.standard();

  logger.stdout('Hello world!');
  logger.trace('message 1');
  await Future.delayed(Duration(milliseconds: 200));
  logger.trace('message 2');
  logger.trace('message 3');

  var progress = logger.progress('doing some work');
  await Future.delayed(Duration(seconds: 2));
  progress.finish(showTiming: true);

  logger.stdout('All ${logger.ansi.emphasized('done')}.');
}
