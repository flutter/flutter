// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SharedDeferredPrefixTest);
  });
}

@reflectiveTest
class SharedDeferredPrefixTest extends PubPackageResolutionTest {
  test_hasSharedDeferredPrefix() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
f1() {}
''');
    newFile('$testPackageLibPath/lib2.dart', '''
library lib2;
f2() {}
''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as lib;
import 'lib2.dart' as lib;
main() { lib.f1(); lib.f2(); }
''', [
      error(CompileTimeErrorCode.SHARED_DEFERRED_PREFIX, 33, 8),
    ]);
  }
}
