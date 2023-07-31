// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/executor/introspection_impls.dart';
import 'package:_fe_analyzer_shared/src/macros/executor/remote_instance.dart';
import 'package:test/fake.dart';
import 'package:test/test.dart';

import 'package:_fe_analyzer_shared/src/macros/executor.dart';
import 'package:_fe_analyzer_shared/src/macros/api.dart';
import 'package:_fe_analyzer_shared/src/macros/executor/augmentation_library.dart';
import 'package:_fe_analyzer_shared/src/macros/executor/response_impls.dart';

import '../util.dart';

void main() {
  group('AugmentationLibraryBuilder', () {
    final intIdentifier = TestIdentifier(
        id: RemoteInstance.uniqueId,
        name: 'int',
        kind: IdentifierKind.topLevelMember,
        staticScope: null,
        uri: Uri.parse('dart:core'));

    test('can combine multiple execution results', () {
      var results = [
        for (var i = 0; i < 2; i++)
          MacroExecutionResultImpl(classAugmentations: {
            for (var j = 0; j < 3; j++)
              'Foo$i$j': [
                DeclarationCode.fromParts([intIdentifier, ' get i => $i;\n']),
                DeclarationCode.fromParts([intIdentifier, ' get j => $j;\n']),
              ]
          }, libraryAugmentations: [
            for (var j = 0; j < 3; j++)
              DeclarationCode.fromParts(
                  [intIdentifier, ' get i${i}j$j => ${i + j};\n']),
          ], newTypeNames: [
            'Foo${i}0',
            'Foo${i}1',
            'Foo${i}2',
          ]),
      ];
      var library = _TestExecutor().buildAugmentationLibrary(
          results,
          (Identifier i) => (i as TestIdentifier).resolved,
          (OmittedTypeAnnotation i) =>
              (i as TestOmittedTypeAnnotation).inferredType);
      expect(library, equalsIgnoringWhitespace('''
        import 'dart:core' as prefix0;

        prefix0.int get i0j0 => 0;
        prefix0.int get i0j1 => 1;
        prefix0.int get i0j2 => 2;
        prefix0.int get i1j0 => 1;
        prefix0.int get i1j1 => 2;
        prefix0.int get i1j2 => 3;
        augment class Foo00 {
          prefix0.int get i => 0;
          prefix0.int get j => 0;
        }
        augment class Foo01 {
          prefix0.int get i => 0;
          prefix0.int get j => 1;
        }
        augment class Foo02 {
          prefix0.int get i => 0;
          prefix0.int get j => 2;
        }
        augment class Foo10 {
          prefix0.int get i => 1;
          prefix0.int get j => 0;
        }
        augment class Foo11 {
          prefix0.int get i => 1;
          prefix0.int get j => 1;
        }
        augment class Foo12 {
          prefix0.int get i => 1;
          prefix0.int get j => 2;
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
          classAugmentations: {},
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
          results,
          (Identifier i) => (i as TestIdentifier).resolved,
          (OmittedTypeAnnotation i) =>
              (i as TestOmittedTypeAnnotation).inferredType);
      expect(library, equalsIgnoringWhitespace('''
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
        MacroExecutionResultImpl(classAugmentations: {}, libraryAugmentations: [
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
        ], newTypeNames: []),
      ];
      var library = _TestExecutor().buildAugmentationLibrary(
          results,
          (Identifier i) => (i as TestIdentifier).resolved,
          (OmittedTypeAnnotation i) =>
              (i as TestOmittedTypeAnnotation).inferredType);
      expect(library, equalsIgnoringWhitespace('''
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
          classAugmentations: {},
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
          results,
          (Identifier i) => (i as TestIdentifier).resolved,
          (OmittedTypeAnnotation i) =>
              (i as TestOmittedTypeAnnotation).inferredType,
          omittedTypes: omittedTypes);
      expect(library, equalsIgnoringWhitespace('''
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
  });
}

class _TestExecutor extends MacroExecutor
    with AugmentationLibraryBuilder, Fake {}
