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
import 'package:analyzer/src/summary2/reference.dart';

class LinkedElementFactory {
  final AnalysisContextImpl analysisContext;
  final AnalysisSessionImpl analysisSession;
  final Reference rootReference;
  final Map<String, LibraryReader> _libraryReaders = {};
  final Map<String, List<Reference>> _exportsOfLibrary = {};

  bool isApplyingInformativeData = false;

  LinkedElementFactory(
    this.analysisContext,
    this.analysisSession,
    this.rootReference,
  ) {
    ArgumentError.checkNotNull(analysisContext, 'analysisContext');
    ArgumentError.checkNotNull(analysisSession, 'analysisSession');
  }

  Reference get dynamicRef {
    return rootReference.getChild('dart:core').getChild('dynamic');
  }

  void addBundle(BundleReader bundle) {
    addLibraries(bundle.libraryMap);
  }

  void addLibraries(Map<String, LibraryReader> libraries) {
    _libraryReaders.addAll(libraries);
  }

  Namespace buildExportNamespace(Uri uri) {
    var exportedNames = <String, Element>{};

    var exportedReferences = exportsOfLibrary('$uri');
    for (var exportedReference in exportedReferences) {
      var element = elementOfReference(exportedReference);
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

  LibraryElementImpl? createLibraryElementForReading(String uriStr) {
    var sourceFactory = analysisContext.sourceFactory;
    var librarySource = sourceFactory.forUri(uriStr);

    // The URI cannot be resolved, we don't know the library.
    if (librarySource == null) return null;

    var reader = _libraryReaders[uriStr];
    if (reader == null) {
      throw ArgumentError(
        'Missing library: $uriStr\n'
        'Available libraries: ${_libraryReaders.keys.toList()}',
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

  Element? elementOfReference(Reference reference) {
    if (reference.element != null) {
      return reference.element;
    }
    if (reference.parent == null) {
      return null;
    }

    if (reference.isLibrary) {
      var uriStr = reference.name;
      return createLibraryElementForReading(uriStr);
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

  List<Reference> exportsOfLibrary(String uriStr) {
    var exports = _exportsOfLibrary[uriStr];
    if (exports != null) return exports;

    // TODO(scheglov) Use [setExportsOfLibrary] instead
    var library = _libraryReaders[uriStr];
    if (library == null) return const [];

    return library.exports;
  }

  bool hasLibrary(String uriStr) {
    // We already have the element, linked or read.
    if (rootReference[uriStr]?.element is LibraryElementImpl) {
      return true;
    }
    // No element yet, but we know how to read it.
    return _libraryReaders[uriStr] != null;
  }

  /// We are about to discard this factory, mark all libraries invalid.
  void invalidateAllLibraries() {
    for (var libraryReference in rootReference.children) {
      _invalidateLibrary(libraryReference);
    }
  }

  LibraryElementImpl? libraryOfUri(String uriStr) {
    var reference = rootReference.getChild(uriStr);
    return elementOfReference(reference) as LibraryElementImpl?;
  }

  LibraryElementImpl libraryOfUri2(String uriStr) {
    var element = libraryOfUri(uriStr);
    if (element == null) {
      libraryOfUri(uriStr);
      throw StateError('No library: $uriStr');
    }
    return element;
  }

  /// Return the [LibraryElementImpl] if it is ready.
  LibraryElementImpl? libraryOfUriIfReady(String uriStr) {
    var element = rootReference.getChild(uriStr).element;
    return element is LibraryElementImpl ? element : null;
  }

  /// We have linked the bundle, and need to disconnect its libraries, so
  /// that the client can re-add the bundle, this time read from bytes.
  void removeBundle(Set<String> uriStrSet) {
    removeLibraries(uriStrSet);
  }

  /// Remove libraries with the specified URIs from the reference tree, and
  /// any session level caches.
  void removeLibraries(Set<String> uriStrSet) {
    for (var uriStr in uriStrSet) {
      _exportsOfLibrary.remove(uriStr);
      _libraryReaders.remove(uriStr);
      var libraryReference = rootReference.removeChild(uriStr);
      _invalidateLibrary(libraryReference);
    }

    analysisSession.classHierarchy.removeOfLibraries(uriStrSet);
    analysisSession.inheritanceManager.removeOfLibraries(uriStrSet);

    // If we discard `dart:core` and `dart:async`, we should also discard
    // the type provider.
    if (uriStrSet.contains('dart:core')) {
      if (!uriStrSet.contains('dart:async')) {
        throw StateError(
          'Expected to link dart:core and dart:async together: '
          '${uriStrSet.toList()}',
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

  /// Set exports of the library with [uriStr], after building exports during
  /// linking, or after reading a linked bundle.
  void setExportsOfLibrary(String uriStr, List<Reference> exports) {
    _exportsOfLibrary[uriStr] = exports;
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

  void _invalidateLibrary(Reference? libraryReference) {
    var libraryElement = libraryReference?.element;
    if (libraryElement is LibraryElementImpl) {
      libraryElement.isValid = false;
    }
  }
}
