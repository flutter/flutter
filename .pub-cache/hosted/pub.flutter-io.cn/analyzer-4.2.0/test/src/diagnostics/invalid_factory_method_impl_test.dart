// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidFactoryMethodImplTest);
  });
}

@reflectiveTest
class InvalidFactoryMethodImplTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_abstract() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
abstract class Stateful {
  @factory
  State createState();
}
class State { }
''');
  }

  test_badReturn() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class Stateful {
  State _s = new State();

  @factory
  State createState() => _s;
}
class State { }
''', [
      error(HintCode.INVALID_FACTORY_METHOD_IMPL, 96, 11),
    ]);
  }

  test_block() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
class Stateful {
  @factory
  State createState() {
    return new State();
  }
}
class State { }
''');
  }

  test_block_returnNull() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
class Stateful {
  @factory
  State createState() {
    return State();
  }
}
class State { }
''');
  }

  test_expr() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
class Stateful {
  @factory
  State createState() => new State();
}
class State { }
''');
  }

  test_expr_returnNull() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
class Stateful {
  @factory
  State createState() => State();
}
class State { }
''');
  }

  test_noReturnType() async {
    // Null return types will get flagged elsewhere, no need to pile on here.
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
class Stateful {
  @factory
  createState() {
    return new Stateful();
  }
}
''');
  }

  test_subclass() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
abstract class Stateful {
  @factory
  State createState();
}
class MyThing extends Stateful {
  @override
  State createState() {
    print('my state');
    return new MyState();
  }
}
class State { }
class MyState extends State { }
''');
  }

  test_voidReturn() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class Stateful {
  @factory
  void createState() {}
}
''', [
      error(HintCode.INVALID_FACTORY_METHOD_DECL, 69, 11),
    ]);
  }
}
