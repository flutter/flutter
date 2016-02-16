// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import "dart:async";
import "dart:io";

import "../base/globals.dart";
import "../runner/flutter_command.dart";
import '../ios/setup_xcodeproj.dart';

class IOSCommand extends FlutterCommand {
  final String name = "ios";
  final String description = "Commands for creating and updating Flutter iOS projects.";

  IOSCommand() {
    argParser.addFlag('init', help: 'Initialize the Xcode project for building the iOS application');
  }

  @override
  Future<int> runInProject() async {
    if (!Platform.isMacOS) {
      printStatus("iOS specific commands may only be run on a Mac.");
      return 1;
    }

    if (argResults['init'])
      return await setupXcodeProjectHarness();

    printError("No flags specified.");
    return 1;
  }
}
