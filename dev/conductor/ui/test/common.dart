// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/src/stdio.dart';

export '../../../../packages/flutter_tools/test/src/fake_process_manager.dart';

class TestStdio extends Stdio {
  TestStdio({
    this.verbose = false,
    List<String>? stdin,
  }) : _stdin = stdin ?? <String>[];

  String get error => logs.where((String log) => log.startsWith(r'[error] ')).join('\n');

  String get stdout => logs.where((String log) {
    return log.startsWith(r'[status] ') || log.startsWith(r'[trace] ') || log.startsWith(r'[write] ');
  }).join('\n');

  final bool verbose;
  late final List<String> _stdin;
  List<String> get stdin => _stdin;

  @override
  String readLineSync() {
    if (_stdin.isEmpty) {
      throw Exception('Unexpected call to readLineSync!');
    }
    return _stdin.removeAt(0);
  }
}
