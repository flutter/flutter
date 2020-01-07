// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import '../flutter_test_alternative.dart';

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
  StackFrame(number: 0,  className: '_AssertionError',                method: '_doThrowNew',    packageScheme: 'dart',    package: 'core-patch',    packagePath: 'errors_patch.dart',          line: 42,   column: 39),
  StackFrame(number: 1,  className: '_AssertionError',                method: '_throwNew',      packageScheme: 'dart',    package: 'core-patch',    packagePath: 'errors_patch.dart',          line: 38,   column: 5),
  StackFrame(number: 2,  className: 'Text',                           method: StackFrame.ctor,  packageScheme: 'package', package: 'flutter',       packagePath: 'src/widgets/text.dart',      line: 287,  column: 10),
  StackFrame(number: 3,  className: '_MyHomePageState',               method: 'build',          packageScheme: 'package', package: 'hello_flutter', packagePath: 'main.dart',                  line: 72,   column: 16),
  StackFrame(number: 4,  className: 'StatefulElement',                method: 'build',          packageScheme: 'package', package: 'flutter',       packagePath: 'src/widgets/framework.dart', line: 4414, column: 27),
  StackFrame(number: 5,  className: 'ComponentElement',               method: 'performRebuild', packageScheme: 'package', package: 'flutter',       packagePath: 'src/widgets/framework.dart', line: 4303, column: 15),
  StackFrame(number: 6,  className: 'Element',                        method: 'rebuild',        packageScheme: 'package', package: 'flutter',       packagePath: 'src/widgets/framework.dart', line: 4027, column: 5),
  StackFrame(number: 7,  className: 'ComponentElement',               method: '_firstBuild',    packageScheme: 'package', package: 'flutter',       packagePath: 'src/widgets/framework.dart', line: 4286, column: 5),
  StackFrame(number: 8,  className: 'StatefulElement',                method: '_firstBuild',    packageScheme: 'package', package: 'flutter',       packagePath: 'src/widgets/framework.dart', line: 4461, column: 11),
  StackFrame(number: 9,  className: 'ComponentElement',               method: 'mount',          packageScheme: 'package', package: 'flutter',       packagePath: 'src/widgets/framework.dart', line: 4281, column: 5),
  StackFrame(number: 10, className: 'Element',                        method: 'inflateWidget',  packageScheme: 'package', package: 'flutter',       packagePath: 'src/widgets/framework.dart', line: 3276, column: 14),
  StackFrame(number: 11, className: 'Element',                        method: 'updateChild',    packageScheme: 'package', package: 'flutter',       packagePath: 'src/widgets/framework.dart', line: 3070, column: 12),
  StackFrame(number: 12, className: 'SingleChildRenderObjectElement', method: 'mount',          packageScheme: 'package', package: 'flutter',       packagePath: 'blah.dart',                  line: 999,  column: 9),
  StackFrame(number: 13, className: '',                               method: 'main',           packageScheme: 'package', package: 'hello_flutter', packagePath: 'main.dart',                  line: 10,   column: 4),
];

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
}
