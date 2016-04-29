// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'android/android_sdk.dart';
import 'base/context.dart';
import 'base/logger.dart';
import 'cache.dart';
import 'device.dart';
import 'doctor.dart';
import 'toolchain.dart';
import 'usage.dart';

DeviceManager get deviceManager => context[DeviceManager];
Logger get logger => context[Logger];
AndroidSdk get androidSdk => context[AndroidSdk];
Cache get cache => Cache.instance;
Doctor get doctor => context[Doctor];
ToolConfiguration get tools => ToolConfiguration.instance;
Usage get flutterUsage => Usage.instance;

/// Display an error level message to the user. Commands should use this if they
/// fail in some way.
void printError(String message, [StackTrace stackTrace]) => logger.printError(message, stackTrace);

/// Display normal output of the command. This should be used for things like
/// progress messages, success messages, or just normal command output.
void printStatus(String message, { bool emphasis: false }) => logger.printStatus(message, emphasis: emphasis);

/// Use this for verbose tracing output. Users can turn this output on in order
/// to help diagnose issues with the toolchain or with their setup.
void printTrace(String message) => logger.printTrace(message);
