// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_package/has_part.dart' as test_pkg;
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const String file = 'package:test_package/has_part.dart';
// print() within fooz()
const int LINE_A = 15;
// print() within barz()
const int LINE_B = 11;

testMain() {
  test_pkg.fooz();
}

var tests = <IsolateTest>[
  hasPausedAtStart,
  (VmService service, IsolateRef isolateRef) async {
    // Mark 'package:observatory_test_package/has_part.dart' as not debuggable.
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);

    LibraryRef has_part_ref = isolate.libraries!.firstWhere(
      (LibraryRef library) => library.uri == file,
    );

    Library has_part =
        await service.getObject(isolateId, has_part_ref.id!) as Library;
    expect(has_part.debuggable, true);
    // SetBreakpoint before setting library to non-debuggable.
    // Breakpoints are allowed to be set (before marking library as
    // non-debuggable) but are not hit when running (after marking library
    // as non-debuggable).
    ScriptRef script = has_part.scripts!.firstWhere(
      (ScriptRef script) => script.uri == file,
    );
    Breakpoint bpt = await service.addBreakpoint(isolateId, script.id!, LINE_A);
    print("Breakpoint is $bpt");
    expect(bpt, isNotNull);

    // Set breakpoint and check later that this breakpoint won't be added if
    // the library is non-debuggable.
    bpt = await service.addBreakpoint(isolateId, script.id!, LINE_B);
    print("Breakpoint is $bpt");
    expect(bpt, isNotNull);

    // Remove breakpoint.
    final res = await service.removeBreakpoint(isolateId, bpt.id!);
    expect(res.type, 'Success');

    await service.setLibraryDebuggable(isolateId, has_part.id!, false);
    has_part = await service.getObject(isolateId, has_part.id!) as Library;
    expect(has_part.debuggable, false);
    print('$has_part is debuggable: ${has_part.debuggable}');

    // Breakpoints are not allowed to set on non-debuggable libraries.
    try {
      await service.addBreakpoint(isolateId, script.id!, LINE_B);
    } on RPCError catch (e) {
      // Cannot add breakpoint error code
      expect(e.code, 102);
      expect(e.details, contains("Cannot add breakpoint at line '11'"));
      print("Set Breakpoint to non-debuggable library is not allowed");
    }
  },
  resumeIsolate,
  hasStoppedAtExit,
];

main(args) => runIsolateTests(
      args,
      tests,
      'breakpoint_non_debuggable_library_test.dart',
      testeeConcurrent: testMain,
      pause_on_start: true,
      pause_on_exit: true,
    );
