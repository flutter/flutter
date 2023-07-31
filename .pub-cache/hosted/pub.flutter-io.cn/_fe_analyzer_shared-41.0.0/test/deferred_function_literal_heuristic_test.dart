// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/deferred_function_literal_heuristic.dart';
import 'package:test/test.dart';

main() {
  test('single', () {
    // If there is just a single function literal and no type variables, it is
    // selected.
    var f = Param('f');
    expect(
        _TestFunctionLiteralDeps(typeVars: [], functionLiterals: [f])
            .planReconciliationStages(),
        [
          [f]
        ]);
  });

  test('simple dependency', () {
    // If f depends on g, then g is selected first, and then f.
    var f = Param('f', argTypes: ['T']);
    var g = Param('g', retTypes: ['T']);
    expect(
        _TestFunctionLiteralDeps(typeVars: ['T'], functionLiterals: [f, g])
            .planReconciliationStages(),
        [
          [g],
          [f]
        ]);
  });

  test('long chain', () {
    // If f depends on g and g depends on h, then we do three separate stages:
    // h, then g, then f.
    var f = Param('f', argTypes: ['T']);
    var g = Param('g', argTypes: ['U'], retTypes: ['T']);
    var h = Param('h', retTypes: ['U']);
    expect(
        _TestFunctionLiteralDeps(
            typeVars: ['T', 'U'],
            functionLiterals: [f, g, h]).planReconciliationStages(),
        [
          [h],
          [g],
          [f]
        ]);
  });

  test('unrelated function literal', () {
    // Function literals that are independent of all the others are inferred
    // during the first stage.
    var f = Param('f', argTypes: ['T']);
    var g = Param('g', retTypes: ['T']);
    var h = Param('h');
    expect(
        _TestFunctionLiteralDeps(
            typeVars: ['T', 'U'],
            functionLiterals: [f, g, h]).planReconciliationStages(),
        [
          [g, h],
          [f]
        ]);
  });

  test('independent chains', () {
    // If f depends on g, and h depends on i, then g and i are selected first,
    // and then f and h.
    var f = Param('f', argTypes: ['T']);
    var g = Param('g', retTypes: ['T']);
    var h = Param('h', argTypes: ['U']);
    var i = Param('i', retTypes: ['U']);
    expect(
        _TestFunctionLiteralDeps(
            typeVars: ['T', 'U'],
            functionLiterals: [f, g, h, i]).planReconciliationStages(),
        [
          [g, i],
          [f, h]
        ]);
  });

  test('diamond', () {
    // Test a diamond dependency shape: f depends on g and h; g and h both
    // depend on i.
    var f = Param('f', argTypes: ['T', 'U']);
    var g = Param('g', argTypes: ['V'], retTypes: ['T']);
    var h = Param('h', argTypes: ['V'], retTypes: ['U']);
    var i = Param('i', retTypes: ['V']);
    expect(
        _TestFunctionLiteralDeps(
            typeVars: ['T', 'U', 'V'],
            functionLiterals: [f, g, h, i]).planReconciliationStages(),
        [
          [i],
          [g, h],
          [f]
        ]);
  });

  test('cycle', () {
    // A dependency cycle is inferred all at once.
    var f = Param('f', argTypes: ['T']);
    var g = Param('g', argTypes: ['U']);
    var h = Param('h', argTypes: ['U'], retTypes: ['T']);
    var i = Param('i', argTypes: ['T'], retTypes: ['U']);
    expect(
        _TestFunctionLiteralDeps(
            typeVars: ['T', 'U'],
            functionLiterals: [f, g, h, i]).planReconciliationStages(),
        [
          [h, i],
          [f, g]
        ]);
  });

  test('dependency on undeferred param', () {
    var f = Param('f', argTypes: ['T']);
    var x = Param('x', retTypes: ['T']);
    expect(
        _TestFunctionLiteralDeps(
            typeVars: ['T'],
            functionLiterals: [f],
            undeferredParams: [x]).planReconciliationStages(),
        [
          <Param>[],
          [f]
        ]);
  });
}

class Param {
  final String name;
  final List<String> argTypes;
  final List<String> retTypes;

  Param(this.name, {this.argTypes = const [], this.retTypes = const []});

  @override
  String toString() => name;
}

class _TestFunctionLiteralDeps
    extends FunctionLiteralDependencies<String, Param, Param> {
  final List<String> typeVars;
  final List<Param> functionLiterals;
  final List<Param> undeferredParams;

  _TestFunctionLiteralDeps(
      {required this.typeVars,
      required this.functionLiterals,
      this.undeferredParams = const []})
      : super(functionLiterals, typeVars, undeferredParams);

  @override
  Set<String> typeVarsFreeInParamParams(Param param) => param.argTypes.toSet();

  @override
  Set<String> typeVarsFreeInParamReturns(Param param) => param.retTypes.toSet();
}
