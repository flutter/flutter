// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor/proto/conductor_state.pb.dart' as pb;
import 'package:conductor/state.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';

import './common.dart';

void main() {
  test('writeStateToFile', () {
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();
    final File stateFile = fileSystem.file('/path/to/statefile.json');
    final pb.ConductorState state = pb.ConductorState();
    writeStateToFile(
        stateFile,
        state,
        <String>[],
    );
  });
}
