// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';

import '../base/common.dart';
import '../runner/flutter_command.dart';

class FormatCommand extends FlutterCommand {
  FormatCommand();

  @override
  ArgParser argParser = ArgParser.allowAnything();

  @override
  final String name = 'format';

  @override
  List<String> get aliases => const <String>['dartfmt'];

  @override
  String get description => deprecationWarning;

  @override
  final bool hidden = true;

  @override
  String get deprecationWarning {
    return 'The "format" command is deprecated. Please use the "dart format" '
           'sub-command instead, which has the same command-line usage as '
           '"flutter format".\n';
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    throwToolExit(deprecationWarning);
  }
}
