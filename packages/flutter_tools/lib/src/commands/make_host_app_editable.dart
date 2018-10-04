// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:meta/meta.dart';
import '../base/common.dart';
import '../project.dart';
import '../runner/flutter_command.dart';

class MakeHostAppEditableCommand extends FlutterCommand {
  MakeHostAppEditableCommand() {
    addSubcommand(MakeHostAppEditableAndroidCommand());
    addSubcommand(MakeHostAppEditableIosCommand());
  }

  @override
  final String name = 'make-host-app-editable';

  @override
  final String description = 'Commands for making host apps editable within a Flutter project';

  @override
  bool get hidden => true;

  @override
  Future<FlutterCommandResult> runCommand() async => null;
}

abstract class MakeHostAppEditableSubCommand extends FlutterCommand {
  MakeHostAppEditableSubCommand() {
    requiresPubspecYaml();
  }

  FlutterProject _project;

  @override
  @mustCallSuper
  Future<FlutterCommandResult> runCommand() async {
    await _project.ensureReadyForPlatformSpecificTooling();
    return null;
  }

  @override
  Future<void> validateCommand() async {
    await super.validateCommand();
    _project = await FlutterProject.current();
    if (!_project.isApplication)
      throw ToolExit("Only projects created using 'flutter create -t application' can have their host apps made editable.");
  }
}

class MakeHostAppEditableAndroidCommand extends MakeHostAppEditableSubCommand {
  @override
  String get name => 'android';

  @override
  String get description => 'Make an Android host app editable within a Flutter project';

  @override
  Future<FlutterCommandResult> runCommand() async {
    await super.runCommand();
    await _project.android.makeHostAppEditable();

    return null;
  }
}

class MakeHostAppEditableIosCommand extends MakeHostAppEditableSubCommand {
  @override
  String get name => 'ios';

  @override
  String get description => 'Make an iOS host app editable within a Flutter project';

  @override
  Future<FlutterCommandResult> runCommand() async {
    await super.runCommand();
    await _project.ios.makeHostAppEditable();

    return null;
  }
}
