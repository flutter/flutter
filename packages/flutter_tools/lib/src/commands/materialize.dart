// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:meta/meta.dart';
import '../base/common.dart';
import '../project.dart';
import '../runner/flutter_command.dart';

class MaterializeCommand extends FlutterCommand {
  MaterializeCommand() {
    addSubcommand(new MaterializeAndroidCommand());
    addSubcommand(new MaterializeIosCommand());
  }

  @override
  final String name = 'materialize';

  @override
  final String description = 'Commands for materializing host apps for a Flutter Module';

  @override
  bool get hidden => true;

  @override
  Future<Null> runCommand() async { }
}

abstract class MaterializeSubCommand extends FlutterCommand {
  MaterializeSubCommand() {
    requiresPubspecYaml();
  }

  FlutterProject _project;

  @override
  @mustCallSuper
  Future<Null> runCommand() async {
    await _project.ensureReadyForPlatformSpecificTooling();
  }

  @override
  Future<Null> validateCommand() async {
    await super.validateCommand();
    _project = await FlutterProject.current();
    if (!_project.isModule)
      throw new ToolExit("Only projects created using 'flutter create -t module' can be materialized.");
  }
}

class MaterializeAndroidCommand extends MaterializeSubCommand {
  @override
  String get name => 'android';

  @override
  String get description => 'Materialize an Android host app';

  @override
  Future<Null> runCommand() async {
    await super.runCommand();
    await _project.android.materialize();
  }
}

class MaterializeIosCommand extends MaterializeSubCommand {
  @override
  String get name => 'ios';

  @override
  String get description => 'Materialize an iOS host app';

  @override
  Future<Null> runCommand() async {
    await super.runCommand();
    await _project.ios.materialize();
  }
}
