// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.import 'dart:async';

// @dart = 2.9

import 'package:logging/logging.dart';
import 'package:vm_service/vm_service.dart';

import '../loaders/strategy.dart';
import '../utilities/domain.dart';
import 'inspector.dart';
import 'metadata/class.dart';

/// Keeps track of Dart libraries available in the running application.
class LibraryHelper extends Domain {
  final Logger _logger = Logger('LibraryHelper');

  /// Map of library ID to [Library].
  final _librariesById = <String, Library>{};

  /// Map of libraryRef ID to [LibraryRef].
  final _libraryRefsById = <String, LibraryRef>{};

  LibraryRef _rootLib;

  LibraryHelper(AppInspector Function() provider) : super(provider);

  Future<LibraryRef> get rootLib async {
    if (_rootLib != null) return _rootLib;
    // TODO: read entrypoint from app metadata.
    // Issue: https://github.com/dart-lang/webdev/issues/1290
    final libraries = await libraryRefs;
    _rootLib = libraries.firstWhere((lib) => lib.name.contains('org-dartlang'),
        orElse: () => null);
    _rootLib = _rootLib ??
        libraries.firstWhere((lib) => lib.name.contains('main'),
            orElse: () => null);
    _rootLib = _rootLib ?? (libraries.isNotEmpty ? libraries.last : null);
    return _rootLib;
  }

  /// Returns all libraryRefs in the app.
  ///
  /// Note this can return a cached result.
  Future<List<LibraryRef>> get libraryRefs async {
    if (_libraryRefsById.isNotEmpty) return _libraryRefsById.values.toList();
    final libraries = await globalLoadStrategy
        .metadataProviderFor(inspector.appConnection.request.entrypointPath)
        .libraries;
    for (var library in libraries) {
      _libraryRefsById[library] =
          LibraryRef(id: library, name: library, uri: library);
    }
    return _libraryRefsById.values.toList();
  }

  Future<Library> libraryFor(LibraryRef libraryRef) async {
    final library = _librariesById[libraryRef.id];
    if (library != null) return library;
    return _librariesById[libraryRef.id] = await _constructLibrary(libraryRef);
  }

  Future<LibraryRef> libraryRefFor(String objectId) async {
    if (_libraryRefsById.isEmpty) await libraryRefs;
    return _libraryRefsById[objectId];
  }

  Future<Library> _constructLibrary(LibraryRef libraryRef) async {
    // Fetch information about all the classes in this library.
    final expression = '''
    (function() {
      ${globalLoadStrategy.loadLibrarySnippet(libraryRef.uri)}
      var result = {};
      var classes = Object.values(Object.getOwnPropertyDescriptors(library))
        .filter((p) => 'value' in p)
        .map((p) => p.value)
        .filter((l) => l && sdkUtils.isType(l));
      var classList = classes.map(function(clazz) {
        var descriptor = {
          'name': clazz.name,
          'dartName': sdkUtils.typeName(clazz)
        };
        return descriptor;
      });
      result['classes'] = classList;
      return result;
    })()
    ''';
    final result =
        await inspector.remoteDebugger.sendCommand('Runtime.evaluate', params: {
      'expression': expression,
      'returnByValue': true,
      'contextId': await inspector.contextId,
    });
    List<ClassRef> classRefs;
    if (result.result.containsKey('exceptionDetails')) {
      // Unreferenced libraries are not loaded at runtime,
      // return empty library object for consistency among
      // VM Service implementations.
      // TODO: Collect library and class information from debug symbols.
      _logger.warning('Library ${libraryRef.uri} is not loaded. '
          'This can happen for unreferenced libraries.');
    } else {
      final classDescriptors =
          (result.result['result']['value']['classes'] as List)
              .cast<Map<String, Object>>();
      classRefs = classDescriptors.map<ClassRef>((classDescriptor) {
        final classMetaData = ClassMetaData(
            jsName: classDescriptor['name'],
            libraryId: libraryRef.id,
            dartName: classDescriptor['dartName']);
        return classMetaData.classRef;
      }).toList();
    }
    return Library(
        name: libraryRef.name,
        uri: libraryRef.uri,
        debuggable: true,
        dependencies: [],
        scripts: await inspector.scriptRefsForLibrary(libraryRef.id),
        variables: [],
        functions: [],
        classes: classRefs,
        id: libraryRef.id);
  }
}
