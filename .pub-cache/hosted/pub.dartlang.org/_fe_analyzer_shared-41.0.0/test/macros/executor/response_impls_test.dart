// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/executor/remote_instance.dart';
import 'package:test/fake.dart';
import 'package:test/test.dart';

import 'package:_fe_analyzer_shared/src/macros/executor/response_impls.dart';
import 'package:_fe_analyzer_shared/src/macros/executor.dart';
import 'package:_fe_analyzer_shared/src/macros/api.dart';

void main() {
  group('MacroInstanceIdentifierImpl', () {
    test('shouldExecute', () {
      for (var kind in DeclarationKind.values) {
        for (var phase in Phase.values) {
          var instance = instancesByKindAndPhase[kind]![phase]!;
          for (var otherKind in DeclarationKind.values) {
            for (var otherPhase in Phase.values) {
              var expected = false;
              if (otherPhase == phase) {
                if (kind == otherKind) {
                  expected = true;
                } else if (kind == DeclarationKind.function &&
                    otherKind == DeclarationKind.method) {
                  expected = true;
                } else if (kind == DeclarationKind.variable &&
                    otherKind == DeclarationKind.field) {
                  expected = true;
                }
              }
              expect(instance.shouldExecute(otherKind, otherPhase), expected,
                  reason: 'Expected a $kind macro in $phase to '
                      '${expected ? '' : 'not '}be applied to a $otherKind '
                      'in $otherPhase');
            }
          }
        }
      }
    });

    test('supportsDeclarationKind', () {
      for (var kind in DeclarationKind.values) {
        for (var phase in Phase.values) {
          var instance = instancesByKindAndPhase[kind]![phase]!;
          for (var otherKind in DeclarationKind.values) {
            var expected = false;
            if (kind == otherKind) {
              expected = true;
            } else if (kind == DeclarationKind.function &&
                otherKind == DeclarationKind.method) {
              expected = true;
            } else if (kind == DeclarationKind.variable &&
                otherKind == DeclarationKind.field) {
              expected = true;
            }
            expect(instance.supportsDeclarationKind(otherKind), expected,
                reason: 'Expected a $kind macro to ${expected ? '' : 'not '}'
                    'support a $otherKind');
          }
        }
      }
    });
  });
}

final Map<DeclarationKind, Map<Phase, MacroInstanceIdentifierImpl>>
    instancesByKindAndPhase = {
  DeclarationKind.clazz: {
    Phase.types: MacroInstanceIdentifierImpl(
        FakeClassTypesMacro(), RemoteInstance.uniqueId),
    Phase.declarations: MacroInstanceIdentifierImpl(
        FakeClassDeclarationsMacro(), RemoteInstance.uniqueId),
    Phase.definitions: MacroInstanceIdentifierImpl(
        FakeClassDefinitionMacro(), RemoteInstance.uniqueId),
  },
  DeclarationKind.constructor: {
    Phase.types: MacroInstanceIdentifierImpl(
        FakeConstructorTypesMacro(), RemoteInstance.uniqueId),
    Phase.declarations: MacroInstanceIdentifierImpl(
        FakeConstructorDeclarationsMacro(), RemoteInstance.uniqueId),
    Phase.definitions: MacroInstanceIdentifierImpl(
        FakeConstructorDefinitionMacro(), RemoteInstance.uniqueId),
  },
  DeclarationKind.field: {
    Phase.types: MacroInstanceIdentifierImpl(
        FakeFieldTypesMacro(), RemoteInstance.uniqueId),
    Phase.declarations: MacroInstanceIdentifierImpl(
        FakeFieldDeclarationsMacro(), RemoteInstance.uniqueId),
    Phase.definitions: MacroInstanceIdentifierImpl(
        FakeFieldDefinitionMacro(), RemoteInstance.uniqueId),
  },
  DeclarationKind.function: {
    Phase.types: MacroInstanceIdentifierImpl(
        FakeFunctionTypesMacro(), RemoteInstance.uniqueId),
    Phase.declarations: MacroInstanceIdentifierImpl(
        FakeFunctionDeclarationsMacro(), RemoteInstance.uniqueId),
    Phase.definitions: MacroInstanceIdentifierImpl(
        FakeFunctionDefinitionMacro(), RemoteInstance.uniqueId),
  },
  DeclarationKind.method: {
    Phase.types: MacroInstanceIdentifierImpl(
        FakeMethodTypesMacro(), RemoteInstance.uniqueId),
    Phase.declarations: MacroInstanceIdentifierImpl(
        FakeMethodDeclarationsMacro(), RemoteInstance.uniqueId),
    Phase.definitions: MacroInstanceIdentifierImpl(
        FakeMethodDefinitionMacro(), RemoteInstance.uniqueId),
  },
  DeclarationKind.variable: {
    Phase.types: MacroInstanceIdentifierImpl(
        FakeVariableTypesMacro(), RemoteInstance.uniqueId),
    Phase.declarations: MacroInstanceIdentifierImpl(
        FakeVariableDeclarationsMacro(), RemoteInstance.uniqueId),
    Phase.definitions: MacroInstanceIdentifierImpl(
        FakeVariableDefinitionMacro(), RemoteInstance.uniqueId),
  },
};

class FakeClassTypesMacro extends Fake implements ClassTypesMacro {}

class FakeClassDeclarationsMacro extends Fake
    implements ClassDeclarationsMacro {}

class FakeClassDefinitionMacro extends Fake implements ClassDefinitionMacro {}

class FakeConstructorTypesMacro extends Fake implements ConstructorTypesMacro {}

class FakeConstructorDeclarationsMacro extends Fake
    implements ConstructorDeclarationsMacro {}

class FakeConstructorDefinitionMacro extends Fake
    implements ConstructorDefinitionMacro {}

class FakeFieldTypesMacro extends Fake implements FieldTypesMacro {}

class FakeFieldDeclarationsMacro extends Fake
    implements FieldDeclarationsMacro {}

class FakeFieldDefinitionMacro extends Fake implements FieldDefinitionMacro {}

class FakeFunctionTypesMacro extends Fake implements FunctionTypesMacro {}

class FakeFunctionDeclarationsMacro extends Fake
    implements FunctionDeclarationsMacro {}

class FakeFunctionDefinitionMacro extends Fake
    implements FunctionDefinitionMacro {}

class FakeMethodTypesMacro extends Fake implements MethodTypesMacro {}

class FakeMethodDeclarationsMacro extends Fake
    implements MethodDeclarationsMacro {}

class FakeMethodDefinitionMacro extends Fake implements MethodDefinitionMacro {}

class FakeVariableTypesMacro extends Fake implements VariableTypesMacro {}

class FakeVariableDeclarationsMacro extends Fake
    implements VariableDeclarationsMacro {}

class FakeVariableDefinitionMacro extends Fake
    implements VariableDefinitionMacro {}
