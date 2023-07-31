// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/ast/element_locator.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:analyzer/src/utilities/extensions/ast.dart';
import 'package:analyzer/src/utilities/extensions/library_element.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LocateElementTest);
  });
}

@reflectiveTest
class LocateElementTest extends PubPackageResolutionTest {
  Future<void> assertLocation(String content) async {
    final code = TestCode.parse(content);
    await resolveTestCode(code.code);

    // Get the element we'll be searching for from the marker in code.
    final node = result.unit.nodeCovering(offset: code.position.offset);
    final expectedElement = ElementLocator.locate(node)!;

    // Verify locating the element using its location finds the same element.
    final actualElement =
        result.libraryElement.locateElement(expectedElement.location!);
    expect(actualElement, expectedElement);
  }

  void test_class() async {
    await assertLocation('''
class C^ {}
''');
  }

  void test_class_const() async {
    await assertLocation('''
class C {
  static const ^c = '';
}
''');
  }

  void test_class_constructor() async {
    await assertLocation('''
class C {
  C.named() {}
  ^C() {}
}
''');
  }

  void test_class_constructor_named() async {
    await assertLocation('''
class C {
  C.named() {}
}

class C2 {
  C.nam^ed() {}
}
''');
  }

  void test_class_field() async {
    await assertLocation('''
class C {
  int f = 0;
}
class C2 {
  int f^ = 0;
}
''');
  }

  void test_class_getter() async {
    await assertLocation('''
class C {
  String get s => '';
}
class C2 {
  String get s^ => '';
}
''');
  }

  void test_class_setter() async {
    await assertLocation('''
class C {
  set s(String a) {}
}
class C2 {
  set ^s(String a) {}
}
''');
  }

  void test_const() async {
    await assertLocation('''
const ^c = '';
''');
  }

  void test_enum() async {
    await assertLocation('''
enum ^E {}
''');
  }

  void test_enum_const2() async {
    await assertLocation('''
enum E {
  o^ne(1);
  final int n;
  const E(this.n);
}
''');
  }

  void test_enum_constructor() async {
    await assertLocation('''
enum E {
  final int n;
  const ^E(this.n);
}
''');
  }

  void test_extension() async {
    await assertLocation('''
extension on int {}
exten^sion on String {}
extension on int {}
''');
  }

  void test_extension_named() async {
    await assertLocation('''
extension StringEx^tension on String {}
''');
  }

  void test_getter() async {
    await assertLocation('''
String get ^g => '';
''');
  }

  void test_method() async {
    await assertLocation('''
class C {
  void m() {}
}
class C2 {
  void ^m() {}
}
''');
  }

  void test_mixin() async {
    await assertLocation('''
mixin ^M {}
''');
  }

  void test_setter() async {
    await assertLocation('''
set f^(String v) {}
''');
  }

  void test_topLevelVariable() async {
    await assertLocation('''
int ^a = 1;
''');
  }

  void test_typedef() async {
    await assertLocation('''
typedef ^S = String;
''');
  }
}
