// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/ffi_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AbiSpecificIntegerMappingTest);
  });
}

@reflectiveTest
class AbiSpecificIntegerMappingTest extends PubPackageResolutionTest {
  test_doubleMapping() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@AbiSpecificIntegerMapping({})
@AbiSpecificIntegerMapping({})
class UintPtr extends AbiSpecificInteger {
  const UintPtr();
}
''', [
      error(FfiCode.ABI_SPECIFIC_INTEGER_MAPPING_EXTRA, 51, 25),
    ]);
  }

  test_invalidMapping() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@AbiSpecificIntegerMapping({
  Abi.androidArm: Uint32(),
  Abi.androidArm64: IntPtr(),
  Abi.androidIA32: UintPtr(),
})
class UintPtr extends AbiSpecificInteger {
  const UintPtr();
}
''', [
      error(FfiCode.ABI_SPECIFIC_INTEGER_MAPPING_UNSUPPORTED, 96, 8,
          messageContains: ["Invalid mapping to 'IntPtr'"]),
      error(FfiCode.ABI_SPECIFIC_INTEGER_MAPPING_UNSUPPORTED, 125, 9,
          messageContains: ["Invalid mapping to 'UintPtr'"]),
    ]);
  }

  test_invalidMapping_identifier() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
const c = {
  Abi.androidArm: Uint32(),
  Abi.androidArm64: IntPtr(),
  Abi.androidIA32: UintPtr(),
};
@AbiSpecificIntegerMapping(c)
class UintPtr extends AbiSpecificInteger {
  const UintPtr();
}
''', [
      error(FfiCode.ABI_SPECIFIC_INTEGER_MAPPING_UNSUPPORTED, 149, 1,
          messageContains: ["Invalid mapping to 'IntPtr'"]),
      error(FfiCode.ABI_SPECIFIC_INTEGER_MAPPING_UNSUPPORTED, 149, 1,
          messageContains: ["Invalid mapping to 'UintPtr'"]),
    ]);
  }

  test_noMapping() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class UintPtr extends AbiSpecificInteger {
  const UintPtr();
}
''', [
      error(FfiCode.ABI_SPECIFIC_INTEGER_MAPPING_MISSING, 25, 7),
    ]);
  }

  test_singleMapping() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';
@AbiSpecificIntegerMapping({})
class UintPtr extends AbiSpecificInteger {
  const UintPtr();
}
''');
  }

  test_validMapping() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';
@AbiSpecificIntegerMapping({
  Abi.androidArm: Uint32(),
  Abi.androidArm64: Uint64(),
  Abi.androidIA32: Uint32(),
})
class UintPtr extends AbiSpecificInteger {
  const UintPtr();
}
''');
  }
}
