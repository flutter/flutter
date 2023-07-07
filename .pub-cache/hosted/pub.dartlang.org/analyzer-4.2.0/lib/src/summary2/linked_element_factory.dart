// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/summary2/bundle_reader.dart';
import 'package:analyzer/src/summary2/export.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:meta/meta.dart';

class LinkedElementFactory {
  static final _dartCoreUri = Uri.parse('dart:core');
  static final _dartAsyncUri = Uri.parse('dart:async');

  final AnalysisContextImpl analysisContext;
  AnalysisSessionImpl analysisSession;
  final Reference rootReference;
  final Map<Uri, LibraryReader> _libraryReaders = {};

  bool isApplyingInformativeData = false;

  LinkedElementFactory(
    this.analysisContext,
    this.analysisSession,
    this.rootReference,
  ) {
    ArgumentError.checkNotNull(analysisContext, 'analysisContext');
    ArgumentError.checkNotNull(analysisSession, 'analysisSession');
  }

  LibraryElementImpl get dartAsyncElement {
    return libraryOfUri2(_dartAsyncUri);
  }

  LibraryElementImpl get dartCoreElement {
    return libraryOfUri2(_dartCoreUri);
  }

  Reference get dynamicRef {
    return rootReference.getChild('dart:core').getChild('dynamic');
  }

  /// Returns URIs for which [LibraryElementImpl] is ready.
  @visibleForTesting
  List<Uri> get uriListWithLibraryElements {
    return rootReference.children
        .map((reference) => reference.element)
        .whereType<LibraryElementImpl>()
        .map((e) => e.source.uri)
        .toList();
  }

  /// Returns URIs for which we have readers, but not elements.
  @visibleForTesting
  List<Uri> get uriListWithLibraryReaders {
    return _libraryReaders.keys.toList();
  }

  void addBundle(BundleReader bundle) {
    addLibraries(bundle.libraryMap);
  }

  void addLibraries(Map<Uri, LibraryReader> libraries) {
    _libraryReaders.addAll(libraries);
  }

  Namespace buildExportNamespace(
    Uri uri,
    List<ExportedReference> exportedReferences,
  ) {
    var exportedNames = <String, Element>{};

    for (var exportedReference in exportedReferences) {
      var element = elementOfReference(exportedReference.reference);
      // TODO(scheglov) Remove after https://github.com/dart-lang/sdk/issues/41212
      if (element == null) {
        throw StateError(
          '[No element]'
          '[uri: $uri]'
          '[exportedReferences: $exportedReferences]'
          '[exportedReference: $exportedReference]',
        );
      }
      exportedNames[element.name!] = element;
    }

    return Namespace(exportedNames);
  }

  LibraryElementImpl? createLibraryElementForReading(Uri uri) {
    var sourceFactory = analysisContext.sourceFactory;
    var librarySource = sourceFactory.forUri2(uri);

    // The URI cannot be resolved, we don't know the library.
    if (librarySource == null) return null;

    var reader = _libraryReaders[uri];
    if (reader == null) {
      final rootChildren = rootReference.children.map((e) => e.name).toList();
      throw ArgumentError(
        'Missing library: $uri\n'
        'Libraries: $uriListWithLibraryElements'
        'Root children: $rootChildren'
        'Readers: ${_libraryReaders.keys.toList()}',
      );
    }

    var libraryElement = reader.readElement(
      librarySource: librarySource,
    );
    setLibraryTypeSystem(libraryElement);
    return libraryElement;
  }

  void createTypeProviders(
    LibraryElementImpl dartCore,
    LibraryElementImpl dartAsync,
  ) {
    if (analysisContext.hasTypeProvider) {
      return;
    }

    analysisContext.setTypeProviders(
      legacy: TypeProviderImpl(
        coreLibrary: dartCore,
        asyncLibrary: dartAsync,
        isNonNullableByDefault: false,
      ),
      nonNullableByDefault: TypeProviderImpl(
        coreLibrary: dartCore,
        asyncLibrary: dartAsync,
        isNonNullableByDefault: true,
      ),
    );

    // During linking we create libraries when typeProvider is not ready.
    // Update these libraries now, when typeProvider is ready.
    for (var reference in rootReference.children) {
      var libraryElement = reference.element as LibraryElementImpl?;
      if (libraryElement != null && !libraryElement.hasTypeProviderSystemSet) {
        setLibraryTypeSystem(libraryElement);
      }
    }
  }

  void dispose() {
    for (var libraryReference in rootReference.children) {
      _disposeLibrary(libraryReference.element);
    }
  }

  /// TODO(scheglov) Why would this method return `null`?
  Element? elementOfReference(Reference reference) {
    if (reference.element != null) {
      return reference.element;
    }
    if (reference.parent == null) {
      return null;
    }

    if (reference.isLibrary) {
      final uri = Uri.parse(reference.name);
      return createLibraryElementForReading(uri);
    }

    var parent = reference.parent!.parent!;
    var parentElement = elementOfReference(parent);

    if (parentElement is ClassElementImpl) {
      var linkedData = parentElement.linkedData;
      if (linkedData is ClassElementLinkedData) {
        linkedData.readMembers(parentElement);
      }
    }

    var element = reference.element;
    if (element == null) {
      throw StateError('Expected existing element: $reference');
    }
    return element;
  }

  bool hasLibrary(Uri uri) {
    // We already have the element, linked or read.
    if (rootReference['$uri']?.element is LibraryElementImpl) {
      return true;
    }
    // No element yet, but we know how to read it.
    return _libraryReaders[uri] != null;
  }

  LibraryElementImpl? libraryOfUri(Uri uri) {
    var reference = rootReference.getChild('$uri');
    return elementOfReference(reference) as LibraryElementImpl?;
  }

  LibraryElementImpl libraryOfUri2(Uri uri) {
    var element = libraryOfUri(uri);
    if (element == null) {
      libraryOfUri(uri);
      throw StateError('No library: $uri');
    }
    return element;
  }

  /// We have linked the bundle, and need to disconnect its libraries, so
  /// that the client can re-add the bundle, this time read from bytes.
  void removeBundle(Set<Uri> uriSet) {
    removeLibraries(uriSet);
  }

  /// Remove libraries with the specified URIs from the reference tree, and
  /// any session level caches.
  void removeLibraries(Set<Uri> uriSet) {
    for (final uri in uriSet) {
      _libraryReaders.remove(uri);
      final libraryReference = rootReference.removeChild('$uri');
      _disposeLibrary(libraryReference?.element);
    }

    analysisSession.classHierarchy.removeOfLibraries(uriSet);
    analysisSession.inheritanceManager.removeOfLibraries(uriSet);

    // If we discard `dart:core` and `dart:async`, we should also discard
    // the type provider.
    if (uriSet.contains(_dartCoreUri)) {
      if (!uriSet.contains(_dartAsyncUri)) {
        throw StateError(
          'Expected to link dart:core and dart:async together: '
          '${uriSet.toList()}',
        );
      }
      if (_libraryReaders.isNotEmpty) {
        throw StateError(
          'Expected to link dart:core and dart:async first: '
          '${_libraryReaders.keys.toList()}',
        );
      }
      analysisContext.clearTypeProvider();
    }
  }

  void replaceAnalysisSession(AnalysisSessionImpl newSession) {
    analysisSession = newSession;
    for (var libraryReference in rootReference.children) {
      var libraryElement = libraryReference.element;
      if (libraryElement is LibraryElementImpl) {
        libraryElement.session = newSession;
      }
    }
  }

  void setLibraryTypeSystem(LibraryElementImpl libraryElement) {
    // During linking we create libraries when typeProvider is not ready.
    // And if we link dart:core and dart:async, we cannot create it.
    // We will set typeProvider later, during [createTypeProviders].
    if (!analysisContext.hasTypeProvider) {
      return;
    }

    var isNonNullable = libraryElement.isNonNullableByDefault;
    libraryElement.typeProvider = isNonNullable
        ? analysisContext.typeProviderNonNullableByDefault
        : analysisContext.typeProviderLegacy;
    libraryElement.typeSystem = isNonNullable
        ? analysisContext.typeSystemNonNullableByDefault
        : analysisContext.typeSystemLegacy;
    libraryElement.hasTypeProviderSystemSet = true;

    libraryElement.createLoadLibraryFunction();
  }

  void _disposeLibrary(Element? libraryElement) {
    if (libraryElement is LibraryElementImpl) {
      libraryElement.bundleMacroExecutor?.dispose();
    }
  }
}
