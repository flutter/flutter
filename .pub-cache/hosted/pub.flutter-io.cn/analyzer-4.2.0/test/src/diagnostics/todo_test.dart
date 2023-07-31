// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TodoTest);
  });
}

@reflectiveTest
class TodoTest extends PubPackageResolutionTest {
  test_fixme() async {
    await assertErrorsInCode(r'''
main() {
  // FIXME: Implement
}
''', [
      error(TodoCode.FIXME, 14, 16, text: 'FIXME: Implement'),
    ]);
  }

  test_hack() async {
    await assertErrorsInCode(r'''
main() {
  // HACK: This is a hack
}
''', [
      error(TodoCode.HACK, 14, 20, text: 'HACK: This is a hack'),
    ]);
  }

  test_todo_multiLineComment() async {
    await assertErrorsInCode(r'''
main() {
  /* TODO: Implement */
  /* TODO: Implement*/
}
''', [
      error(TodoCode.TODO, 14, 15, text: 'TODO: Implement'),
      error(TodoCode.TODO, 38, 15, text: 'TODO: Implement'),
    ]);
  }

  test_todo_multiLineCommentWrapped() async {
    await assertErrorsInCode(r'''
main() {
  /* TODO(a): Implement something
   *  that is too long for one line
   * This line is not part of the todo
   */
  /* TODO: Implement something
   *  that is too long for one line
   * This line is not part of the todo
   */
  /* TODO(a): Implement something
   *  that is too long for one line
   *
   *  This line is not part of the todo
   */
  /* TODO: Implement something
   *  that is too long for one line
   *
   *  This line is not part of the todo
   */
}
''', [
      error(TodoCode.TODO, 14, 64,
          text: 'TODO(a): Implement something that is too long for one line'),
      error(TodoCode.TODO, 129, 61,
          text: 'TODO: Implement something that is too long for one line'),
      error(TodoCode.TODO, 241, 64,
          text: 'TODO(a): Implement something that is too long for one line'),
      error(TodoCode.TODO, 362, 61,
          text: 'TODO: Implement something that is too long for one line'),
    ]);
  }

  test_todo_singleLineComment() async {
    await assertErrorsInCode(r'''
main() {
  // TODO: Implement
}
''', [
      error(TodoCode.TODO, 14, 15, text: 'TODO: Implement'),
    ]);
  }

  test_todo_singleLineCommentDoubleCommented() async {
    // Continuations are ignored for code that looks like commented comments
    // although the original TODOs are still picked up.
    await assertErrorsInCode(r'''
main() {
//      // TODO: Implement something
//      //  that is too long for one line
//      main() {

//      // TODO: Implement something
//      // this is not a todo
//      main() {

//      // TODO: Implement something
//      main() {
}
''', [
      error(TodoCode.TODO, 20, 67,
          text: 'TODO: Implement something that is too long for one line'),
      error(TodoCode.TODO, 117, 25, text: 'TODO: Implement something'),
      error(TodoCode.TODO, 202, 25, text: 'TODO: Implement something'),
    ]);
  }

  test_todo_singleLineCommentLessIndentedContinuation() async {
    await assertErrorsInCode(r'''
main() {
  // TODO: Implement something
  //  that is too long for one line
//    this is not part of the todo
}
''', [
      error(TodoCode.TODO, 14, 61,
          text: 'TODO: Implement something that is too long for one line'),
    ]);
  }

  test_todo_singleLineCommentMoreIndentedContinuation() async {
    await assertErrorsInCode(r'''
main() {
  // TODO: Implement something
  //  that is too long for one line
  //      this is not part of the todo
}
''', [
      error(TodoCode.TODO, 14, 61,
          text: 'TODO: Implement something that is too long for one line'),
    ]);
  }

  test_todo_singleLineCommentNested() async {
    await assertErrorsInCode(r'''
main() {
  // TODO: Implement something
  //  that is too long for one line
  //  TODO: This is a separate todo that is accidentally indented
}
''', [
      error(TodoCode.TODO, 14, 61,
          text: 'TODO: Implement something that is too long for one line'),
      error(TodoCode.TODO, 82, 59,
          text: 'TODO: This is a separate todo that is accidentally indented'),
    ]);
  }

  test_todo_singleLineCommentWrapped() async {
    await assertErrorsInCode(r'''
main() {
  // TODO: Implement something
  //  that is too long for one line
  // this is not part of the todo

  // TODO: Implement something
  //  that is too long for one line

  //  this is not part of the todo

  // TODO: Implement something
  //  that is too long for one line
  //
  //  this is not part of the todo
}
''', [
      error(TodoCode.TODO, 14, 61,
          text: 'TODO: Implement something that is too long for one line'),
      error(TodoCode.TODO, 116, 61,
          text: 'TODO: Implement something that is too long for one line'),
      error(TodoCode.TODO, 220, 61,
          text: 'TODO: Implement something that is too long for one line'),
    ]);
  }

  test_undone() async {
    await assertErrorsInCode(r'''
main() {
  // UNDONE: This was undone
}
''', [
      error(TodoCode.UNDONE, 14, 23, text: 'UNDONE: This was undone'),
    ]);
  }
}
