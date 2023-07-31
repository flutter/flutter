// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/error/codes.dart';

VerifySuperFormalParametersResult verifySuperFormalParameters({
  required ConstructorDeclaration constructor,
  ErrorReporter? errorReporter,
  bool hasExplicitPositionalArguments = false,
}) {
  var result = VerifySuperFormalParametersResult();
  for (var parameter in constructor.parameters.parameters) {
    parameter = parameter.notDefault;
    if (parameter is SuperFormalParameter) {
      var parameterElement =
          parameter.declaredElement as SuperFormalParameterElementImpl;
      if (parameter.isNamed) {
        result.namedArgumentNames.add(parameterElement.name);
      } else {
        result.positionalArgumentCount++;
        if (hasExplicitPositionalArguments) {
          errorReporter?.reportErrorForToken(
            CompileTimeErrorCode
                .POSITIONAL_SUPER_FORMAL_PARAMETER_WITH_POSITIONAL_ARGUMENT,
            parameter.name,
          );
        }
      }
    }
  }
  return result;
}

class VerifySuperFormalParametersResult {
  /// The count of positional arguments provided by the super-parameters.
  int positionalArgumentCount = 0;

  /// The names of named arguments provided by the super-parameters.
  List<String> namedArgumentNames = [];
}
