// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:isolate';

import 'package:_macros/src/api.dart';
import 'package:_macros/src/bootstrap.dart';
import 'package:_macros/src/executor.dart';
import 'package:_macros/src/executor/isolated_executor.dart'
    as isolated_executor;
import 'package:_macros/src/executor/process_executor.dart' as process_executor
    show start;
import 'package:_macros/src/executor/process_executor.dart' hide start;
import 'package:_macros/src/executor/serialization.dart';
import 'package:test/test.dart';

import '../util.dart';

void main() {
  late MacroExecutor executor;
  late File kernelOutputFile;
  final danglingTaskMacroName = 'DanglingTaskMacro';
  final danglingTimerMacroName = 'DanglingTimerMacro';
  final danglingPeriodicTimerMacroName = 'DanglingPeriodicTimerMacro';
  final diagnosticMacroName = 'DiagnosticMacro';
  final simpleMacroName = 'SimpleMacro';
  late MacroInstanceIdentifier danglingTaskMacroId;
  late MacroInstanceIdentifier danglingTimerMacroId;
  late MacroInstanceIdentifier danglingPeriodicTimerMacroId;
  late MacroInstanceIdentifier diagnosticMacroInstanceId;
  late MacroInstanceIdentifier simpleMacroInstanceId;
  late Uri macroUri;
  late File simpleMacroFile;
  late Directory tmpDir;

  for (var executorKind in [
    'Isolated',
    'ProcessSocket',
    'ProcessStdio',
  ]) {
    group('$executorKind executor', () {
      for (var mode in [SerializationMode.byteData, SerializationMode.json]) {
        group('$mode', () {
          setUpAll(() async {
            simpleMacroFile =
                File(Platform.script.resolve('simple_macro.dart').toFilePath());
            tmpDir = Directory.systemTemp.createTempSync('executor_test');
            macroUri = simpleMacroFile.absolute.uri;

            var bootstrapContent = bootstrapMacroIsolate({
              macroUri.toString(): {
                simpleMacroName: ['', 'named'],
                danglingTaskMacroName: [''],
                danglingTimerMacroName: [''],
                danglingPeriodicTimerMacroName: [''],
                diagnosticMacroName: [''],
              }
            }, mode);
            var bootstrapFile =
                File(tmpDir.uri.resolve('main.dart').toFilePath())
                  ..writeAsStringSync(bootstrapContent);
            kernelOutputFile =
                File(tmpDir.uri.resolve('main.dart.dill').toFilePath());
            var packageConfigPath = (await Isolate.packageConfig)!.toFilePath();
            var buildSnapshotResult =
                await Process.run(Platform.resolvedExecutable, [
              if (executorKind == 'Isolated') ...[
                '--snapshot=${kernelOutputFile.uri.toFilePath()}',
                '--snapshot-kind=kernel',
              ] else ...[
                'compile',
                'exe',
                '-o',
                kernelOutputFile.uri.toFilePath(),
              ],
              '--packages=$packageConfigPath',
              bootstrapFile.uri.toFilePath(),
            ]);
            expect(buildSnapshotResult.exitCode, 0,
                reason: 'stdout: ${buildSnapshotResult.stdout}\n'
                    'stderr: ${buildSnapshotResult.stderr}');

            executor = executorKind == 'Isolated'
                ? await isolated_executor.start(mode, kernelOutputFile.uri)
                : executorKind == 'ProcessSocket'
                    ? await process_executor.start(mode,
                        CommunicationChannel.socket, kernelOutputFile.path)
                    : await process_executor.start(mode,
                        CommunicationChannel.stdio, kernelOutputFile.path);

            simpleMacroInstanceId = await executor.instantiateMacro(
                macroUri, simpleMacroName, '', Arguments([], {}));
            expect(simpleMacroInstanceId, isNotNull,
                reason: 'Can create an instance with no arguments.');
            executor.disposeMacro(simpleMacroInstanceId);

            simpleMacroInstanceId = await executor.instantiateMacro(
                macroUri, simpleMacroName, '', Arguments([IntArgument(1)], {}));
            expect(simpleMacroInstanceId, isNotNull,
                reason: 'Can create an instance with positional arguments.');
            executor.disposeMacro(simpleMacroInstanceId);

            simpleMacroInstanceId = await executor.instantiateMacro(
                macroUri,
                simpleMacroName,
                'named',
                Arguments([], {
                  'myBool': BoolArgument(true),
                  'myDouble': DoubleArgument(1.0),
                  'myInt': IntArgument(1),
                  'myList': ListArgument([
                    IntArgument(1),
                    IntArgument(2),
                    IntArgument(3),
                  ], [
                    ArgumentKind.nullable,
                    ArgumentKind.int
                  ]),
                  'mySet': SetArgument([
                    BoolArgument(true),
                    NullArgument(),
                    MapArgument({StringArgument('a'): DoubleArgument(1.0)},
                        [ArgumentKind.string, ArgumentKind.double]),
                  ], [
                    ArgumentKind.nullable,
                    ArgumentKind.object,
                  ]),
                  'myMap': MapArgument({
                    StringArgument('x'): IntArgument(1),
                  }, [
                    ArgumentKind.string,
                    ArgumentKind.int
                  ]),
                  'myString': StringArgument('a'),
                }));
            expect(simpleMacroInstanceId, isNotNull,
                reason: 'Can create an instance with named arguments.');

            danglingTaskMacroId = await executor.instantiateMacro(
                macroUri, danglingTaskMacroName, '', Arguments([], {}));
            expect(danglingTaskMacroId, isNotNull);

            danglingTimerMacroId = await executor.instantiateMacro(
                macroUri, danglingTimerMacroName, '', Arguments([], {}));
            expect(danglingTimerMacroId, isNotNull);

            danglingPeriodicTimerMacroId = await executor.instantiateMacro(
                macroUri,
                danglingPeriodicTimerMacroName,
                '',
                Arguments([], {}));
            expect(danglingPeriodicTimerMacroId, isNotNull);

            diagnosticMacroInstanceId = await executor.instantiateMacro(
                macroUri, diagnosticMacroName, '', Arguments([], {}));
            expect(diagnosticMacroInstanceId, isNotNull);
          });

          tearDownAll(() async {
            executor.disposeMacro(diagnosticMacroInstanceId);
            executor.disposeMacro(danglingTaskMacroId);
            executor.disposeMacro(danglingTimerMacroId);
            executor.disposeMacro(danglingPeriodicTimerMacroId);
            executor.disposeMacro(simpleMacroInstanceId);
            await expectLater(
                () => executor.executeTypesPhase(simpleMacroInstanceId,
                    Fixtures.myFunction, TestTypePhaseIntrospector()),
                throwsA(isA<UnexpectedMacroException>().having((e) => e.message,
                    'message', contains('Unrecognized macro instance'))),
                reason: 'Should be able to dispose macro instances',
                skip: 'https://github.com/dart-lang/sdk/issues/55992');
            if (tmpDir.existsSync()) {
              try {
                // Fails flakily on windows if a process still has the file open
                tmpDir.deleteSync(recursive: true);
              } catch (_) {}
            }
            await executor.close();
          });

          group('run macros', () {
            group('in the types phase', () {
              test('on functions', () async {
                var result = await executor.executeTypesPhase(
                    simpleMacroInstanceId,
                    Fixtures.myFunction,
                    TestTypePhaseIntrospector());
                expect(result.enumValueAugmentations, isEmpty);
                expect(result.interfaceAugmentations, isEmpty);
                expect(result.mixinAugmentations, isEmpty);
                expect(result.typeAugmentations, isEmpty);
                expect(
                    result.libraryAugmentations.single.debugString().toString(),
                    equalsIgnoringWhitespace('class GeneratedByMyFunction {}'));
              });

              test('on methods', () async {
                var result = await executor.executeTypesPhase(
                    simpleMacroInstanceId,
                    Fixtures.myMethod,
                    TestTypePhaseIntrospector());
                expect(result.enumValueAugmentations, isEmpty);
                expect(result.interfaceAugmentations, isEmpty);
                expect(result.mixinAugmentations, isEmpty);
                expect(result.typeAugmentations, isEmpty);
                expect(
                    result.libraryAugmentations.single.debugString().toString(),
                    equalsIgnoringWhitespace('class GeneratedByMyMethod {}'));
              });

              test('on getters', () async {
                var result = await executor.executeTypesPhase(
                    simpleMacroInstanceId,
                    Fixtures.myVariableGetter,
                    TestTypePhaseIntrospector());
                expect(result.enumValueAugmentations, isEmpty);
                expect(result.interfaceAugmentations, isEmpty);
                expect(result.mixinAugmentations, isEmpty);
                expect(result.typeAugmentations, isEmpty);
                expect(
                    result.libraryAugmentations.single.debugString().toString(),
                    equalsIgnoringWhitespace(
                        'class GeneratedByMyVariableGetter {}'));
              });

              test('on setters', () async {
                var result = await executor.executeTypesPhase(
                    simpleMacroInstanceId,
                    Fixtures.myVariableSetter,
                    TestTypePhaseIntrospector());
                expect(result.enumValueAugmentations, isEmpty);
                expect(result.interfaceAugmentations, isEmpty);
                expect(result.mixinAugmentations, isEmpty);
                expect(result.typeAugmentations, isEmpty);
                expect(
                    result.libraryAugmentations.single.debugString().toString(),
                    equalsIgnoringWhitespace(
                        'class GeneratedByMyVariableSetter {}'));
              });

              test('on variables', () async {
                var result = await executor.executeTypesPhase(
                    simpleMacroInstanceId,
                    Fixtures.myVariable,
                    TestTypePhaseIntrospector());
                expect(result.enumValueAugmentations, isEmpty);
                expect(result.interfaceAugmentations, isEmpty);
                expect(result.mixinAugmentations, isEmpty);
                expect(result.typeAugmentations, isEmpty);
                expect(
                    result.libraryAugmentations.single.debugString().toString(),
                    equalsIgnoringWhitespace(
                        'class GeneratedBy_myVariable {}'));
              });

              test('on constructors', () async {
                var result = await executor.executeTypesPhase(
                    simpleMacroInstanceId,
                    Fixtures.myConstructor,
                    TestTypePhaseIntrospector());
                expect(result.enumValueAugmentations, isEmpty);
                expect(result.interfaceAugmentations, isEmpty);
                expect(result.mixinAugmentations, isEmpty);
                expect(result.typeAugmentations, isEmpty);
                expect(
                    result.libraryAugmentations.single.debugString().toString(),
                    equalsIgnoringWhitespace(
                        'class GeneratedByMyConstructor {}'));
              });

              test('on fields', () async {
                var result = await executor.executeTypesPhase(
                    simpleMacroInstanceId,
                    Fixtures.myField,
                    TestTypePhaseIntrospector());
                expect(result.enumValueAugmentations, isEmpty);
                expect(result.interfaceAugmentations, isEmpty);
                expect(result.mixinAugmentations, isEmpty);
                expect(result.typeAugmentations, isEmpty);
                expect(
                    result.libraryAugmentations.single.debugString().toString(),
                    equalsIgnoringWhitespace('class GeneratedByMyField {}'));
              });

              test('on classes', () async {
                var result = await executor.executeTypesPhase(
                    simpleMacroInstanceId,
                    Fixtures.myClass,
                    TestTypePhaseIntrospector());
                expect(result.enumValueAugmentations, isEmpty);
                expect(
                    result
                        .extendsTypeAugmentations[Fixtures.myClass.identifier]!
                        .debugString()
                        .toString(),
                    equals(Fixtures.mySuperclass.identifier.name));
                expect(
                    result.interfaceAugmentations.mapValuesToDebugCodeString(),
                    equals({
                      Fixtures.myClass.identifier: ['HasX'],
                    }));
                expect(
                    result.mixinAugmentations.mapValuesToDebugCodeString(),
                    equals({
                      Fixtures.myClass.identifier: ['GetX'],
                    }));
                expect(result.typeAugmentations, isEmpty);
                expect(
                    result.libraryAugmentations.mapToDebugCodeString(),
                    unorderedEquals([
                      equalsIgnoringWhitespace(
                          'class MyClassBuilder implements Builder<MyClass> '
                          '{}'),
                      equalsIgnoringWhitespace('''mixin GetX implements HasX {
                              int get x => 1;
                            }'''),
                      equalsIgnoringWhitespace(
                          '''abstract interface class HasX {
                              int get x;
                            }'''),
                    ]));
              });

              test('on enums', () async {
                var result = await executor.executeTypesPhase(
                    simpleMacroInstanceId,
                    Fixtures.myEnum,
                    TestTypePhaseIntrospector());
                expect(result.enumValueAugmentations, isEmpty);
                expect(result.interfaceAugmentations, isEmpty);
                expect(result.mixinAugmentations, isEmpty);
                expect(result.typeAugmentations, isEmpty);
                expect(
                    result.libraryAugmentations.single.debugString().toString(),
                    equalsIgnoringWhitespace('class GeneratedByMyEnum {}'));
              });

              test('on enum values', () async {
                var result = await executor.executeTypesPhase(
                    simpleMacroInstanceId,
                    Fixtures.myEnumValues.first,
                    TestTypePhaseIntrospector());
                expect(result.enumValueAugmentations, isEmpty);
                expect(result.interfaceAugmentations, isEmpty);
                expect(result.mixinAugmentations, isEmpty);
                expect(result.typeAugmentations, isEmpty);
                expect(
                    result.libraryAugmentations.single.debugString().toString(),
                    equalsIgnoringWhitespace('class GeneratedByMyEnum_A {}'));
              });

              test('on extensions', () async {
                var result = await executor.executeTypesPhase(
                    simpleMacroInstanceId,
                    Fixtures.myExtension,
                    TestTypePhaseIntrospector());
                expect(result.enumValueAugmentations, isEmpty);
                expect(result.typeAugmentations, isEmpty);
                expect(
                    result.libraryAugmentations.single.debugString().toString(),
                    equalsIgnoringWhitespace('class MyExtensionOnMyClass {}'));
              });

              test('on extension types', () async {
                var result = await executor.executeTypesPhase(
                    simpleMacroInstanceId,
                    Fixtures.myExtensionType,
                    TestTypePhaseIntrospector());
                expect(result.enumValueAugmentations, isEmpty);
                expect(result.typeAugmentations, isEmpty);
                expect(
                    result.libraryAugmentations.single.debugString().toString(),
                    equalsIgnoringWhitespace(
                        'class MyExtensionTypeOnMyClass {}'));
              });

              test('on type aliases', () async {
                var result = await executor.executeTypesPhase(
                  simpleMacroInstanceId,
                  Fixtures.myTypeAlias,
                  TestTypePhaseIntrospector(),
                );
                expect(result.enumValueAugmentations, isEmpty);
                expect(result.typeAugmentations, isEmpty);
                expect(
                  result.libraryAugmentations.single.debugString().toString(),
                  equalsIgnoringWhitespace(
                    'class MyTypeAliasAliasedTypeMyClass {}',
                  ),
                );
              });

              test('on mixins', () async {
                var result = await executor.executeTypesPhase(
                    simpleMacroInstanceId,
                    Fixtures.myMixin,
                    TestTypePhaseIntrospector());
                expect(result.enumValueAugmentations, isEmpty);
                expect(result.interfaceAugmentations, isEmpty);
                expect(result.mixinAugmentations, isEmpty);
                expect(result.typeAugmentations, isEmpty);
                expect(
                    result.libraryAugmentations.single.debugString().toString(),
                    equalsIgnoringWhitespace(
                        'class GeneratedByMyMixinOnMyClass {}'));
              });

              test('on libraries', () async {
                var result = await executor.executeTypesPhase(
                  simpleMacroInstanceId,
                  Fixtures.library,
                  TestTypePhaseIntrospector(),
                );
                expect(result.enumValueAugmentations, isEmpty);
                expect(result.interfaceAugmentations, isEmpty);
                expect(result.mixinAugmentations, isEmpty);
                expect(result.typeAugmentations, isEmpty);
                expect(
                  result.libraryAugmentations.single.debugString().toString(),
                  equalsIgnoringWhitespace('''
class LibraryInfo {
  final Uri uri;
  final String languageVersion;
  final List<Type> definedTypes;
  const LibraryInfo(this.uri, this.languageVersion, this.definedTypes);
}
'''),
                );
              });

              test('Cannot leave dangling tasks', () async {
                expect(
                    () => executor.executeTypesPhase(danglingTaskMacroId,
                        Fixtures.library, TestTypePhaseIntrospector()),
                    throwsA(
                      isA<UnexpectedMacroException>().having((e) => e.message,
                          'message', contains('1 async tasks still pending')),
                    ));
              });

              test('Cannot leave dangling timers', () async {
                expect(
                    () => executor.executeTypesPhase(danglingTimerMacroId,
                        Fixtures.library, TestTypePhaseIntrospector()),
                    throwsA(
                      isA<UnexpectedMacroException>().having((e) => e.message,
                          'message', contains('1 active timers')),
                    ));

                expect(
                    () => executor.executeTypesPhase(
                        danglingPeriodicTimerMacroId,
                        Fixtures.library,
                        TestTypePhaseIntrospector()),
                    throwsA(
                      isA<UnexpectedMacroException>().having((e) => e.message,
                          'message', contains('1 active timers')),
                    ));
              });
            });

            group('in the declaration phase', () {
              test('on functions', () async {
                var result = await executor.executeDeclarationsPhase(
                    simpleMacroInstanceId,
                    Fixtures.myFunction,
                    Fixtures.testDeclarationPhaseIntrospector);
                expect(result.enumValueAugmentations, isEmpty);
                expect(result.interfaceAugmentations, isEmpty);
                expect(result.mixinAugmentations, isEmpty);
                expect(result.typeAugmentations, isEmpty);
                expect(
                    result.libraryAugmentations.single.debugString().toString(),
                    equalsIgnoringWhitespace(
                        'String delegateMyFunction() => myFunction();'));
              });

              test('on methods', () async {
                var result = await executor.executeDeclarationsPhase(
                    simpleMacroInstanceId,
                    Fixtures.myMethod,
                    Fixtures.testDeclarationPhaseIntrospector);
                expect(result.enumValueAugmentations, isEmpty);
                expect(result.interfaceAugmentations, isEmpty);
                expect(result.mixinAugmentations, isEmpty);
                expect(result.typeAugmentations, isEmpty);
                expect(
                    result.libraryAugmentations.single.debugString().toString(),
                    equalsIgnoringWhitespace(
                        '(String, bool? hello, {String world}) '
                        'delegateMemberMyMethod() => myMethod();'));
              });

              test('on constructors', () async {
                var result = await executor.executeDeclarationsPhase(
                    simpleMacroInstanceId,
                    Fixtures.myConstructor,
                    Fixtures.testDeclarationPhaseIntrospector);
                expect(result.enumValueAugmentations, isEmpty);
                expect(result.interfaceAugmentations, isEmpty);
                expect(result.mixinAugmentations, isEmpty);
                expect(result.typeAugmentations, hasLength(1));
                expect(
                    result
                        .typeAugmentations[Fixtures.myConstructor.definingType]!
                        .single
                        .debugString()
                        .toString(),
                    equalsIgnoringWhitespace('''
                factory MyClass.myConstructorDelegate() => MyClass.myConstructor();
              '''));
                expect(result.libraryAugmentations, isEmpty);
              });

              test('on getters', () async {
                var result = await executor.executeDeclarationsPhase(
                    simpleMacroInstanceId,
                    Fixtures.myVariableGetter,
                    Fixtures.testDeclarationPhaseIntrospector);
                expect(result.enumValueAugmentations, isEmpty);
                expect(result.interfaceAugmentations, isEmpty);
                expect(result.mixinAugmentations, isEmpty);
                expect(result.typeAugmentations, isEmpty);
                expect(
                    result.libraryAugmentations.single.debugString().toString(),
                    equalsIgnoringWhitespace('''
                String get delegateMyVariable => myVariable;'''));
              });

              test('on setters', () async {
                var result = await executor.executeDeclarationsPhase(
                    simpleMacroInstanceId,
                    Fixtures.myVariableSetter,
                    Fixtures.testDeclarationPhaseIntrospector);
                expect(result.enumValueAugmentations, isEmpty);
                expect(result.interfaceAugmentations, isEmpty);
                expect(result.mixinAugmentations, isEmpty);
                expect(result.typeAugmentations, isEmpty);
                expect(
                    result.libraryAugmentations.single.debugString().toString(),
                    equalsIgnoringWhitespace('''
                void set delegateMyVariable(String value) => myVariable = value;'''));
              });

              test('on variables', () async {
                var result = await executor.executeDeclarationsPhase(
                    simpleMacroInstanceId,
                    Fixtures.myVariable,
                    Fixtures.testDeclarationPhaseIntrospector);
                expect(result.enumValueAugmentations, isEmpty);
                expect(result.interfaceAugmentations, isEmpty);
                expect(result.mixinAugmentations, isEmpty);
                expect(result.typeAugmentations, isEmpty);
                expect(
                    result.libraryAugmentations.single.debugString().toString(),
                    equalsIgnoringWhitespace('''
                /*inferred*/String get delegate_myVariable => _myVariable;'''));
              });

              test('on fields', () async {
                var result = await executor.executeDeclarationsPhase(
                    simpleMacroInstanceId,
                    Fixtures.myField,
                    Fixtures.testDeclarationPhaseIntrospector);
                expect(result.enumValueAugmentations, isEmpty);
                expect(result.interfaceAugmentations, isEmpty);
                expect(result.mixinAugmentations, isEmpty);
                expect(result.typeAugmentations, hasLength(1));
                expect(
                    result.typeAugmentations[Fixtures.myField.definingType]!
                        .single
                        .debugString()
                        .toString(),
                    equalsIgnoringWhitespace('''
                String get delegateMyField => myField;
              '''));
                expect(result.libraryAugmentations, isEmpty);
              });

              test('on classes', () async {
                var result = await executor.executeDeclarationsPhase(
                    simpleMacroInstanceId,
                    Fixtures.myClass,
                    Fixtures.testDeclarationPhaseIntrospector);
                expect(result.enumValueAugmentations, isEmpty);
                expect(result.interfaceAugmentations, isEmpty);
                expect(result.mixinAugmentations, isEmpty);
                expect(result.typeAugmentations, hasLength(1));
                expect(
                    result
                        .typeAugmentations[Fixtures.myClass.identifier]!.single
                        .debugString()
                        .toString(),
                    equalsIgnoringWhitespace('''
                static const List<String> fieldNames = ['myField',];
              '''));
              });

              test('on enums', () async {
                var result = await executor.executeDeclarationsPhase(
                    simpleMacroInstanceId,
                    Fixtures.myEnum,
                    Fixtures.testDeclarationPhaseIntrospector);
                expect(result.enumValueAugmentations, isEmpty);
                expect(result.interfaceAugmentations, isEmpty);
                expect(result.mixinAugmentations, isEmpty);
                expect(result.typeAugmentations, hasLength(1));
                expect(
                    result.typeAugmentations[Fixtures.myEnum.identifier]!.single
                        .debugString()
                        .toString(),
                    equalsIgnoringWhitespace('''
                static const List<String> valuesByName = {'a': a};
              '''));
                expect(result.libraryAugmentations, isEmpty);
              });

              test('on enum values', () async {
                var result = await executor.executeDeclarationsPhase(
                    simpleMacroInstanceId,
                    Fixtures.myEnumValues.first,
                    Fixtures.testDeclarationPhaseIntrospector);
                expect(result.enumValueAugmentations, isEmpty);
                expect(result.interfaceAugmentations, isEmpty);
                expect(result.mixinAugmentations, isEmpty);
                expect(result.typeAugmentations, hasLength(1));
                expect(
                    result.typeAugmentations[Fixtures.myEnum.identifier]!.single
                        .debugString()
                        .toString(),
                    equalsIgnoringWhitespace('''
                MyEnum aToString() => a.toString();
              '''));
                expect(result.libraryAugmentations, isEmpty);
              });

              test('on extensions', () async {
                var result = await executor.executeDeclarationsPhase(
                    simpleMacroInstanceId,
                    Fixtures.myExtension,
                    Fixtures.testDeclarationPhaseIntrospector);
                expect(result.enumValueAugmentations, isEmpty);
                expect(result.typeAugmentations, hasLength(1));
                expect(
                    result.typeAugmentations[Fixtures.myExtension.identifier]!
                        .single
                        .debugString()
                        .toString(),
                    equalsIgnoringWhitespace('''
                List<String> get onTypeFieldNames;
              '''));
                expect(result.libraryAugmentations, isEmpty);
              });

              test('on extension types', () async {
                var result = await executor.executeDeclarationsPhase(
                    simpleMacroInstanceId,
                    Fixtures.myExtensionType,
                    Fixtures.testDeclarationPhaseIntrospector);
                expect(result.enumValueAugmentations, isEmpty);
                expect(result.typeAugmentations, hasLength(1));
                expect(
                    result
                        .typeAugmentations[Fixtures.myExtensionType.identifier]!
                        .single
                        .debugString()
                        .toString(),
                    equalsIgnoringWhitespace('''
                List<String> get onTypeFieldNames;
              '''));
                expect(result.libraryAugmentations, isEmpty);
              });

              test('on type aliases', () async {
                var result = await executor.executeDeclarationsPhase(
                  simpleMacroInstanceId,
                  Fixtures.myTypeAlias,
                  Fixtures.testDeclarationPhaseIntrospector,
                );
                expect(result.enumValueAugmentations, isEmpty);
                expect(result.libraryAugmentations, hasLength(1));
                expect(
                  result.libraryAugmentations.single.debugString().toString(),
                  equalsIgnoringWhitespace(
                    'List<String> get aliasedTypeFieldNames;',
                  ),
                );
                expect(result.typeAugmentations, isEmpty);
              });

              test('on mixins', () async {
                var result = await executor.executeDeclarationsPhase(
                    simpleMacroInstanceId,
                    Fixtures.myMixin,
                    Fixtures.testDeclarationPhaseIntrospector);
                expect(result.enumValueAugmentations, isEmpty);
                expect(result.interfaceAugmentations, isEmpty);
                expect(result.mixinAugmentations, isEmpty);
                expect(result.typeAugmentations, hasLength(1));
                expect(
                    result
                        .typeAugmentations[Fixtures.myMixin.identifier]!.single
                        .debugString()
                        .toString(),
                    equalsIgnoringWhitespace('''
                static const List<String> methodNames = ['myMixinMethod',];
              '''));
                expect(result.libraryAugmentations, isEmpty);
              });

              test('on libraries', () async {
                var result = await executor.executeDeclarationsPhase(
                    simpleMacroInstanceId,
                    Fixtures.library,
                    Fixtures.testDeclarationPhaseIntrospector);
                expect(result.enumValueAugmentations, isEmpty);
                expect(result.interfaceAugmentations, isEmpty);
                expect(result.mixinAugmentations, isEmpty);
                expect(result.typeAugmentations, isEmpty);
                expect(
                  result.libraryAugmentations.single.debugString().toString(),
                  equalsIgnoringWhitespace('final LibraryInfo library;'),
                );
              });

              test('Cannot leave dangling tasks', () async {
                expect(
                    () => executor.executeDeclarationsPhase(
                        danglingTaskMacroId,
                        Fixtures.library,
                        Fixtures.testDeclarationPhaseIntrospector),
                    throwsA(
                      isA<UnexpectedMacroException>().having((e) => e.message,
                          'message', contains('1 async tasks still pending')),
                    ));
              });

              test('Cannot leave dangling timers', () async {
                expect(
                    () => executor.executeDeclarationsPhase(
                        danglingTimerMacroId,
                        Fixtures.library,
                        Fixtures.testDeclarationPhaseIntrospector),
                    throwsA(
                      isA<UnexpectedMacroException>().having((e) => e.message,
                          'message', contains('1 active timers')),
                    ));

                expect(
                    () => executor.executeDeclarationsPhase(
                        danglingPeriodicTimerMacroId,
                        Fixtures.library,
                        Fixtures.testDeclarationPhaseIntrospector),
                    throwsA(
                      isA<UnexpectedMacroException>().having((e) => e.message,
                          'message', contains('1 active timers')),
                    ));
              });
            });

            group('in the definition phase', () {
              test('on functions', () async {
                var result = await executor.executeDefinitionsPhase(
                    simpleMacroInstanceId,
                    Fixtures.myFunction,
                    Fixtures.testDefinitionPhaseIntrospector);
                expect(result.enumValueAugmentations, isEmpty);
                expect(result.interfaceAugmentations, isEmpty);
                expect(result.mixinAugmentations, isEmpty);
                expect(result.typeAugmentations, isEmpty);
                expect(
                    result.libraryAugmentations.single.debugString().toString(),
                    equalsIgnoringWhitespace('''
                // A comment!
                augment String myFunction() {
                  print('isExternal: false');
                  print('isGetter: false');
                  print('isSetter: false');
                  print('returnType: String');
                  return augmented();
                }'''));
              });

              test('on methods', () async {
                var definitionResult = await executor.executeDefinitionsPhase(
                    simpleMacroInstanceId,
                    Fixtures.myMethod,
                    Fixtures.testDefinitionPhaseIntrospector);
                expect(definitionResult.enumValueAugmentations, isEmpty);
                expect(definitionResult.interfaceAugmentations, isEmpty);
                expect(definitionResult.mixinAugmentations, isEmpty);
                expect(definitionResult.typeAugmentations, hasLength(1));
                var augmentationStrings = definitionResult
                    .typeAugmentations[Fixtures.myMethod.definingType]!
                    .mapToDebugCodeString();
                expect(augmentationStrings,
                    unorderedEquals(methodDefinitionMatchers));
                expect(definitionResult.libraryAugmentations, isEmpty);
              });

              test('on constructors', () async {
                var definitionResult = await executor.executeDefinitionsPhase(
                    simpleMacroInstanceId,
                    Fixtures.myConstructor,
                    Fixtures.testDefinitionPhaseIntrospector);
                expect(definitionResult.enumValueAugmentations, isEmpty);
                expect(definitionResult.interfaceAugmentations, isEmpty);
                expect(definitionResult.mixinAugmentations, isEmpty);
                expect(definitionResult.typeAugmentations, hasLength(1));
                expect(
                    definitionResult
                        .typeAugmentations[Fixtures.myConstructor.definingType]!
                        .first
                        .debugString()
                        .toString(),
                    constructorDefinitionMatcher);
                expect(definitionResult.libraryAugmentations, isEmpty);
              });

              test('on getters', () async {
                var result = await executor.executeDefinitionsPhase(
                    simpleMacroInstanceId,
                    Fixtures.myVariableGetter,
                    Fixtures.testDefinitionPhaseIntrospector);
                expect(result.enumValueAugmentations, isEmpty);
                expect(result.interfaceAugmentations, isEmpty);
                expect(result.mixinAugmentations, isEmpty);
                expect(result.typeAugmentations, isEmpty);
                expect(
                    result.libraryAugmentations.single.debugString().toString(),
                    equalsIgnoringWhitespace('''
                // A comment!
                augment String get myVariable {
                  print('isExternal: false');
                  print('isGetter: true');
                  print('isSetter: false');
                  print('returnType: String');
                  return augmented;
                }'''));
              });

              test('on setters', () async {
                var result = await executor.executeDefinitionsPhase(
                    simpleMacroInstanceId,
                    Fixtures.myVariableSetter,
                    Fixtures.testDefinitionPhaseIntrospector);
                expect(result.enumValueAugmentations, isEmpty);
                expect(result.interfaceAugmentations, isEmpty);
                expect(result.mixinAugmentations, isEmpty);
                expect(result.typeAugmentations, isEmpty);
                expect(
                    result.libraryAugmentations.single.debugString().toString(),
                    equalsIgnoringWhitespace('''
                // A comment!
                augment void set myVariable(String value, ) {
                  print('isExternal: false');
                  print('isGetter: false');
                  print('isSetter: true');
                  print('returnType: void');
                  print('positionalParam: String value');
                  return augmented = value;
                }'''));
              });

              test('on variables', () async {
                var result = await executor.executeDefinitionsPhase(
                    simpleMacroInstanceId,
                    Fixtures.myVariable,
                    Fixtures.testDefinitionPhaseIntrospector);
                expect(result.enumValueAugmentations, isEmpty);
                expect(result.interfaceAugmentations, isEmpty);
                expect(result.mixinAugmentations, isEmpty);
                expect(result.typeAugmentations, isEmpty);
                expect(
                    result.libraryAugmentations.mapToDebugCodeString(),
                    unorderedEquals([
                      equalsIgnoringWhitespace('''
                augment /*inferred*/String get _myVariable {
                  print('parentClass: ');
                  print('isExternal: false');
                  print('isFinal: true');
                  print('isLate: false');
                  return augmented;
                }'''),
                      equalsIgnoringWhitespace('''
                augment set _myVariable(/*inferred*/String value) {
                  augmented = value;
                }'''),
                      equalsIgnoringWhitespace('''
                augment final /*inferred*/String _myVariable = 'new initial value' + augmented;
                '''),
                    ]));
              });

              test('on fields', () async {
                var definitionResult = await executor.executeDefinitionsPhase(
                    simpleMacroInstanceId,
                    Fixtures.myField,
                    Fixtures.testDefinitionPhaseIntrospector);
                expect(definitionResult.enumValueAugmentations, isEmpty);
                expect(definitionResult.interfaceAugmentations, isEmpty);
                expect(definitionResult.mixinAugmentations, isEmpty);
                expect(definitionResult.typeAugmentations, hasLength(1));
                expect(
                    definitionResult
                        .typeAugmentations[Fixtures.myField.definingType]!
                        .mapToDebugCodeString(),
                    unorderedEquals(fieldDefinitionMatchers));
                expect(definitionResult.libraryAugmentations, isEmpty);
              });

              test('on classes', () async {
                var definitionResult = await executor.executeDefinitionsPhase(
                    simpleMacroInstanceId,
                    Fixtures.myClass,
                    Fixtures.testDefinitionPhaseIntrospector);
                expect(definitionResult.enumValueAugmentations, isEmpty);
                expect(definitionResult.interfaceAugmentations, isEmpty);
                expect(definitionResult.mixinAugmentations, isEmpty);
                expect(definitionResult.typeAugmentations, hasLength(1));
                var augmentationStrings = definitionResult
                    .typeAugmentations[Fixtures.myClass.identifier]!
                    .mapToDebugCodeString();
                expect(
                    augmentationStrings,
                    unorderedEquals([
                      ...methodDefinitionMatchers,
                      constructorDefinitionMatcher,
                      ...fieldDefinitionMatchers,
                    ]));
              });

              test('on enums', () async {
                var definitionResult = await executor.executeDefinitionsPhase(
                    simpleMacroInstanceId,
                    Fixtures.myEnum,
                    Fixtures.testDefinitionPhaseIntrospector);
                expect(definitionResult.enumValueAugmentations, hasLength(1));
                var entryAugmentationStrings = definitionResult
                    .enumValueAugmentations[Fixtures.myEnum.identifier]!
                    .mapToDebugCodeString()
                    .toList();
                expect(entryAugmentationStrings,
                    unorderedEquals(["a('myField', ),"]));
                expect(definitionResult.interfaceAugmentations, isEmpty);
                expect(definitionResult.mixinAugmentations, isEmpty);
                expect(definitionResult.typeAugmentations, hasLength(1));
                var typeAugmentationStrings = definitionResult
                    .typeAugmentations[Fixtures.myEnum.identifier]!
                    .mapToDebugCodeString();
                expect(
                    typeAugmentationStrings,
                    unorderedEquals([
                      equalsIgnoringWhitespace('''
                        augment MyEnum.myEnumConstructor(String myField, ) {
                          print('definingClass: MyEnum');
                          print('isFactory: false');
                          print('isExternal: false');
                          print('isGetter: false');
                          print('isSetter: false');
                          print('returnType: MyEnum');
                          print('positionalParam: String myField');
                          return augmented();
                        }''')
                    ]));
              });

              test('on enum values', () async {
                var definitionResult = await executor.executeDefinitionsPhase(
                    simpleMacroInstanceId,
                    Fixtures.myEnumValues.first,
                    Fixtures.testDefinitionPhaseIntrospector);
                expect(definitionResult.enumValueAugmentations, hasLength(1));
                expect(definitionResult.interfaceAugmentations, isEmpty);
                expect(definitionResult.mixinAugmentations, isEmpty);
                var augmentationStrings = definitionResult
                    .enumValueAugmentations[Fixtures.myEnum.identifier]!
                    .mapToDebugCodeString();
                expect(
                    augmentationStrings, unorderedEquals(["a('myField', ),"]));
                expect(definitionResult.typeAugmentations, isEmpty);
              });

              test('on extensions', () async {
                var definitionResult = await executor.executeDefinitionsPhase(
                    simpleMacroInstanceId,
                    Fixtures.myExtension,
                    Fixtures.testDefinitionPhaseIntrospector);
                expect(definitionResult.enumValueAugmentations, isEmpty);
                expect(definitionResult.typeAugmentations, hasLength(1));
                expect(
                    definitionResult
                        .typeAugmentations[Fixtures.myExtension.identifier]!
                        .single
                        .debugString()
                        .toString(),
                    equalsIgnoringWhitespace(
                        "augment List<String> get onTypeFieldNames => "
                        "['myField',];"));
              });

              test('on extension types', () async {
                var definitionResult = await executor.executeDefinitionsPhase(
                    simpleMacroInstanceId,
                    Fixtures.myExtensionType,
                    Fixtures.testDefinitionPhaseIntrospector);
                expect(definitionResult.enumValueAugmentations, isEmpty);
                expect(definitionResult.typeAugmentations, hasLength(1));
                expect(
                    definitionResult
                        .typeAugmentations[Fixtures.myExtensionType.identifier]!
                        .single
                        .debugString()
                        .toString(),
                    equalsIgnoringWhitespace(
                        "augment List<String> get onTypeFieldNames => "
                        "['myField',];"));
              });

              test('on mixins', () async {
                var definitionResult = await executor.executeDefinitionsPhase(
                    simpleMacroInstanceId,
                    Fixtures.myMixin,
                    Fixtures.testDefinitionPhaseIntrospector);
                expect(definitionResult.enumValueAugmentations, isEmpty);
                expect(definitionResult.interfaceAugmentations, isEmpty);
                expect(definitionResult.mixinAugmentations, isEmpty);
                expect(definitionResult.typeAugmentations, hasLength(1));
                var augmentationStrings = definitionResult
                    .typeAugmentations[Fixtures.myMixin.identifier]!
                    .mapToDebugCodeString();
                expect(
                    augmentationStrings,
                    unorderedEquals(
                      mixinMethodDefinitionMatchers,
                    ));
              });

              test('on libraries', () async {
                var result = await executor.executeDefinitionsPhase(
                    simpleMacroInstanceId,
                    Fixtures.library,
                    Fixtures.testDefinitionPhaseIntrospector);
                expect(result.enumValueAugmentations, isEmpty);
                expect(result.interfaceAugmentations, isEmpty);
                expect(result.mixinAugmentations, isEmpty);
                expect(result.typeAugmentations, isEmpty);
                expect(
                    result.libraryAugmentations.single.debugString().toString(),
                    equalsIgnoringWhitespace('''
augment final LibraryInfo library = LibraryInfo(Uri.parse('package:foo/bar.dart'), '3.0', [MyClass, MyEnum, MyMixin, ]);
'''));
              });

              test('Cannot leave dangling tasks', () async {
                expect(
                    () => executor.executeDefinitionsPhase(
                        danglingTaskMacroId,
                        Fixtures.library,
                        Fixtures.testDefinitionPhaseIntrospector),
                    throwsA(
                      isA<UnexpectedMacroException>().having((e) => e.message,
                          'message', contains('1 async tasks still pending')),
                    ));
              });

              test('Cannot leave dangling timers', () async {
                expect(
                    () => executor.executeDefinitionsPhase(
                        danglingTimerMacroId,
                        Fixtures.library,
                        Fixtures.testDefinitionPhaseIntrospector),
                    throwsA(
                      isA<UnexpectedMacroException>().having((e) => e.message,
                          'message', contains('1 active timers')),
                    ));

                expect(
                    () => executor.executeDefinitionsPhase(
                        danglingPeriodicTimerMacroId,
                        Fixtures.library,
                        Fixtures.testDefinitionPhaseIntrospector),
                    throwsA(
                      isA<UnexpectedMacroException>().having((e) => e.message,
                          'message', contains('1 active timers')),
                    ));
              });
            });

            test('and report diagnostics', () async {
              final result = await executor.executeTypesPhase(
                  diagnosticMacroInstanceId,
                  Fixtures.myClass,
                  TestTypePhaseIntrospector());
              expect(result.diagnostics, [
                predicate<Diagnostic>((d) =>
                    d.severity == Severity.info &&
                    d.message.message == 'superclass' &&
                    (d.message.target as TypeAnnotationDiagnosticTarget)
                            .typeAnnotation ==
                        Fixtures.mySuperclassType &&
                    d.contextMessages.single.message == 'interface' &&
                    (d.contextMessages.single.target
                                as TypeAnnotationDiagnosticTarget)
                            .typeAnnotation ==
                        Fixtures.myInterfaceType &&
                    d.correctionMessage == 'correct me!'),
                predicate<Diagnostic>((d) =>
                    d.severity == Severity.error &&
                    d.message.message.contains('bug in the macro') &&
                    // Quick test that some stack trace also appears
                    d.contextMessages.first.message
                        .contains('simple_macro.dart')),
              ]);
            });
          });
        });
      }
    });
  }
}

final constructorDefinitionMatcher = equalsIgnoringWhitespace('''
augment MyClass.myConstructor(/*inferred*/String myField, ) {
  print('definingClass: MyClass');
  print('isFactory: false');
  print('isExternal: false');
  print('isGetter: false');
  print('isSetter: false');
  print('returnType: MyClass');
  print('positionalParam: String (inferred) myField');
  return augmented();
}''');

final fieldDefinitionMatchers = [
  equalsIgnoringWhitespace('''
    augment String get myField {
      print('parentClass: MyClass');
      print('isAbstract: false');
      print('isExternal: false');
      print('isFinal: false');
      print('isLate: false');
      return augmented;
    }'''),
  equalsIgnoringWhitespace('''
    augment set myField(String value) {
      augmented = value;
    }'''),
  equalsIgnoringWhitespace('''
    augment String myField = 'new initial value' + augmented;'''),
];

final methodDefinitionMatchers = [
  equalsIgnoringWhitespace('''
    // A comment!
    augment (String, bool? hello, {String world}) myMethod() {
      print('definingClass: MyClass');
      print('isExternal: false');
      print('isGetter: false');
      print('isSetter: false');
      print('returnType: (String, bool? hello, {String world})');
      return augmented();
    }'''),
  equalsIgnoringWhitespace('''
    augment (String, bool? hello, {String world}) myMethod() {
      print('myBool: true');
      print('myDouble: 1.0');
      print('myInt: 1');
      print('myList: [1, 2, 3]');
      print('mySet: {true, null, {a: 1.0}}');
      print('myMap: {x: 1}');
      print('myString: a');
      print('parentClass: MyClass');
      print('superClass: MySuperclass');
      print('interface: MyInterface');
      print('mixin: MyMixin');
      print('field: myField');
      print('method: myMethod');
      print('constructor: myConstructor');
      return augmented();
    }'''),
];

final mixinMethodDefinitionMatchers = [
  equalsIgnoringWhitespace('''
    // A comment!
    augment (String, bool? hello, {String world}) myMixinMethod() {
      print('definingClass: MyMixin');
      print('isExternal: false');
      print('isGetter: false');
      print('isSetter: false');
      print('returnType: (String, bool? hello, {String world})');
      return augmented();
    }'''),
  equalsIgnoringWhitespace('''
    augment (String, bool? hello, {String world}) myMixinMethod() {
      print('myBool: true');
      print('myDouble: 1.0');
      print('myInt: 1');
      print('myList: [1, 2, 3]');
      print('mySet: {true, null, {a: 1.0}}');
      print('myMap: {x: 1}');
      print('myString: a');
      print('parentClass: MyMixin');
      print('superClass: null');
      print('method: myMixinMethod');
      return augmented();
    }'''),
];
