// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_macros/src/api.dart';
import 'package:_macros/src/executor.dart';
import 'package:_macros/src/executor/remote_instance.dart';
import 'package:_macros/src/executor/response_impls.dart';
import 'package:test/fake.dart';
import 'package:test/test.dart';

void main() {
  group('MacroInstanceIdentifierImpl', () {
    test('shouldExecute', () {
      for (var kind in DeclarationKind.values) {
        for (var phase in Phase.values) {
          var instance = instancesByKindAndPhase[kind]?[phase];
          if (instance == null) continue;
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
          var instance = instancesByKindAndPhase[kind]?[phase];
          if (instance == null) continue;
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
  DeclarationKind.classType: {
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
  DeclarationKind.enumType: {
    Phase.types: MacroInstanceIdentifierImpl(
        FakeEnumTypesMacro(), RemoteInstance.uniqueId),
    Phase.declarations: MacroInstanceIdentifierImpl(
        FakeEnumDeclarationsMacro(), RemoteInstance.uniqueId),
    Phase.definitions: MacroInstanceIdentifierImpl(
        FakeEnumDefinitionMacro(), RemoteInstance.uniqueId),
  },
  DeclarationKind.enumValue: {
    Phase.types: MacroInstanceIdentifierImpl(
        FakeEnumValueTypesMacro(), RemoteInstance.uniqueId),
    Phase.declarations: MacroInstanceIdentifierImpl(
        FakeEnumValueDeclarationsMacro(), RemoteInstance.uniqueId),
    Phase.definitions: MacroInstanceIdentifierImpl(
        FakeEnumValueDefinitionMacro(), RemoteInstance.uniqueId),
  },
  DeclarationKind.extension: {
    Phase.types: MacroInstanceIdentifierImpl(
        FakeExtensionTypesMacro(), RemoteInstance.uniqueId),
    Phase.declarations: MacroInstanceIdentifierImpl(
        FakeExtensionDeclarationsMacro(), RemoteInstance.uniqueId),
    Phase.definitions: MacroInstanceIdentifierImpl(
        FakeExtensionDefinitionMacro(), RemoteInstance.uniqueId),
  },
  DeclarationKind.extensionType: {
    Phase.types: MacroInstanceIdentifierImpl(
        FakeExtensionTypeTypesMacro(), RemoteInstance.uniqueId),
    Phase.declarations: MacroInstanceIdentifierImpl(
        FakeExtensionTypeDeclarationsMacro(), RemoteInstance.uniqueId),
    Phase.definitions: MacroInstanceIdentifierImpl(
        FakeExtensionTypeDefinitionMacro(), RemoteInstance.uniqueId),
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
  DeclarationKind.library: {
    Phase.types: MacroInstanceIdentifierImpl(
        FakeLibraryTypesMacro(), RemoteInstance.uniqueId),
    Phase.declarations: MacroInstanceIdentifierImpl(
        FakeLibraryDeclarationsMacro(), RemoteInstance.uniqueId),
    Phase.definitions: MacroInstanceIdentifierImpl(
        FakeLibraryDefinitionMacro(), RemoteInstance.uniqueId),
  },
  DeclarationKind.method: {
    Phase.types: MacroInstanceIdentifierImpl(
        FakeMethodTypesMacro(), RemoteInstance.uniqueId),
    Phase.declarations: MacroInstanceIdentifierImpl(
        FakeMethodDeclarationsMacro(), RemoteInstance.uniqueId),
    Phase.definitions: MacroInstanceIdentifierImpl(
        FakeMethodDefinitionMacro(), RemoteInstance.uniqueId),
  },
  DeclarationKind.mixinType: {
    Phase.types: MacroInstanceIdentifierImpl(
        FakeMixinTypesMacro(), RemoteInstance.uniqueId),
    Phase.declarations: MacroInstanceIdentifierImpl(
        FakeMixinDeclarationsMacro(), RemoteInstance.uniqueId),
    Phase.definitions: MacroInstanceIdentifierImpl(
        FakeMixinDefinitionMacro(), RemoteInstance.uniqueId),
  },
  DeclarationKind.typeAlias: {
    Phase.types: MacroInstanceIdentifierImpl(
        FakeTypeAliasTypesMacro(), RemoteInstance.uniqueId),
    Phase.declarations: MacroInstanceIdentifierImpl(
        FakeTypeAliasDeclarationsMacro(), RemoteInstance.uniqueId),
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

class FakeMixinTypesMacro extends Fake implements MixinTypesMacro {}

class FakeMixinDeclarationsMacro extends Fake
    implements MixinDeclarationsMacro {}

class FakeMixinDefinitionMacro extends Fake implements MixinDefinitionMacro {}

class FakeEnumTypesMacro extends Fake implements EnumTypesMacro {}

class FakeEnumDeclarationsMacro extends Fake implements EnumDeclarationsMacro {}

class FakeEnumDefinitionMacro extends Fake implements EnumDefinitionMacro {}

class FakeEnumValueTypesMacro extends Fake implements EnumValueTypesMacro {}

class FakeEnumValueDeclarationsMacro extends Fake
    implements EnumValueDeclarationsMacro {}

class FakeEnumValueDefinitionMacro extends Fake
    implements EnumValueDefinitionMacro {}

class FakeExtensionTypesMacro extends Fake implements ExtensionTypesMacro {}

class FakeExtensionDeclarationsMacro extends Fake
    implements ExtensionDeclarationsMacro {}

class FakeExtensionDefinitionMacro extends Fake
    implements ExtensionDefinitionMacro {}

class FakeExtensionTypeTypesMacro extends Fake
    implements ExtensionTypeTypesMacro {}

class FakeExtensionTypeDeclarationsMacro extends Fake
    implements ExtensionTypeDeclarationsMacro {}

class FakeExtensionTypeDefinitionMacro extends Fake
    implements ExtensionTypeDefinitionMacro {}

class FakeLibraryTypesMacro extends Fake implements LibraryTypesMacro {}

class FakeLibraryDeclarationsMacro extends Fake
    implements LibraryDeclarationsMacro {}

class FakeLibraryDefinitionMacro extends Fake
    implements LibraryDefinitionMacro {}

class FakeTypeAliasTypesMacro extends Fake implements TypeAliasTypesMacro {}

class FakeTypeAliasDeclarationsMacro extends Fake
    implements TypeAliasDeclarationsMacro {}
