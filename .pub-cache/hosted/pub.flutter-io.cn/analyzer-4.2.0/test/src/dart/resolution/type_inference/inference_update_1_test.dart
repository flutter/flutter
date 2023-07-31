// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(HorizontalInferenceEnabledTest);
    defineReflectiveTests(HorizontalInferenceDisabledTest);
  });
}

@reflectiveTest
class HorizontalInferenceDisabledTest extends PubPackageResolutionTest
    with HorizontalInferenceTestCases {
  @override
  String get testPackageLanguageVersion => '2.17';
}

@reflectiveTest
class HorizontalInferenceEnabledTest extends PubPackageResolutionTest
    with HorizontalInferenceTestCases {
  @override
  List<String> get experiments =>
      [...super.experiments, EnableString.inference_update_1];
}

mixin HorizontalInferenceTestCases on PubPackageResolutionTest {
  bool get _isEnabled => experiments.contains(EnableString.inference_update_1);

  test_closure_passed_to_dynamic() async {
    await assertNoErrorsInCode('''
test(dynamic d) => d(() {});
''');
    // No further assertions; we just want to make sure the interaction with a
    // dynamic receiver doesn't lead to a crash.
  }

  test_closure_passed_to_identical() async {
    await assertNoErrorsInCode('''
test() => identical(() {}, () {});
''');
    // No further assertions; we just want to make sure the interaction between
    // flow analysis for `identical` and deferred analysis of closures doesn't
    // lead to a crash.
  }

  test_fold_inference() async {
    var code = '''
example(List<int> list) {
  var a = list.fold(0, (x, y) => x + y);
}
''';
    if (_isEnabled) {
      await assertErrorsInCode(code, [
        error(HintCode.UNUSED_LOCAL_VARIABLE, 32, 1),
      ]);
      assertType(findElement.localVar('a').type, 'int');
      assertType(findElement.parameter('x').type, 'int');
      assertType(findElement.parameter('y').type, 'int');
      expect(
          findNode.binary('x + y').staticElement!.enclosingElement.name, 'num');
    } else {
      await assertErrorsInCode(code, [
        error(HintCode.UNUSED_LOCAL_VARIABLE, 32, 1),
        error(
            CompileTimeErrorCode
                .UNCHECKED_OPERATOR_INVOCATION_OF_NULLABLE_VALUE,
            61,
            1),
      ]);
    }
  }

  test_horizontal_inference_closure_as_parameter_type() async {
    // Test the case where a closure is passed to a parameter whose declared
    // type is not a function but instead a type parameter.  We should still
    // pick up the appropriate dependencies.
    await assertErrorsInCode('''
U f<T, U>(T t, U Function(T) g) => throw '';
test() {
  var a = f(() => 0, (h) => [h()]);
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 60, 1),
      if (!_isEnabled)
        error(
            CompileTimeErrorCode.UNCHECKED_INVOCATION_OF_NULLABLE_VALUE, 83, 1),
    ]);
    assertType(findNode.methodInvocation('f(').typeArgumentTypes![0],
        'int Function()');
    assertType(findNode.methodInvocation('f(').typeArgumentTypes![1],
        _isEnabled ? 'List<int>' : 'List<dynamic>');
    assertType(
        findNode.methodInvocation('f(').staticInvokeType,
        _isEnabled
            ? 'List<int> Function(int Function(), '
                'List<int> Function(int Function()))'
            : 'List<dynamic> Function(int Function(), '
                'List<dynamic> Function(int Function()))');
    assertType(findNode.simpleParameter('h)').declaredElement!.type,
        _isEnabled ? 'int Function()' : 'Object?');
    assertType(findNode.variableDeclaration('a =').declaredElement!.type,
        _isEnabled ? 'List<int>' : 'List<dynamic>');
  }

  test_horizontal_inference_necessary_due_to_wrong_explicit_parameter_type() async {
    // In this example, horizontal type inference is needed because although the
    // type of `y` is explicit, it's actually `x` that would have needed to be
    // explicit.
    await assertErrorsInCode('''
test(List<int> list) {
  var a = list.fold(0, (x, int y) => x + y);
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 29, 1),
      if (!_isEnabled)
        error(
            CompileTimeErrorCode
                .UNCHECKED_OPERATOR_INVOCATION_OF_NULLABLE_VALUE,
            62,
            1),
    ]);
    assertType(findElement.localVar('a').type, _isEnabled ? 'int' : 'dynamic');
    assertType(findElement.parameter('x').type, _isEnabled ? 'int' : 'Object?');
    assertType(findElement.parameter('y').type, 'int');
    expect(findNode.binary('+ y').staticElement?.enclosingElement.name,
        _isEnabled ? 'num' : null);
  }

  test_horizontal_inference_propagate_to_earlier_closure() async {
    await assertErrorsInCode('''
U f<T, U>(U Function(T) g, T Function() h) => throw '';
test() {
  var a = f((x) => [x], () => 0);
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 71, 1),
    ]);
    assertType(findNode.methodInvocation('f(').typeArgumentTypes![0], 'int');
    assertType(findNode.methodInvocation('f(').typeArgumentTypes![1],
        _isEnabled ? 'List<int>' : 'List<Object?>');
    assertType(
        findNode.methodInvocation('f(').staticInvokeType,
        _isEnabled
            ? 'List<int> Function(List<int> Function(int), int Function())'
            : 'List<Object?> Function(List<Object?> Function(int), int Function())');
    assertType(findNode.simpleParameter('x)').declaredElement!.type,
        _isEnabled ? 'int' : 'Object?');
    assertType(findNode.variableDeclaration('a =').declaredElement!.type,
        _isEnabled ? 'List<int>' : 'List<Object?>');
  }

  test_horizontal_inference_propagate_to_later_closure() async {
    await assertErrorsInCode('''
U f<T, U>(T Function() g, U Function(T) h) => throw '';
test() {
  var a = f(() => 0, (x) => [x]);
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 71, 1),
    ]);
    assertType(findNode.methodInvocation('f(').typeArgumentTypes![0], 'int');
    assertType(findNode.methodInvocation('f(').typeArgumentTypes![1],
        _isEnabled ? 'List<int>' : 'List<Object?>');
    assertType(
        findNode.methodInvocation('f(').staticInvokeType,
        _isEnabled
            ? 'List<int> Function(int Function(), List<int> Function(int))'
            : 'List<Object?> Function(int Function(), List<Object?> Function(int))');
    assertType(findNode.simpleParameter('x)').declaredElement!.type,
        _isEnabled ? 'int' : 'Object?');
    assertType(findNode.variableDeclaration('a =').declaredElement!.type,
        _isEnabled ? 'List<int>' : 'List<Object?>');
  }

  test_horizontal_inference_propagate_to_return_type() async {
    await assertErrorsInCode('''
U f<T, U>(T t, U Function(T) g) => throw '';
test() {
  var a = f(0, (x) => [x]);
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 60, 1),
    ]);
    assertType(findNode.methodInvocation('f(').typeArgumentTypes![0], 'int');
    assertType(findNode.methodInvocation('f(').typeArgumentTypes![1],
        _isEnabled ? 'List<int>' : 'List<Object?>');
    assertType(
        findNode.methodInvocation('f(').staticInvokeType,
        _isEnabled
            ? 'List<int> Function(int, List<int> Function(int))'
            : 'List<Object?> Function(int, List<Object?> Function(int))');
    assertType(findNode.simpleParameter('x)').declaredElement!.type,
        _isEnabled ? 'int' : 'Object?');
    assertType(findNode.variableDeclaration('a =').declaredElement!.type,
        _isEnabled ? 'List<int>' : 'List<Object?>');
  }

  test_horizontal_inference_simple() async {
    await assertNoErrorsInCode('''
void f<T>(T t, void Function(T) g) {}
test() => f(0, (x) {});
''');
    assertType(
        findNode.methodInvocation('f(').typeArgumentTypes!.single, 'int');
    assertType(findNode.methodInvocation('f(').staticInvokeType,
        'void Function(int, void Function(int))');
    assertType(findNode.simpleParameter('x').declaredElement!.type,
        _isEnabled ? 'int' : 'Object?');
  }

  test_horizontal_inference_simple_named() async {
    await assertNoErrorsInCode('''
void f<T>({required T t, required void Function(T) g}) {}
test() => f(t: 0, g: (x) {});
''');
    assertType(
        findNode.methodInvocation('f(').typeArgumentTypes!.single, 'int');
    assertType(findNode.methodInvocation('f(').staticInvokeType,
        'void Function({required void Function(int) g, required int t})');
    assertType(findNode.simpleParameter('x').declaredElement!.type,
        _isEnabled ? 'int' : 'Object?');
  }

  test_horizontal_inference_simple_parenthesized() async {
    await assertNoErrorsInCode('''
void f<T>(T t, void Function(T) g) {}
test() => f(0, ((x) {}));
''');
    assertType(
        findNode.methodInvocation('f(').typeArgumentTypes!.single, 'int');
    assertType(findNode.methodInvocation('f(').staticInvokeType,
        'void Function(int, void Function(int))');
    assertType(findNode.simpleParameter('x').declaredElement!.type,
        _isEnabled ? 'int' : 'Object?');
  }

  test_horizontal_inference_simple_parenthesized_named() async {
    await assertNoErrorsInCode('''
void f<T>({required T t, required void Function(T) g}) {}
test() => f(t: 0, g: ((x) {}));
''');
    assertType(
        findNode.methodInvocation('f(').typeArgumentTypes!.single, 'int');
    assertType(findNode.methodInvocation('f(').staticInvokeType,
        'void Function({required void Function(int) g, required int t})');
    assertType(findNode.simpleParameter('x').declaredElement!.type,
        _isEnabled ? 'int' : 'Object?');
  }

  test_horizontal_inference_simple_parenthesized_twice() async {
    await assertNoErrorsInCode('''
void f<T>(T t, void Function(T) g) {}
test() => f(0, (((x) {})));
''');
    assertType(
        findNode.methodInvocation('f(').typeArgumentTypes!.single, 'int');
    assertType(findNode.methodInvocation('f(').staticInvokeType,
        'void Function(int, void Function(int))');
    assertType(findNode.simpleParameter('x').declaredElement!.type,
        _isEnabled ? 'int' : 'Object?');
  }

  test_horizontal_inference_simple_parenthesized_twice_named() async {
    await assertNoErrorsInCode('''
void f<T>({required T t, required void Function(T) g}) {}
test() => f(t: 0, g: (((x) {})));
''');
    assertType(
        findNode.methodInvocation('f(').typeArgumentTypes!.single, 'int');
    assertType(findNode.methodInvocation('f(').staticInvokeType,
        'void Function({required void Function(int) g, required int t})');
    assertType(findNode.simpleParameter('x').declaredElement!.type,
        _isEnabled ? 'int' : 'Object?');
  }

  test_horizontal_inference_unnecessary_due_to_explicit_parameter_type() async {
    // In this example, there is no need for horizontal type inference because
    // the type of `x` is explicit.
    await assertErrorsInCode('''
test(List<int> list) {
  var a = list.fold(null, (int? x, y) => (x ?? 0) + y);
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 29, 1),
    ]);
    assertType(findElement.localVar('a').type, 'int?');
    assertType(findElement.parameter('x').type, 'int?');
    assertType(findElement.parameter('y').type, 'int');
    expect(findNode.binary('+ y').staticElement!.enclosingElement.name, 'num');
  }

  test_horizontal_inference_unnecessary_due_to_explicit_parameter_type_named() async {
    // In this example, there is no need for horizontal type inference because
    // the type of `x` is explicit.
    await assertErrorsInCode('''
T f<T>(T a, T Function({required T x, required int y}) b) => throw '';
test() {
  var a = f(null, ({int? x, required y}) => (x ?? 0) + y);
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 86, 1),
    ]);
    assertType(findElement.localVar('a').type, 'int?');
    assertType(findElement.parameter('x').type, 'int?');
    assertType(findElement.parameter('y').type, 'int');
    expect(findNode.binary('+ y').staticElement!.enclosingElement.name, 'num');
  }

  test_horizontal_inference_unnecessary_due_to_no_dependency() async {
    // In this example, there is no dependency between the two parameters of
    // `f`, so there should be no horizontal type inference between inferring
    // `null` and inferring `() => 0`.  (If there were horizontal type inference
    // between them, that would be a problem, because we would infer a type of
    // `null` for `T`).
    await assertNoErrorsInCode('''
void f<T>(T Function() g, T t) {}
test() => f(() => 0, null);
''');
    assertType(
        findNode.methodInvocation('f(').typeArgumentTypes!.single, 'int?');
    assertType(findNode.methodInvocation('f(').staticInvokeType,
        'void Function(int? Function(), int?)');
  }

  test_horizontal_inference_with_callback() async {
    await assertNoErrorsInCode('''
test(void Function<T>(T, void Function(T)) f) {
  f(0, (x) {
    x;
  });
}
''');
    assertType(findNode.simple('x;'), _isEnabled ? 'int' : 'Object?');
  }

  test_write_capture_deferred() async {
    await assertNoErrorsInCode('''
test(int? i) {
  if (i != null) {
    f(() { i = null; }, i); // (1)
    i; // (2)
  }
}
void f(void Function() g, Object? x) {}
''');
    // With the feature enabled, analysis of the closure is deferred until after
    // all the other arguments to `f`, so the `i` at (1) is not yet write
    // captured and retains its promoted value.  With the experiment disabled,
    // it is write captured immediately.
    assertType(findNode.simple('i); // (1)'), _isEnabled ? 'int' : 'int?');
    // At (2), after the call to `f`, the write capture has taken place
    // regardless of whether the experiment is enabled.
    assertType(findNode.simple('i; // (2)'), 'int?');
  }

  test_write_capture_deferred_named() async {
    await assertNoErrorsInCode('''
test(int? i) {
  if (i != null) {
    f(g: () { i = null; }, x: i); // (1)
    i; // (2)
  }
}
void f({required void Function() g, Object? x}) {}
''');
    // With the feature enabled, analysis of the closure is deferred until after
    // all the other arguments to `f`, so the `i` at (1) is not yet write
    // captured and retains its promoted value.  With the experiment disabled,
    // it is write captured immediately.
    assertType(findNode.simple('i); // (1)'), _isEnabled ? 'int' : 'int?');
    // At (2), after the call to `f`, the write capture has taken place
    // regardless of whether the experiment is enabled.
    assertType(findNode.simple('i; // (2)'), 'int?');
  }

  test_write_capture_deferred_redirecting_constructor() async {
    await assertNoErrorsInCode('''
class C {
  C(int? i) : this.other(i!, () { i = null; }, i);
  C.other(Object? x, void Function() g, Object? y);
}
''');
    // With the feature enabled, analysis of the closure is deferred until after
    // all the other arguments to `this.other`, so the `i` passed to `y` is not
    // yet write captured and retains its promoted value.  With the experiment
    // disabled, it is write captured immediately.
    assertType(findNode.simple('i);'), _isEnabled ? 'int' : 'int?');
  }

  test_write_capture_deferred_super_constructor() async {
    await assertNoErrorsInCode('''
class B {
  B(Object? x, void Function() g, Object? y);
}
class C extends B {
  C(int? i) : super(i!, () { i = null; }, i);
}
''');
    // With the feature enabled, analysis of the closure is deferred until after
    // all the other arguments to `this.other`, so the `i` passed to `y` is not
    // yet write captured and retains its promoted value.  With the experiment
    // disabled, it is write captured immediately.
    assertType(findNode.simple('i);'), _isEnabled ? 'int' : 'int?');
  }
}
