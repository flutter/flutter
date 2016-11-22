// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'base/config.dart';
import 'base/context.dart';
import 'base/logger.dart';
import 'cache.dart';
import 'toolchain.dart';

Logger get logger => context[Logger];
Cache get cache => Cache.instance;
Config get config => Config.instance;
ToolConfiguration get tools => ToolConfiguration.instance;

/// Display an error level message to the user. Commands should use this if they
/// fail in some way.
void printError(String message, [StackTrace stackTrace]) => logger.printError(message, stackTrace);

/// Display normal output of the command. This should be used for things like
/// progress messages, success messages, or just normal command output.
///
/// Set `emphasis` to true to make the output bold if it's supported.
///
/// Set `newline` to false to skip the trailing linefeed.
///
/// If `ansiAlternative` is provided, and the terminal supports color, that
/// string will be printed instead of the message.
void printStatus(String message, { bool emphasis: false, bool newline: true, String ansiAlternative }) {
  logger.printStatus(message, emphasis: emphasis, newline: newline, ansiAlternative: ansiAlternative);
}

/// Use this for verbose tracing output. Users can turn this output on in order
/// to help diagnose issues with the toolchain or with their setup.
void printTrace(String message) => logger.printTrace(message);
