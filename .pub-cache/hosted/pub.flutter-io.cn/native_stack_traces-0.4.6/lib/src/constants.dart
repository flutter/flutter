// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The section name in which the build ID is stored as a note.
const String buildIdSectionName = '.note.gnu.build-id';
// The type of a build ID note.
const int buildIdNoteType = 3;
// The name of a build ID note.
const String buildIdNoteName = 'GNU';

// The dynamic symbol name for the VM instructions section.
const String vmSymbolName = '_kDartVmSnapshotInstructions';

// The dynamic symbol name for the VM data section.
const String vmDataSymbolName = '_kDartVmSnapshotData';

// The dynamic symbol name for the isolate instructions section.
const String isolateSymbolName = '_kDartIsolateSnapshotInstructions';

// The dynamic symbol name for the isolate data section.
const String isolateDataSymbolName = '_kDartIsolateSnapshotData';
