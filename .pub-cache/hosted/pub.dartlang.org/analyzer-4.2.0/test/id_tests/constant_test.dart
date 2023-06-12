// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:_fe_analyzer_shared/src/testing/id.dart' show ActualData, Id;
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/analysis/testing_data.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/util/ast_data_extractor.dart';

import '../util/id_testing_helper.dart';

main(List<String> args) async {
  Directory dataDir = Directory.fromUri(Platform.script
      .resolve('../../../_fe_analyzer_shared/test/constants/data'));
  return runTests<String>(dataDir,
      args: args,
      createUriForFileName: createUriForFileName,
      onFailure: onFailure,
      runTest:
          runTestFor(const ConstantsDataComputer(), [analyzerDefaultConfig]));
}

class ConstantsDataComputer extends DataComputer<String> {
  const ConstantsDataComputer();

  @override
  DataInterpreter<String> get dataValidator => const StringDataInterpreter();

  @override
  bool get supportsErrors => true;

  @override
  String? computeErrorData(TestConfig config, TestingData testingData, Id id,
      List<AnalysisError> errors) {
    var errorCodes = errors.map((e) => e.errorCode).where((errorCode) =>
        errorCode !=
        CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE);
    return errorCodes.isNotEmpty ? errorCodes.join(',') : null;
  }

  @override
  void computeUnitData(TestingData testingData, CompilationUnit unit,
      Map<Id, ActualData<String>> actualMap) {
    ConstantsDataExtractor(unit.declaredElement!.source.uri, actualMap)
        .run(unit);
  }
}

class ConstantsDataExtractor extends AstDataExtractor<String> {
  ConstantsDataExtractor(super.uri, super.actualMap);

  @override
  String? computeNodeValue(Id id, AstNode node) {
    if (node is Identifier) {
      var element = node.staticElement;
      if (element is PropertyAccessorElement && element.isSynthetic) {
        var variable = element.variable;
        if (!variable.isSynthetic && variable.isConst) {
          var value = variable.computeConstantValue();
          if (value != null) return _stringify(value);
        }
      }
    }
    return null;
  }

  String _stringify(DartObject value) {
    var type = value.type;
    if (type is InterfaceType) {
      if (type.isDartCoreNull) {
        return 'Null()';
      } else if (type.isDartCoreBool) {
        return 'Bool(${value.toBoolValue()})';
      } else if (type.isDartCoreString) {
        return 'String(${value.toStringValue()})';
      } else if (type.isDartCoreInt) {
        return 'Int(${value.toIntValue()})';
      } else if (type.isDartCoreDouble) {
        return 'Double(${value.toDoubleValue()})';
      } else if (type.isDartCoreSymbol) {
        return 'Symbol(${value.toSymbolValue()})';
      } else if (type.isDartCoreSet) {
        var elements = value.toSetValue()!.map(_stringify).join(',');
        return '${_stringifyType(type)}($elements)';
      } else if (type.isDartCoreList) {
        var elements = value.toListValue()!.map(_stringify).join(',');
        return '${_stringifyType(type)}($elements)';
      } else if (type.isDartCoreMap) {
        var elements = value.toMapValue()!.entries.map((entry) {
          var key = _stringify(entry.key!);
          var value = _stringify(entry.value!);
          return '$key:$value';
        }).join(',');
        return '${_stringifyType(type)}($elements)';
      } else {
        // TODO(paulberry): Add `isDartCoreType` to properly recognize type
        // literal constants.
        return 'TypeLiteral(${_stringifyType(value.toTypeValue()!)})';
      }
      // TODO(paulberry): Support object constants.
    } else if (type is FunctionType) {
      var element = value.toFunctionValue()!;
      return 'Function(${element.name},type=${_stringifyType(value.type!)})';
    }
    throw UnimplementedError('_stringify for type $type');
  }

  String _stringifyType(DartType type) {
    return type.getDisplayString(withNullability: true);
  }
}
