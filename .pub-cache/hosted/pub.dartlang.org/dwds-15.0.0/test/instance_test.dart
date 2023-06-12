// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'package:dwds/src/connections/debug_connection.dart';
import 'package:dwds/src/debugging/debugger.dart';
import 'package:dwds/src/debugging/inspector.dart';
import 'package:dwds/src/debugging/instance.dart';
import 'package:dwds/src/loaders/strategy.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

import 'fixtures/context.dart';

final context = TestContext(
    directory: '../example', path: 'scopes.html', pathToServe: 'web');

WipConnection get tabConnection => context.tabConnection;

void main() {
  AppInspector inspector;
  Debugger debugger;
  InstanceHelper instanceHelper;

  setUpAll(() async {
    await context.setUp();
    final chromeProxyService = fetchChromeProxyService(context.debugConnection);
    inspector = chromeProxyService.appInspectorProvider();
    debugger = inspector.debugger;
    instanceHelper = inspector.instanceHelper;
  });

  tearDownAll(() async {
    await context.tearDown();
  });

  final url = 'org-dartlang-app:///web/scopes_main.dart';

  String libraryVariableExpression(String variable) =>
      '${globalLoadStrategy.loadModuleSnippet}("dart_sdk").dart.getModuleLibraries("web/scopes_main")'
      '["$url"]["$variable"];';

  /// A reference to the the variable `libraryPublicFinal`, an instance of
  /// `MyTestClass`.
  Future<RemoteObject> libraryPublicFinal() =>
      inspector.jsEvaluate(libraryVariableExpression('libraryPublicFinal'));

  /// A reference to the the variable `libraryPublic`, a List of Strings.
  Future<RemoteObject> libraryPublic() =>
      inspector.jsEvaluate(libraryVariableExpression('libraryPublic'));

  group('instanceRef', () {
    test('for a null', () async {
      final remoteObject = await libraryPublicFinal();
      final nullVariable = await inspector.loadField(remoteObject, 'notFinal');
      final ref = await instanceHelper.instanceRefFor(nullVariable);
      expect(ref.valueAsString, 'null');
      expect(ref.kind, InstanceKind.kNull);
      final classRef = ref.classRef;
      expect(classRef.name, 'Null');
      expect(classRef.id, 'classes|dart:core|Null');
    });

    test('for a double', () async {
      final remoteObject = await libraryPublicFinal();
      final count = await inspector.loadField(remoteObject, 'count');
      final ref = await instanceHelper.instanceRefFor(count);
      expect(ref.valueAsString, '0');
      expect(ref.kind, InstanceKind.kDouble);
      final classRef = ref.classRef;
      expect(classRef.name, 'Double');
      expect(classRef.id, 'classes|dart:core|Double');
    });

    test('for a class', () async {
      final remoteObject = await libraryPublicFinal();
      final count = await inspector.loadField(remoteObject, 'myselfField');
      final ref = await instanceHelper.instanceRefFor(count);
      expect(ref.kind, InstanceKind.kPlainInstance);
      final classRef = ref.classRef;
      expect(classRef.name, 'MyTestClass<dynamic>');
      expect(
          classRef.id,
          'classes|org-dartlang-app:///web/scopes_main.dart'
          '|MyTestClass<dynamic>');
    });

    test('for closure', () async {
      final remoteObject = await libraryPublicFinal();
      final properties = await debugger.getProperties(remoteObject.objectId);
      final closure =
          properties.firstWhere((property) => property.name == 'closure');
      final instanceRef = await instanceHelper.instanceRefFor(closure.value);
      final functionName = instanceRef.closureFunction.name;
      // Older SDKs do not contain function names
      if (functionName != 'Closure') {
        expect(functionName, 'someFunction');
      }
      expect(instanceRef.kind, InstanceKind.kClosure);
    });

    test('for a list', () async {
      final remoteObject = await libraryPublic();
      final ref = await instanceHelper.instanceRefFor(remoteObject);
      expect(ref.length, greaterThan(0));
      expect(ref.kind, InstanceKind.kList);
      expect(ref.classRef.name, 'List<String>');
    });

    test('for map', () async {
      final remoteObject =
          await inspector.jsEvaluate(libraryVariableExpression('map'));
      final ref = await instanceHelper.instanceRefFor(remoteObject);
      expect(ref.length, 2);
      expect(ref.kind, InstanceKind.kMap);
      expect(ref.classRef.name, 'LinkedMap<Object, Object>');
    });

    test('for an IdentityMap', () async {
      final remoteObject =
          await inspector.jsEvaluate(libraryVariableExpression('identityMap'));
      final ref = await instanceHelper.instanceRefFor(remoteObject);
      expect(ref.length, 2);
      expect(ref.kind, InstanceKind.kMap);
      expect(ref.classRef.name, 'IdentityMap<String, int>');
    });
  });

  group('instance', () {
    test('for class object', () async {
      final remoteObject = await libraryPublicFinal();
      final instance = await instanceHelper.instanceFor(remoteObject);
      expect(instance.kind, InstanceKind.kPlainInstance);
      final classRef = instance.classRef;
      expect(classRef, isNotNull);
      expect(classRef.name, 'MyTestClass<dynamic>');
      final fieldNames =
          instance.fields.map((boundField) => boundField.decl.name).toList();
      expect(fieldNames, [
        '_privateField',
        'abstractField',
        'closure',
        'count',
        'message',
        'myselfField',
        'notFinal',
        'tornOff',
      ]);
      for (var field in instance.fields) {
        expect(field.decl.declaredType, isNotNull);
      }
    });

    test('for closure', () async {
      final remoteObject = await libraryPublicFinal();
      final properties = await debugger.getProperties(remoteObject.objectId);
      final closure =
          properties.firstWhere((property) => property.name == 'closure');
      final instance = await instanceHelper.instanceFor(closure.value);
      expect(instance.kind, InstanceKind.kClosure);
      expect(instance.classRef.name, 'Closure');
    });

    test('for a nested class', () async {
      final libraryRemoteObject = await libraryPublicFinal();
      final fieldRemoteObject =
          await inspector.loadField(libraryRemoteObject, 'myselfField');
      final instance = await instanceHelper.instanceFor(fieldRemoteObject);
      expect(instance.kind, InstanceKind.kPlainInstance);
      final classRef = instance.classRef;
      expect(classRef, isNotNull);
      expect(classRef.name, 'MyTestClass<dynamic>');
    });

    test('for a list', () async {
      final remote = await libraryPublic();
      final instance = await instanceHelper.instanceFor(remote);
      expect(instance.kind, InstanceKind.kList);
      final classRef = instance.classRef;
      expect(classRef, isNotNull);
      expect(classRef.name, 'List<String>');
      final first = instance.elements[0];
      expect(first.valueAsString, 'library');
    });

    test('for a map', () async {
      final remote =
          await inspector.jsEvaluate(libraryVariableExpression('map'));
      final instance = await instanceHelper.instanceFor(remote);
      expect(instance.kind, InstanceKind.kMap);
      final classRef = instance.classRef;
      expect(classRef.name, 'LinkedMap<Object, Object>');
      final first = instance.associations[0].value as InstanceRef;
      expect(first.kind, InstanceKind.kList);
      expect(first.length, 3);
      final second = instance.associations[1].value as InstanceRef;
      expect(second.kind, InstanceKind.kString);
      expect(second.valueAsString, 'something');
    });

    test('for an identityMap', () async {
      final remote =
          await inspector.jsEvaluate(libraryVariableExpression('identityMap'));
      final instance = await instanceHelper.instanceFor(remote);
      expect(instance.kind, InstanceKind.kMap);
      final classRef = instance.classRef;
      expect(classRef.name, 'IdentityMap<String, int>');
      final first = instance.associations[0].value;
      expect(first.valueAsString, '1');
    });

    test('for a class that implements List', () async {
      // The VM only uses kind List for SDK lists, and we follow that.
      final remote =
          await inspector.jsEvaluate(libraryVariableExpression('notAList'));
      final instance = await instanceHelper.instanceFor(remote);
      expect(instance.kind, InstanceKind.kPlainInstance);
      final classRef = instance.classRef;
      expect(classRef.name, 'NotReallyAList');
      expect(instance.elements, isNull);
      final field = instance.fields.first;
      expect(field.decl.name, '_internal');
    });
  });
}
