// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:meta/meta.dart';
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
  Future<Null> runCommand() async { }
}

abstract class MaterializeSubCommand extends FlutterCommand {
  MaterializeSubCommand() {
    requiresPubspecYaml();
  }

  @override
  @mustCallSuper
  Future<Null> runCommand() async {
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
    final FlutterProject project = await FlutterProject.current();
    await project.ensureReadyForPlatformSpecificTooling();
    await project.android.materialize();
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
    final FlutterProject project = await FlutterProject.current();
    await project.ensureReadyForPlatformSpecificTooling();
    await project.ios.materialize();
  }
}
