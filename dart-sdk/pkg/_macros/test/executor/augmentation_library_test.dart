// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/fake.dart';
import 'package:test/test.dart';

import 'package:_macros/src/api.dart';
import 'package:_macros/src/executor.dart';
import 'package:_macros/src/executor/augmentation_library.dart';
import 'package:_macros/src/executor/introspection_impls.dart';
import 'package:_macros/src/executor/remote_instance.dart';
import 'package:_macros/src/executor/response_impls.dart';

import '../util.dart';

void main() {
  group('AugmentationLibraryBuilder', () {
    final intIdentifier = TestIdentifier(
        id: RemoteInstance.uniqueId,
        name: 'int',
        kind: IdentifierKind.topLevelMember,
        staticScope: null,
        uri: Uri.parse('dart:core'));
    final objectIdentifier = TestIdentifier(
        id: RemoteInstance.uniqueId,
        name: 'Object',
        kind: IdentifierKind.topLevelMember,
        staticScope: null,
        uri: Uri.parse('dart:core'));
    final superclassIdentifier = TestIdentifier(
        id: RemoteInstance.uniqueId,
        name: 'SomeSuperclass',
        kind: IdentifierKind.topLevelMember,
        uri: null,
        staticScope: null);
    final interfaceIdentifiers = [
      for (var i = 0; i < 2; i++)
        TestIdentifier(
            id: RemoteInstance.uniqueId,
            name: 'I$i',
            kind: IdentifierKind.topLevelMember,
            uri: null,
            staticScope: null),
    ];
    final mixinIdentifiers = [
      for (var i = 0; i < 2; i++)
        TestIdentifier(
            id: RemoteInstance.uniqueId,
            name: 'M$i',
            kind: IdentifierKind.topLevelMember,
            uri: null,
            staticScope: null),
    ];

    test('can combine multiple execution results', () {
      final classes = <IdentifierImpl, ClassDeclaration>{};
      for (var i = 0; i < 2; i++) {
        for (var j = 0; j < 3; j++) {
          final identifier =
              IdentifierImpl(id: RemoteInstance.uniqueId, name: 'Foo$i$j');
          classes[identifier] = ClassDeclarationImpl(
              id: RemoteInstance.uniqueId,
              identifier: identifier,
              library: Fixtures.library,
              metadata: [],
              typeParameters: [],
              interfaces: [],
              hasAbstract: false,
              hasBase: false,
              hasExternal: false,
              hasFinal: false,
              hasInterface: false,
              hasMixin: false,
              hasSealed: false,
              mixins: [],
              superclass: null);
        }
      }
      var results = [
        for (var i = 0; i < 2; i++)
          MacroExecutionResultImpl(
            diagnostics: [],
            enumValueAugmentations: {},
            extendsTypeAugmentations: {
              for (var j in [0, 2])
                classes.keys.firstWhere(
                        (identifier) => identifier.name == 'Foo$i$j'):
                    NamedTypeAnnotationCode(name: superclassIdentifier),
            },
            interfaceAugmentations: {
              for (var j = 0; j < 3; j++)
                classes.keys
                    .firstWhere((identifier) => identifier.name == 'Foo$i$j'): [
                  for (var k = 0; k < j; k++)
                    NamedTypeAnnotationCode(name: interfaceIdentifiers[k]),
                ]
            },
            libraryAugmentations: [
              for (var j = 0; j < 3; j++)
                DeclarationCode.fromParts(
                    [intIdentifier, ' get i${i}j$j => ${i + j};\n']),
            ],
            mixinAugmentations: {
              for (var j = 0; j < 3; j++)
                classes.keys
                    .firstWhere((identifier) => identifier.name == 'Foo$i$j'): [
                  for (var k = 0; k < i; k++)
                    NamedTypeAnnotationCode(name: mixinIdentifiers[k]),
                ]
            },
            newTypeNames: [
              'Foo${i}0',
              'Foo${i}1',
              'Foo${i}2',
            ],
            typeAugmentations: {
              for (var j = 0; j < 3; j++)
                classes.keys
                    .firstWhere((identifier) => identifier.name == 'Foo$i$j'): [
                  DeclarationCode.fromParts([intIdentifier, ' get i => $i;\n']),
                  DeclarationCode.fromParts([intIdentifier, ' get j => $j;\n']),
                ]
            },
          ),
      ];
      var library = _TestExecutor().buildAugmentationLibrary(
          Fixtures.library.uri,
          results,
          (Identifier i) => classes[i]!,
          (Identifier i) => (i as TestIdentifier).resolved,
          (OmittedTypeAnnotation i) =>
              (i as TestOmittedTypeAnnotation).inferredType);
      expect(library, equalsIgnoringWhitespace('''
        augment library 'package:foo/bar.dart';

        import 'dart:core' as prefix0;

        prefix0.int get i0j0 => 0;
        prefix0.int get i0j1 => 1;
        prefix0.int get i0j2 => 2;
        prefix0.int get i1j0 => 1;
        prefix0.int get i1j1 => 2;
        prefix0.int get i1j2 => 3;
        augment class Foo00 extends SomeSuperclass {
          prefix0.int get i => 0;
          prefix0.int get j => 0;
        }
        augment class Foo02 extends SomeSuperclass implements I0, I1 {
          prefix0.int get i => 0;
          prefix0.int get j => 2;
        }
        augment class Foo10 extends SomeSuperclass with M0 {
          prefix0.int get i => 1;
          prefix0.int get j => 0;
        }
        augment class Foo12 extends SomeSuperclass with M0 implements I0, I1 {
          prefix0.int get i => 1;
          prefix0.int get j => 2;
        }
        augment class Foo01 implements I0 {
          prefix0.int get i => 0;
          prefix0.int get j => 1;
        }
        augment class Foo11 with M0 implements I0 {
          prefix0.int get i => 1;
          prefix0.int get j => 1;
        }
      '''));
    });

    test('can add imports for identifiers', () {
      var fooIdentifier = TestIdentifier(
          id: RemoteInstance.uniqueId,
          name: 'Foo',
          kind: IdentifierKind.topLevelMember,
          staticScope: null,
          uri: Uri.parse('package:foo/foo.dart'));
      var barIdentifier = TestIdentifier(
          id: RemoteInstance.uniqueId,
          name: 'Bar',
          kind: IdentifierKind.topLevelMember,
          staticScope: null,
          uri: Uri.parse('package:bar/bar.dart'));
      var builderIdentifier = TestIdentifier(
          id: RemoteInstance.uniqueId,
          name: 'Builder',
          kind: IdentifierKind.topLevelMember,
          staticScope: null,
          uri: Uri.parse('package:builder/builder.dart'));
      var barInstanceMember = TestIdentifier(
          id: RemoteInstance.uniqueId,
          name: 'baz',
          kind: IdentifierKind.instanceMember,
          staticScope: null,
          uri: Uri.parse('package:bar/bar.dart'));
      var barStaticMember = TestIdentifier(
          id: RemoteInstance.uniqueId,
          name: 'zap',
          kind: IdentifierKind.staticInstanceMember,
          staticScope: 'Bar',
          uri: Uri.parse('package:bar/bar.dart'));
      var results = [
        MacroExecutionResultImpl(
          diagnostics: [],
          enumValueAugmentations: {},
          extendsTypeAugmentations: {},
          interfaceAugmentations: {},
          mixinAugmentations: {},
          typeAugmentations: {},
          libraryAugmentations: [
            DeclarationCode.fromParts([
              'class FooBuilder<T extends ',
              fooIdentifier,
              '> implements ',
              builderIdentifier,
              '<',
              barIdentifier,
              '<T>> {\n',
              'late ',
              intIdentifier,
              ' ${barInstanceMember.name};\n',
              barIdentifier,
              '<T> build() => new ',
              barIdentifier,
              '()..',
              barInstanceMember,
              ' = ',
              barStaticMember,
              ';',
              '\n}',
            ]),
          ],
          newTypeNames: [
            'FooBuilder',
          ],
        )
      ];
      var library = _TestExecutor().buildAugmentationLibrary(
          Fixtures.library.uri,
          results,
          (_) => throw UnimplementedError(),
          (Identifier i) => (i as TestIdentifier).resolved,
          (OmittedTypeAnnotation i) =>
              (i as TestOmittedTypeAnnotation).inferredType);
      expect(library, equalsIgnoringWhitespace('''
        augment library 'package:foo/bar.dart';

        import 'package:foo/foo.dart' as prefix0;
        import 'package:builder/builder.dart' as prefix1;
        import 'package:bar/bar.dart' as prefix2;
        import 'dart:core' as prefix3;

        class FooBuilder<T extends prefix0.Foo> implements prefix1.Builder<prefix2.Bar<T>> {
          late prefix3.int baz;

          prefix2.Bar<T> build() => new prefix2.Bar()..baz = prefix2.Bar.zap;
        }
      '''));
    });

    test('can handle omitted type annotations', () {
      var results = [
        MacroExecutionResultImpl(
            diagnostics: [],
            enumValueAugmentations: {},
            extendsTypeAugmentations: {},
            interfaceAugmentations: {},
            mixinAugmentations: {},
            typeAugmentations: {},
            libraryAugmentations: [
              DeclarationCode.fromParts([
                OmittedTypeAnnotationCode(
                    TestOmittedTypeAnnotation(NamedTypeAnnotationImpl(
                  id: RemoteInstance.uniqueId,
                  identifier: intIdentifier,
                  isNullable: false,
                  typeArguments: [],
                ))),
                ' x = 1;',
              ]),
            ],
            newTypeNames: []),
      ];
      var library = _TestExecutor().buildAugmentationLibrary(
          Fixtures.library.uri,
          results,
          (_) => throw UnimplementedError(),
          (Identifier i) => (i as TestIdentifier).resolved,
          (OmittedTypeAnnotation i) =>
              (i as TestOmittedTypeAnnotation).inferredType);
      expect(library, equalsIgnoringWhitespace('''
        augment library 'package:foo/bar.dart';

        import 'dart:core' as prefix0;

        prefix0.int x = 1;
      '''));
    });

    test('can handle name conflicts', () {
      var omittedType0 = TestOmittedTypeAnnotation();
      var omittedType1 = TestOmittedTypeAnnotation();

      var omittedTypeIdentifier = TestIdentifier(
          id: RemoteInstance.uniqueId,
          name: 'OmittedType',
          kind: IdentifierKind.topLevelMember,
          staticScope: null,
          uri: Uri.parse('package:foo/foo.dart'));
      var omittedTypeIdentifier0 = TestIdentifier(
          id: RemoteInstance.uniqueId,
          name: 'OmittedType0',
          kind: IdentifierKind.topLevelMember,
          staticScope: null,
          uri: Uri.parse('package:bar/bar.dart'));
      var prefixInstanceMember = TestIdentifier(
          id: RemoteInstance.uniqueId,
          name: 'prefix',
          kind: IdentifierKind.instanceMember,
          staticScope: null,
          uri: Uri.parse('package:bar/bar.dart'));
      var prefix0InstanceMember = TestIdentifier(
          id: RemoteInstance.uniqueId,
          name: 'prefix0',
          kind: IdentifierKind.instanceMember,
          staticScope: null,
          uri: Uri.parse('package:bar/bar.dart'));
      var prefix1StaticMember = TestIdentifier(
          id: RemoteInstance.uniqueId,
          name: 'prefix1',
          kind: IdentifierKind.staticInstanceMember,
          staticScope: 'OmittedType1',
          uri: Uri.parse('package:bar/bar.dart'));
      var results = [
        MacroExecutionResultImpl(
          diagnostics: [],
          enumValueAugmentations: {},
          extendsTypeAugmentations: {},
          interfaceAugmentations: {},
          mixinAugmentations: {},
          typeAugmentations: {},
          libraryAugmentations: [
            DeclarationCode.fromParts([
              'class OmittedType {\n  ',
              omittedType0.code,
              ' method(',
              omittedType1.code,
              ' o) {\n    ',
              intIdentifier,
              ' ${prefixInstanceMember.name} = 0;\n    ',
              omittedTypeIdentifier,
              ' ${prefix0InstanceMember.name} = ',
              'new ',
              omittedTypeIdentifier,
              '();\n    ',
              'new ',
              omittedTypeIdentifier0,
              '()..',
              prefixInstanceMember,
              ' = ',
              prefix1StaticMember,
              ';',
              '\n  }',
              '\n}',
            ]),
          ],
          newTypeNames: [
            'OmittedType',
          ],
        )
      ];
      var omittedTypes = <OmittedTypeAnnotation, String>{};
      var library = _TestExecutor().buildAugmentationLibrary(
          Fixtures.library.uri,
          results,
          (_) => throw UnimplementedError(),
          (Identifier i) => (i as TestIdentifier).resolved,
          (OmittedTypeAnnotation i) =>
              (i as TestOmittedTypeAnnotation).inferredType,
          omittedTypes: omittedTypes);
      expect(library, equalsIgnoringWhitespace('''
        augment library 'package:foo/bar.dart';

        import 'dart:core' as prefix2_0;
        import 'package:foo/foo.dart' as prefix2_1;
        import 'package:bar/bar.dart' as prefix2_2;

        class OmittedType {
          OmittedType2_0 method(OmittedType2_1 o) {
            prefix2_0.int prefix = 0;
            prefix2_1.OmittedType prefix0 = new prefix2_1.OmittedType();
            new prefix2_2.OmittedType0()..prefix = prefix2_2.OmittedType1.prefix1;
          }
        }
      '''));
      expect(omittedTypes[omittedType0], 'OmittedType2_0');
      expect(omittedTypes[omittedType1], 'OmittedType2_1');
    });

    test('can augment enums and enum values', () async {
      final myEnum = EnumDeclarationImpl(
        id: RemoteInstance.uniqueId,
        identifier: TestIdentifier(
            id: RemoteInstance.uniqueId,
            name: 'MyEnum',
            kind: IdentifierKind.topLevelMember,
            uri: Uri.parse('a.dart'),
            staticScope: null),
        library: Fixtures.library,
        metadata: [],
        typeParameters: [],
        interfaces: [],
        mixins: [],
      );
      final myField = FieldDeclarationImpl(
          id: RemoteInstance.uniqueId,
          identifier: TestIdentifier(
              id: RemoteInstance.uniqueId,
              name: 'value',
              kind: IdentifierKind.instanceMember,
              uri: Uri.parse('a.dart'),
              staticScope: null),
          library: Fixtures.library,
          metadata: [],
          definingType: myEnum.identifier,
          hasAbstract: false,
          hasConst: false,
          hasExternal: false,
          hasFinal: true,
          hasInitializer: false,
          hasLate: false,
          hasStatic: false,
          type: NamedTypeAnnotationImpl(
              id: RemoteInstance.uniqueId,
              isNullable: false,
              identifier: intIdentifier,
              typeArguments: []));

      var results = [
        MacroExecutionResultImpl(diagnostics: [], enumValueAugmentations: {
          myEnum.identifier: [
            DeclarationCode.fromParts(['a(1),\n']),
          ],
        }, extendsTypeAugmentations: {}, typeAugmentations: {
          myEnum.identifier: [
            DeclarationCode.fromParts(['MyEnum(', myField.identifier, ');\n']),
            DeclarationCode.fromParts(
                ['final ', intIdentifier, ' ', myField.identifier.name, ';\n']),
          ],
        }, interfaceAugmentations: {
          myEnum.identifier: [
            NamedTypeAnnotationCode(name: interfaceIdentifiers.first),
          ],
        }, mixinAugmentations: {
          myEnum.identifier: [
            NamedTypeAnnotationCode(name: mixinIdentifiers.first),
          ],
        }, newTypeNames: [], libraryAugmentations: []),
      ];
      var library = _TestExecutor().buildAugmentationLibrary(
          Fixtures.library.uri,
          results,
          (Identifier i) =>
              i == myEnum.identifier ? myEnum : throw UnimplementedError(),
          (Identifier i) => (i as TestIdentifier).resolved,
          (OmittedTypeAnnotation i) =>
              (i as TestOmittedTypeAnnotation).inferredType);
      expect(library, equalsIgnoringWhitespace('''
        augment library 'package:foo/bar.dart';

        import 'a.dart' as prefix0;
        import 'dart:core' as prefix1;

        augment enum MyEnum with M0 implements I0 {
          a(1),
          ;
          MyEnum(this.value);
          final prefix1.int value;
        }
      '''));
    });

    test('can augment extensions', () async {
      final myExtension = ExtensionDeclarationImpl(
        id: RemoteInstance.uniqueId,
        identifier: TestIdentifier(
            id: RemoteInstance.uniqueId,
            name: 'MyExtension',
            kind: IdentifierKind.topLevelMember,
            uri: Uri.parse('a.dart'),
            staticScope: null),
        library: Fixtures.library,
        metadata: [],
        typeParameters: [],
        onType: Fixtures.myClassType,
      );
      final myGetter = MethodDeclarationImpl(
          id: RemoteInstance.uniqueId,
          identifier: TestIdentifier(
              id: RemoteInstance.uniqueId,
              name: 'x',
              kind: IdentifierKind.instanceMember,
              uri: Uri.parse('a.dart'),
              staticScope: null),
          library: Fixtures.library,
          metadata: [],
          definingType: myExtension.identifier,
          hasExternal: false,
          hasStatic: false,
          returnType: NamedTypeAnnotationImpl(
              id: RemoteInstance.uniqueId,
              isNullable: false,
              identifier: intIdentifier,
              typeArguments: []),
          hasBody: true,
          isGetter: true,
          isOperator: false,
          isSetter: false,
          namedParameters: [],
          positionalParameters: [],
          typeParameters: []);

      var results = [
        MacroExecutionResultImpl(
            diagnostics: [],
            enumValueAugmentations: {},
            extendsTypeAugmentations: {},
            typeAugmentations: {
              myExtension.identifier: [
                DeclarationCode.fromParts([
                  intIdentifier,
                  ' get ',
                  myGetter.identifier.name,
                  ' => 1;\n'
                ]),
              ],
            },
            interfaceAugmentations: {},
            mixinAugmentations: {},
            newTypeNames: [],
            libraryAugmentations: []),
      ];
      var library = _TestExecutor().buildAugmentationLibrary(
          Fixtures.library.uri,
          results,
          (Identifier i) => i == myExtension.identifier
              ? myExtension
              : throw UnimplementedError(),
          (Identifier i) => (i as TestIdentifier).resolved,
          (OmittedTypeAnnotation i) =>
              (i as TestOmittedTypeAnnotation).inferredType);
      expect(library, equalsIgnoringWhitespace('''
        augment library 'package:foo/bar.dart';

        import 'dart:core' as prefix0;

        augment extension MyExtension {
          prefix0.int get x => 1;
        }
      '''));
    });

    test('copies keywords for classes', () async {
      for (final hasKeywords in [true, false]) {
        final clazz = ClassDeclarationImpl(
            id: RemoteInstance.uniqueId,
            identifier:
                IdentifierImpl(id: RemoteInstance.uniqueId, name: 'MyClass'),
            library: Fixtures.library,
            metadata: [],
            typeParameters: [],
            interfaces: [],
            hasAbstract: hasKeywords,
            hasBase: hasKeywords,
            hasExternal: hasKeywords,
            hasFinal: hasKeywords,
            hasInterface: hasKeywords,
            hasMixin: hasKeywords,
            hasSealed: hasKeywords,
            mixins: [],
            superclass: null);

        var results = [
          MacroExecutionResultImpl(
              diagnostics: [],
              enumValueAugmentations: {},
              extendsTypeAugmentations: {},
              typeAugmentations: {
                clazz.identifier: [
                  DeclarationCode.fromParts(['']),
                ]
              },
              interfaceAugmentations: {},
              mixinAugmentations: {},
              newTypeNames: [],
              libraryAugmentations: []),
        ];
        var library = _TestExecutor().buildAugmentationLibrary(
            Fixtures.library.uri,
            results,
            (Identifier i) =>
                i == clazz.identifier ? clazz : throw UnimplementedError(),
            (Identifier i) => (i as TestIdentifier).resolved,
            (OmittedTypeAnnotation i) =>
                (i as TestOmittedTypeAnnotation).inferredType);
        final expectedKeywords = [
          if (hasKeywords) ...[
            'abstract',
            'base',
            'external',
            'final',
            'interface',
            'mixin',
            'sealed'
          ]
        ];
        // Add extra space after, if we have keywords
        if (expectedKeywords.isNotEmpty) expectedKeywords.add('');
        expect(library, equalsIgnoringWhitespace('''
            augment library 'package:foo/bar.dart';

            augment ${expectedKeywords.join(' ')}class MyClass {
            }
          '''));
      }
    });

    test('copies generic types and bounds', () async {
      final clazz = ClassDeclarationImpl(
          id: RemoteInstance.uniqueId,
          identifier:
              IdentifierImpl(id: RemoteInstance.uniqueId, name: 'MyClass'),
          library: Fixtures.library,
          metadata: [],
          typeParameters: [
            TypeParameterDeclarationImpl(
                id: RemoteInstance.uniqueId,
                identifier:
                    IdentifierImpl(id: RemoteInstance.uniqueId, name: 'T'),
                library: Fixtures.library,
                metadata: [],
                bound: NamedTypeAnnotationImpl(
                    id: RemoteInstance.uniqueId,
                    isNullable: false,
                    identifier: objectIdentifier,
                    typeArguments: [])),
            TypeParameterDeclarationImpl(
                id: RemoteInstance.uniqueId,
                identifier:
                    IdentifierImpl(id: RemoteInstance.uniqueId, name: 'S'),
                library: Fixtures.library,
                metadata: [],
                bound: null),
          ],
          interfaces: [],
          hasAbstract: false,
          hasBase: false,
          hasExternal: false,
          hasFinal: false,
          hasInterface: false,
          hasMixin: false,
          hasSealed: false,
          mixins: [],
          superclass: null);

      var results = [
        MacroExecutionResultImpl(
            diagnostics: [],
            enumValueAugmentations: {},
            extendsTypeAugmentations: {},
            typeAugmentations: {
              clazz.identifier: [
                DeclarationCode.fromParts(['']),
              ]
            },
            interfaceAugmentations: {},
            mixinAugmentations: {},
            newTypeNames: [],
            libraryAugmentations: []),
      ];
      var library = _TestExecutor().buildAugmentationLibrary(
          Fixtures.library.uri,
          results,
          (Identifier i) =>
              i == clazz.identifier ? clazz : throw UnimplementedError(),
          (Identifier i) => (i as TestIdentifier).resolved,
          (OmittedTypeAnnotation i) =>
              (i as TestOmittedTypeAnnotation).inferredType);
      expect(library, equalsIgnoringWhitespace('''
            augment library 'package:foo/bar.dart';

            import 'dart:core' as prefix0;

            augment class MyClass<T extends prefix0.Object, S> {
            }
          '''));
    });
  });
}

class _TestExecutor extends MacroExecutor
    with AugmentationLibraryBuilder, Fake {}
