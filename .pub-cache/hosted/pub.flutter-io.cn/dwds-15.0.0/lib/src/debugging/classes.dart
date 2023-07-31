// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.import 'dart:async';

// @dart = 2.9

import 'package:vm_service/vm_service.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

import '../../src/services/chrome_debug_exception.dart';
import '../loaders/strategy.dart';
import '../utilities/domain.dart';
import '../utilities/shared.dart';
import 'inspector.dart';
import 'metadata/class.dart';

/// A hard-coded ClassRef for the Closure class.
final classRefForClosure = classRefFor('dart:core', 'Closure');

/// A hard-coded ClassRef for the String class.
final classRefForString = classRefFor('dart:core', InstanceKind.kString);

/// A hard-coded ClassRef for a (non-existent) class called Unknown.
final classRefForUnknown = classRefFor('dart:core', 'Unknown');

/// Returns a [ClassRef] for the provided library ID and class name.
ClassRef classRefFor(String libraryId, String name) => ClassRef(
    id: 'classes|$libraryId|$name',
    name: name,
    library: LibraryRef(id: libraryId, name: libraryId, uri: libraryId));

/// Keeps track of Dart classes available in the running application.
class ClassHelper extends Domain {
  /// Map of class ID to [Class].
  final _classes = <String, Class>{};

  ClassHelper(AppInspector Function() provider) : super(provider) {
    final staticClasses = [
      classRefForClosure,
      classRefForString,
      classRefForUnknown
    ];
    for (var classRef in staticClasses) {
      _classes[classRef.id] = Class(
          name: classRef.name,
          isAbstract: false,
          isConst: false,
          library: null,
          interfaces: [],
          fields: [],
          functions: [],
          subclasses: [],
          id: classRef.id,
          traceAllocations: false);
    }
  }

  /// Returns the [Class] that corresponds to the provided [objectId].
  ///
  /// If a corresponding class does not exist it will return null.
  Future<Class> forObjectId(String objectId) async {
    if (!objectId.startsWith('classes|')) return null;
    var clazz = _classes[objectId];
    if (clazz != null) return clazz;
    final splitId = objectId.split('|');
    final libraryId = splitId[1];
    if (libraryId == 'null') {
      throw UnsupportedError('unknown library: $libraryId');
    }
    final libraryRef = await inspector.libraryHelper.libraryRefFor(libraryId);
    if (libraryRef == null) {
      throw Exception('Could not find library: $libraryId');
    }
    final classRef = classRefFor(libraryId, splitId.last);
    clazz = await _constructClass(libraryRef, classRef);
    if (clazz == null) {
      throw Exception('Could not contruct class: $classRef');
    }
    return _classes[objectId] = clazz;
  }

  /// Constructs a [Class] instance for the provided [LibraryRef] and
  /// [ClassRef].
  Future<Class> _constructClass(
      LibraryRef libraryRef, ClassRef classRef) async {
    final rawName = classRef.name.split('<').first;
    final expression = '''
    (function() {
      ${globalLoadStrategy.loadLibrarySnippet(libraryRef.uri)}
      var result = {};
      var clazz = library["$rawName"];
      var descriptor = {
          'name': clazz.name,
          'dartName': sdkUtils.typeName(clazz)
        };

      // TODO(grouma) - we display all inherited methods since we don't provide
      // the superClass information. This is technically not correct.
      var proto = clazz.prototype;
      var methodNames = [];
      for (; proto != null; proto = Object.getPrototypeOf(proto)) {
        var methods = Object.getOwnPropertyNames(proto);
        for (var i = 0; i < methods.length; i++) {
          if (methodNames.indexOf(methods[i]) == -1
              && methods[i] != 'constructor') {
              methodNames.push(methods[i]);
          }
        }
        if (proto.constructor.name == 'Object') break;
      }

      descriptor['methods'] = {};
      for (var name of methodNames) {
        descriptor['methods'][name] = {
          // TODO(jakemac): how can we get actual const info?
          "isConst": false,
          "isStatic": false,
        }
      }

      var fields = sdkUtils.getFields(clazz);
      var fieldNames = fields ? Object.keys(fields) : [];
      descriptor['fields'] = {};
      for (var name of fieldNames) {
        var field = fields[name];
        var libraryUri = Object.getOwnPropertySymbols(fields[name]["type"])
        .find(x => x.description == "libraryUri");
        descriptor['fields'][name] = {
          // TODO(jakemac): how can we get actual const info?
          "isConst": false,
          "isFinal": field.isFinal,
          "isStatic": false,
          "classRefName": fields[name]["type"]["name"],
          "classRefDartName": sdkUtils.typeName(fields[name]["type"]),
          "classRefLibraryId" : field["type"][libraryUri],
        }
      }

      // TODO(elliette): The following static member information is minimal and 
      // should be replaced once DDC provides full symbol information (see 
      // https://github.com/dart-lang/sdk/issues/40273):

      descriptor['staticFields'] = {};
      var staticFieldNames = sdkUtils.getStaticFields(clazz) ?? [];
      for (const name of staticFieldNames) {
        descriptor['staticFields'][name] = {
          "isStatic": true,
          // DDC only provides names of static members, we set isConst/isFinal 
          // to false even though they could be true.
          "isConst": false,
          "isFinal": false,
        }
      }

      descriptor['staticMethods'] = {};
      var staticMethodNames = sdkUtils.getStaticMethods(clazz) ?? [];
      for (var name of staticMethodNames) {
        descriptor['methods'][name] = {
          // DDC only provides names of static members, we set isConst
          // to false even though it could be true.
          "isConst": false,
          "isStatic": true,
        } 
      }

      return descriptor;
    })()
    ''';

    RemoteObject result;
    try {
      result = await inspector.remoteDebugger.evaluate(
        expression,
        returnByValue: true,
        contextId: await inspector.contextId,
      );
    } on ExceptionDetails catch (e) {
      throw ChromeDebugException(e.json, evalContents: expression);
    }

    final classDescriptor = result.value as Map<String, dynamic>;
    final methodRefs = <FuncRef>[];
    final methodDescriptors =
        classDescriptor['methods'] as Map<String, dynamic>;
    final staticMethodDescriptors =
        classDescriptor['staticMethods'] as Map<String, dynamic>;
    methodDescriptors.addAll(staticMethodDescriptors);
    methodDescriptors.forEach((name, descriptor) {
      final methodId = 'methods|${classRef.id}|$name';
      methodRefs.add(FuncRef(
          id: methodId,
          name: name,
          owner: classRef,
          isConst: descriptor['isConst'] as bool,
          isStatic: descriptor['isStatic'] as bool,
          // TODO(annagrin): get information about getters and setters from symbols.
          // https://github.com/dart-lang/sdk/issues/46723
          implicit: false));
    });
    final fieldRefs = <FieldRef>[];
    final fieldDescriptors = classDescriptor['fields'] as Map<String, dynamic>;
    fieldDescriptors.forEach((name, descriptor) async {
      final classMetaData = ClassMetaData(
          jsName: descriptor['classRefName'],
          libraryId: descriptor['classRefLibraryId'],
          dartName: descriptor['classRefDartName']);
      fieldRefs.add(FieldRef(
          name: name,
          owner: classRef,
          declaredType: InstanceRef(
            identityHashCode: createId().hashCode,
            id: createId(),
            kind: InstanceKind.kType,
            // TODO(elliette): Is this the same as classRef?
            classRef: classMetaData.classRef,
          ),
          isConst: descriptor['isConst'] as bool,
          isFinal: descriptor['isFinal'] as bool,
          isStatic: descriptor['isStatic'] as bool,
          id: createId()));
    });

    final staticFieldDescriptors =
        classDescriptor['staticFields'] as Map<String, dynamic>;
    staticFieldDescriptors.forEach((name, descriptor) async {
      fieldRefs.add(
        FieldRef(
          name: name,
          owner: classRef,
          declaredType: InstanceRef(
            identityHashCode: createId().hashCode,
            id: createId(),
            kind: InstanceKind.kType,
            classRef: classRef,
          ),
          isConst: descriptor['isConst'] as bool,
          isFinal: descriptor['isFinal'] as bool,
          isStatic: descriptor['isStatic'] as bool,
          id: createId(),
        ),
      );
    });

    // TODO: Implement the rest of these
    // https://github.com/dart-lang/webdev/issues/176.
    return Class(
        name: classRef.name,
        isAbstract: false,
        isConst: false,
        library: libraryRef,
        interfaces: [],
        fields: fieldRefs,
        functions: methodRefs,
        subclasses: [],
        id: classRef.id,
        traceAllocations: false);
  }
}
