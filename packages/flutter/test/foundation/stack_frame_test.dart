// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import '../flutter_test_alternative.dart';

void main() {
  test('Parses line', () {
    expect(
      StackFrame.fromStackTraceLine(stackString.split('\n')[0]),
      stackFrames[0],
    );
  });

  test('Parses string', () {
    expect(
      StackFrame.fromStackString(stackString),
      stackFrames,
    );
  });

  test('Parses StackTrace', () {
    expect(
      StackFrame.fromStackTrace(StackTrace.fromString(stackString)),
      stackFrames,
    );
  });

  test('Parses complex stack', () {
    expect(
      StackFrame.fromStackString(asyncStackString),
      asyncStackFrames,
    );
  });
}

const String stackString = '''#0      _AssertionError._doThrowNew (dart:core-patch/errors_patch.dart:42:39)
#1      _AssertionError._throwNew (dart:core-patch/errors_patch.dart:38:5)
#2      new Text (package:flutter/src/widgets/text.dart:287:10)
#3      _MyHomePageState.build (package:hello_flutter/main.dart:72:16)
#4      StatefulElement.build (package:flutter/src/widgets/framework.dart:4414:27)
#5      ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4303:15)
#6      Element.rebuild (package:flutter/src/widgets/framework.dart:4027:5)
#7      ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:4286:5)
#8      StatefulElement._firstBuild (package:flutter/src/widgets/framework.dart:4461:11)
#9      ComponentElement.mount (package:flutter/src/widgets/framework.dart:4281:5)
#10     Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#11     Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#12     SingleChildRenderObjectElement.mount (package:flutter/blah.dart:999:9)
#13     main (package:hello_flutter/main.dart:10:4)''';

const List<StackFrame> stackFrames = <StackFrame>[
  StackFrame(0,  className: '_AssertionError',                method: '_doThrowNew',    packageScheme: 'dart',    package: 'core-patch',    packagePath: 'errors_patch.dart',          line: 42,   column: 39),
  StackFrame(1,  className: '_AssertionError',                method: '_throwNew',      packageScheme: 'dart',    package: 'core-patch',    packagePath: 'errors_patch.dart',          line: 38,   column: 5),
  StackFrame(2,  className: 'Text',                           method: '',               packageScheme: 'package', package: 'flutter',       packagePath: 'src/widgets/text.dart',      line: 287,  column: 10, isConstructor: true),
  StackFrame(3,  className: '_MyHomePageState',               method: 'build',          packageScheme: 'package', package: 'hello_flutter', packagePath: 'main.dart',                  line: 72,   column: 16),
  StackFrame(4,  className: 'StatefulElement',                method: 'build',          packageScheme: 'package', package: 'flutter',       packagePath: 'src/widgets/framework.dart', line: 4414, column: 27),
  StackFrame(5,  className: 'ComponentElement',               method: 'performRebuild', packageScheme: 'package', package: 'flutter',       packagePath: 'src/widgets/framework.dart', line: 4303, column: 15),
  StackFrame(6,  className: 'Element',                        method: 'rebuild',        packageScheme: 'package', package: 'flutter',       packagePath: 'src/widgets/framework.dart', line: 4027, column: 5),
  StackFrame(7,  className: 'ComponentElement',               method: '_firstBuild',    packageScheme: 'package', package: 'flutter',       packagePath: 'src/widgets/framework.dart', line: 4286, column: 5),
  StackFrame(8,  className: 'StatefulElement',                method: '_firstBuild',    packageScheme: 'package', package: 'flutter',       packagePath: 'src/widgets/framework.dart', line: 4461, column: 11),
  StackFrame(9,  className: 'ComponentElement',               method: 'mount',          packageScheme: 'package', package: 'flutter',       packagePath: 'src/widgets/framework.dart', line: 4281, column: 5),
  StackFrame(10, className: 'Element',                        method: 'inflateWidget',  packageScheme: 'package', package: 'flutter',       packagePath: 'src/widgets/framework.dart', line: 3276, column: 14),
  StackFrame(11, className: 'Element',                        method: 'updateChild',    packageScheme: 'package', package: 'flutter',       packagePath: 'src/widgets/framework.dart', line: 3070, column: 12),
  StackFrame(12, className: 'SingleChildRenderObjectElement', method: 'mount',          packageScheme: 'package', package: 'flutter',       packagePath: 'blah.dart',                  line: 999,  column: 9),
  StackFrame(13, className: '',                               method: 'main',           packageScheme: 'package', package: 'hello_flutter', packagePath: 'main.dart',                  line: 10,   column: 4),
];


const String asyncStackString = '''#0      getSampleStack.<anonymous closure> (file:///path/to/flutter/packages/flutter/test/foundation/error_reporting_test.dart:40:57)
#1      new Future.sync (dart:async/future.dart:224:31)
#2      getSampleStack (file:///path/to/flutter/packages/flutter/test/foundation/error_reporting_test.dart:40:10)
#3      main (file:///path/to/flutter/packages/flutter/test/foundation/error_reporting_test.dart:46:40)
#4      main (package:flutter_goldens/flutter_goldens.dart:43:17)
<asynchronous suspension>
#5      main.<anonymous closure>.<anonymous closure> (file:///temp/path.whatever/listener.dart:47:18)
#6      _rootRun (dart:async/zone.dart:1126:13)
#7      _CustomZone.run (dart:async/zone.dart:1023:19)
#8      _runZoned (dart:async/zone.dart:1518:10)
#9      runZoned (dart:async/zone.dart:1465:12)
#10     Declarer.declare (package:test_api/src/backend/declarer.dart:130:22)
#11     RemoteListener.start.<anonymous closure>.<anonymous closure>.<anonymous closure> (package:test_api/src/remote_listener.dart:124:26)
<asynchronous suspension>
#12     _rootRun (dart:async/zone.dart:1126:13)
#13     _CustomZone.run (dart:async/zone.dart:1023:19)
#14     _runZoned (dart:async/zone.dart:1518:10)
#15     runZoned (dart:async/zone.dart:1502:12)
#16     RemoteListener.start.<anonymous closure>.<anonymous closure> (package:test_api/src/remote_listener.dart:70:9)
#17     _rootRun (dart:async/zone.dart:1126:13)
#18     _CustomZone.run (dart:async/zone.dart:1023:19)
#19     _runZoned (dart:async/zone.dart:1518:10)
#20     runZoned (dart:async/zone.dart:1465:12)
#21     StackTraceFormatter.asCurrent (package:test_api/src/backend/stack_trace_formatter.dart:41:31)
#22     RemoteListener.start.<anonymous closure> (package:test_api/src/remote_listener.dart:69:29)
#23     _rootRun (dart:async/zone.dart:1126:13)
#24     _CustomZone.run (dart:async/zone.dart:1023:19)
#25     _runZoned (dart:async/zone.dart:1518:10)
#26     runZoned (dart:async/zone.dart:1465:12)
#27     SuiteChannelManager.asCurrent (package:test_api/src/suite_channel_manager.dart:34:31)
#28     RemoteListener.start (package:test_api/src/remote_listener.dart:68:27)
#29     serializeSuite (file:///temp/path.whatever/listener.dart:17:25)
#30     main (file:///temp/path.whatever/listener.dart:43:36)
#31     _runMainZoned.<anonymous closure>.<anonymous closure> (dart:ui/hooks.dart:239:25)
#32     _rootRun (dart:async/zone.dart:1126:13)
#33     _CustomZone.run (dart:async/zone.dart:1023:19)
#34     _runZoned (dart:async/zone.dart:1518:10)
#35     runZoned (dart:async/zone.dart:1502:12)
#36     _runMainZoned.<anonymous closure> (dart:ui/hooks.dart:231:5)
#37     _startIsolate.<anonymous closure> (dart:isolate-patch/isolate_patch.dart:307:19)
#38     _RawReceivePortImpl._handleMessage (dart:isolate-patch/isolate_patch.dart:174:12)''';

const List<StackFrame> asyncStackFrames = <StackFrame>[
StackFrame(0,  className: '',                    method: 'getSampleStack', packageScheme: 'file',    package: '<unknown>',       packagePath: '/path/to/flutter/packages/flutter/test/foundation/error_reporting_test.dart', line: 40,   column: 57),
StackFrame(1,  className: 'Future',              method: 'sync',           packageScheme: 'dart',    package: 'async',           packagePath: 'future.dart',                                                                 line: 224,  column: 31, isConstructor: true),
StackFrame(2,  className: '',                    method: 'getSampleStack', packageScheme: 'file',    package: '<unknown>',       packagePath: '/path/to/flutter/packages/flutter/test/foundation/error_reporting_test.dart', line: 40,   column: 10),
StackFrame(3,  className: '',                    method: 'main',           packageScheme: 'file',    package: '<unknown>',       packagePath: '/path/to/flutter/packages/flutter/foundation/error_reporting_test.dart',      line: 46,   column: 40),
StackFrame(4,  className: '',                    method: 'main',           packageScheme: 'package', package: 'flutter_goldens', packagePath: 'flutter_goldens.dart',                                                        line: 43,   column: 17),
StackFrame.asynchronousSuspension,
StackFrame(5,  className: '',                    method: 'main',           packageScheme: 'file',    package: '<unknown>',      packagePath: '/temp/path.whatever/listener.dart',                                           line: 47,   column: 18),
StackFrame(6,  className: '',                    method: '_rootRun',       packageScheme: 'dart',    package: 'async',          packagePath: 'zone.dart',                                                                   line: 1126, column: 13),
StackFrame(7,  className: '_CustomZone',         method: 'run',            packageScheme: 'dart',    package: 'async',          packagePath: 'zone.dart',                                                                   line: 1023, column: 19),
StackFrame(8,  className: '',                    method: '_runZoned',      packageScheme: 'dart',    package: 'async',          packagePath: 'zone.dart',                                                                   line: 1518, column: 10),
StackFrame(9,  className: '',                    method: 'runZoned',       packageScheme: 'dart',    package: 'async',          packagePath: 'zone.dart',                                                                   line: 1465, column: 12),
StackFrame(10, className: 'Declarer',            method: 'declare',        packageScheme: 'package', package: 'test_api',       packagePath: 'src/backend/declarer.dart',                                                   line: 130,  column: 22),
StackFrame(11, className: 'RemoteListener',      method: 'start',          packageScheme: 'package', package: 'test_api',       packagePath: 'src/remote_listener.dart',                                                    line: 124,  column: 26),
StackFrame.asynchronousSuspension,
StackFrame(12, className: '',                    method: '_rootRun',       packageScheme: 'dart',    package: 'async',          packagePath: 'zone.dart',                                                                   line: 1126, column: 13),
StackFrame(13, className: '_CustomZone',         method: 'run' ,           packageScheme: 'dart',    package: 'async',          packagePath: 'zone.dart',                                                                   line: 1023, column: 19),
StackFrame(14, className: '',                    method: '_runZoned',      packageScheme: 'dart',    package: 'async',          packagePath: 'zone.dart',                                                                   line: 1518, column: 10),
StackFrame(15, className: '',                    method: 'runZoned',       packageScheme: 'dart',    package: 'async',          packagePath: 'zone.dart',                                                                   line: 1502, column: 12),
StackFrame(16, className: 'RemoteListener',      method: 'start',          packageScheme: 'package', package: 'test_api',       packagePath: 'src/remote_listener.dart',                                                    line: 70,   column: 9),
StackFrame(17, className: '',                    method: '_rootRun',       packageScheme: 'dart',    package: 'async',          packagePath: 'zone.dart',                                                                   line: 1126, column: 13),
StackFrame(18, className: '_CustomZone',         method: 'run',            packageScheme: 'dart',    package: 'async',          packagePath: 'zone.dart',                                                                   line: 1023, column: 19),
StackFrame(19, className: '',                    method: '_runZoned',      packageScheme: 'dart',    package: 'async',          packagePath: 'zone.dart',                                                                   line: 1518, column: 10),
StackFrame(20, className: '',                    method: 'runZoned',       packageScheme: 'dart',    package: 'async',          packagePath: 'zone.dart',                                                                   line: 1465, column: 12),
StackFrame(21, className: 'StackTraceFormatter', method: 'asCurrent',      packageScheme: 'pacakge', package: 'test_api',       packagePath: 'src/backend/stack_trace_formatter.dart',                                      line: 41,   column: 31),
StackFrame(22, className: 'RemoteListener',      method: 'start',          packageScheme: 'package', package: 'test_api',       packagePath: 'src/remote_listener.dart',                                                    line: 69,   column: 29),
StackFrame(23, className: '',                    method: '_rootRun',       packageScheme: 'dart',    package: 'async',          packagePath: 'zone.dart',                                                                   line: 1126, column: 13),
StackFrame(24, className: '_CustomZone',         method: 'run',            packageScheme: 'dart',    package: 'async',          packagePath: 'zone.dart',                                                                   line: 1023, column: 19),
StackFrame(25, className: '',                    method: '_runZoned',      packageScheme: 'dart',    package: 'async',          packagePath: 'zone.dart',                                                                   line: 1518, column: 10),
StackFrame(26, className: '',                    method: 'runZoned',       packageScheme: 'dart',    package: 'async',          packagePath: 'zone.dart',                                                                   line: 1465, column: 12),
StackFrame(27, className: 'SuiteChannelManager', method: 'asCurrent',      packageScheme: 'package', package: 'test_api',       packagePath: 'src/suite_channel_manager.dart',                                              line: 34,   column: 31),
StackFrame(28, className: 'RemoteListener',      method: 'start',          packageScheme: 'package', package: 'test_api',       packagePath: 'src/remote_listener.dart',                                                    line: 68,   column: 27),
StackFrame(29, className: '',                    method: 'serializeSuite', packageScheme: 'file',    package: '<unknown>',      packagePath: '/temp/path.whatever/listener.dart',                                           line: 17,   column: 25),
StackFrame(30, className: '',                    method: 'main',           packageScheme: 'file',    package: '<unknown>',      packagePath: '/temp/path.whatever/listener.dart',                                           line: 43,   column: 36),
StackFrame(31, className: '',                    method: '_runMainZoned',  packageScheme: 'dart',    package: 'ui',             packagePath: 'hooks.dart',                                                                  line:239,   column: 25),
StackFrame(32, className: '',                    method: '_rootRun',       packageScheme: 'dart',    package: 'async',          packagePath: 'zone.dart',                                                                   line: 1126, column: 13),
StackFrame(33, className: '_CustomZone',         method: 'run' ,           packageScheme: 'dart',    package: 'async',          packagePath: 'zone.dart',                                                                   line: 1023, column: 19),
StackFrame(34, className: '',                    method: '_runZoned',      packageScheme: 'dart',    package: 'async',          packagePath: 'zone.dart',                                                                   line: 1518, column: 10),
StackFrame(35, className: '',                    method: 'runZoned',       packageScheme: 'dart',    package: 'async',          packagePath: 'zone.dart',                                                                   line: 1502, column: 12),
StackFrame(36, className: '',                    method: '_runMainZoned',  packageScheme: 'dart',    package: 'ui',             packagePath: 'hooks.dart',                                                                  line: 231,  column: 5),
StackFrame(37, className: '',                    method: '_startIsolate',  packageScheme: 'dart',    package: 'isolate-patch',  packagePath: 'isolate_patch.dart',                                                          line: 307,  column: 19),
StackFrame(38, className: '_RawReceivePortImpl', method: '_handleMessage', packageScheme: 'dart',    package: 'isolate-patch',  packagePath: 'isolate_patch.dart',                                                          line: 174,  column: 12),
];
