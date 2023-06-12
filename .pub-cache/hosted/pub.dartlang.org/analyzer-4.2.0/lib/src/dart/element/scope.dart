// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/summary2/combinator.dart';
import 'package:analyzer/src/summary2/export.dart';

/// The scope defined by a class.
class ClassScope extends EnclosedScope {
  ClassScope(super.parent, ClassElement element) {
    element.accessors.forEach(_addPropertyAccessor);
    element.methods.forEach(_addGetter);
  }
}

/// The scope for the initializers in a constructor.
class ConstructorInitializerScope extends EnclosedScope {
  ConstructorInitializerScope(super.parent, ConstructorElement element) {
    element.parameters.forEach(_addGetter);
  }
}

/// A scope that is lexically enclosed in another scope.
class EnclosedScope implements Scope {
  final Scope _parent;
  final Map<String, Element> _getters = {};
  final Map<String, Element> _setters = {};

  EnclosedScope(Scope parent) : _parent = parent;

  Scope get parent => _parent;

  @override
  ScopeLookupResult lookup(String id) {
    var getter = _getters[id];
    var setter = _setters[id];
    if (getter != null || setter != null) {
      return ScopeLookupResultImpl(getter, setter);
    }

    return _parent.lookup(id);
  }

  void _addGetter(Element element) {
    var id = element.name;
    if (id != null) {
      _getters[id] ??= element;
    }
  }

  void _addPropertyAccessor(PropertyAccessorElement element) {
    if (element.isGetter) {
      _addGetter(element);
    } else {
      _addSetter(element);
    }
  }

  void _addSetter(Element element) {
    var name = element.name;
    if (name != null && name.endsWith('=')) {
      var id = name.substring(0, name.length - 1);
      _setters[id] ??= element;
    }
  }
}

/// The scope defined by an extension.
class ExtensionScope extends EnclosedScope {
  ExtensionScope(
    super.parent,
    ExtensionElement element,
  ) {
    element.accessors.forEach(_addPropertyAccessor);
    element.methods.forEach(_addGetter);
  }
}

class FormalParameterScope extends EnclosedScope {
  FormalParameterScope(
    super.parent,
    List<ParameterElement> elements,
  ) {
    for (var parameter in elements) {
      if (parameter is! FieldFormalParameterElement &&
          parameter is! SuperFormalParameterElement) {
        _addGetter(parameter);
      }
    }
  }
}

class ImportedElement {
  final Element element;

  /// This flag is set to `true` if [element] is available using import
  /// directives where every imported library re-exports the element, and
  /// every such `export` directive is marked as deprecated.
  final bool isFromDeprecatedExport;

  ImportedElement({
    required this.element,
    required this.isFromDeprecatedExport,
  });
}

class LibraryScope extends EnclosedScope {
  final LibraryElementImpl _element;
  final List<ExtensionElement> extensions = [];

  LibraryScope(LibraryElementImpl element)
      : _element = element,
        super(_LibraryImportScope(element)) {
    extensions.addAll((_parent as _LibraryImportScope).extensions);

    _element.prefixes.forEach(_addGetter);
    _element.units.forEach(_addUnitElements);
  }

  void _addExtension(ExtensionElement element) {
    _addGetter(element);
    if (!extensions.contains(element)) {
      extensions.add(element);
    }
  }

  void _addUnitElements(CompilationUnitElement compilationUnit) {
    compilationUnit.accessors.forEach(_addPropertyAccessor);
    compilationUnit.enums.forEach(_addGetter);
    compilationUnit.extensions.forEach(_addExtension);
    compilationUnit.functions.forEach(_addGetter);
    compilationUnit.typeAliases.forEach(_addGetter);
    compilationUnit.mixins.forEach(_addGetter);
    compilationUnit.classes.forEach(_addGetter);
  }
}

class LocalScope extends EnclosedScope {
  LocalScope(super.parent);

  void add(Element element) {
    _addGetter(element);
  }
}

class PrefixScope implements Scope {
  final LibraryOrAugmentationElementImpl _library;
  final Map<String, ImportedElement> _getters = {};
  final Map<String, ImportedElement> _setters = {};
  final Set<ExtensionElement> _extensions = {};
  LibraryElement? _deferredLibrary;

  PrefixScope(this._library, PrefixElement? prefix) {
    final elementFactory = _library.session.elementFactory;
    for (final import in _library.imports) {
      if (import.prefix == prefix) {
        final importedLibrary = import.importedLibrary;
        if (importedLibrary is LibraryElementImpl) {
          final combinators = import.combinators.build();
          for (final exportedReference in importedLibrary.exportedReferences) {
            final reference = exportedReference.reference;
            if (combinators.allows(reference.name)) {
              final element = elementFactory.elementOfReference(reference)!;
              final importedElement = ImportedElement(
                element: element,
                isFromDeprecatedExport:
                    _isFromDeprecatedExport(importedLibrary, exportedReference),
              );
              _add(importedElement);
            }
          }
          if (import.isDeferred) {
            _deferredLibrary ??= importedLibrary;
          }
        }
      }
    }
  }

  @override
  ScopeLookupResult lookup(String id) {
    var deferredLibrary = _deferredLibrary;
    if (deferredLibrary != null && id == FunctionElement.LOAD_LIBRARY_NAME) {
      return ScopeLookupResultImpl(deferredLibrary.loadLibraryFunction, null);
    }

    var getter = _getters[id];
    var setter = _setters[id];
    return PrefixScopeLookupResult(getter, setter);
  }

  void _add(ImportedElement imported) {
    final element = imported.element;
    if (element is PropertyAccessorElement && element.isSetter) {
      _addTo(map: _setters, incoming: imported);
    } else {
      _addTo(map: _getters, incoming: imported);
      if (element is ExtensionElement) {
        _extensions.add(element);
      }
    }
  }

  void _addTo({
    required Map<String, ImportedElement> map,
    required ImportedElement incoming,
  }) {
    final id = incoming.element.displayName;
    final existing = map[id];

    if (existing == null) {
      map[id] = incoming;
      return;
    }

    if (existing.element == incoming.element) {
      map[id] = ImportedElement(
        element: incoming.element,
        isFromDeprecatedExport:
            existing.isFromDeprecatedExport && incoming.isFromDeprecatedExport,
      );
      return;
    }

    map[id] = ImportedElement(
      element: _merge(existing.element, incoming.element),
      isFromDeprecatedExport: false,
    );
  }

  Element _merge(Element existing, Element other) {
    if (_isSdkElement(existing)) {
      if (!_isSdkElement(other)) {
        return other;
      }
    } else {
      if (_isSdkElement(other)) {
        return existing;
      }
    }

    var conflictingElements = <Element>{};
    _addElement(conflictingElements, existing);
    _addElement(conflictingElements, other);

    return MultiplyDefinedElementImpl(
      _library.context,
      _library.session,
      conflictingElements.first.name!,
      conflictingElements.toList(),
    );
  }

  static void _addElement(
    Set<Element> conflictingElements,
    Element element,
  ) {
    if (element is MultiplyDefinedElementImpl) {
      conflictingElements.addAll(element.conflictingElements);
    } else {
      conflictingElements.add(element);
    }
  }

  /// Return `true` if [exportedReference] comes only from deprecated exports.
  static bool _isFromDeprecatedExport(
    LibraryElementImpl importedLibrary,
    ExportedReference exportedReference,
  ) {
    if (exportedReference is ExportedReferenceExported) {
      for (final exportIndex in exportedReference.indexes) {
        final export = importedLibrary.exports[exportIndex];
        if (!export.hasDeprecated) {
          return false;
        }
      }
      return true;
    }
    return false;
  }

  static bool _isSdkElement(Element element) {
    if (element is DynamicElementImpl || element is NeverElementImpl) {
      return true;
    }
    if (element is MultiplyDefinedElement) {
      return false;
    }
    return element.library!.isInSdk;
  }
}

class PrefixScopeLookupResult implements ScopeLookupResult {
  final ImportedElement? importedGetter;
  final ImportedElement? importedSetter;

  PrefixScopeLookupResult(
    this.importedGetter,
    this.importedSetter,
  );

  @override
  Element? get getter => importedGetter?.element;

  @override
  Element? get setter => importedSetter?.element;
}

class ScopeLookupResultImpl implements ScopeLookupResult {
  @override
  final Element? getter;

  @override
  final Element? setter;

  ScopeLookupResultImpl(this.getter, this.setter);
}

class TypeParameterScope extends EnclosedScope {
  TypeParameterScope(
    super.parent,
    List<TypeParameterElement> elements,
  ) {
    elements.forEach(_addGetter);
  }
}

class _LibraryImportScope implements Scope {
  final LibraryElementImpl _library;
  final PrefixScope _nullPrefixScope;
  List<ExtensionElement>? _extensions;

  _LibraryImportScope(LibraryElementImpl library)
      : _library = library,
        _nullPrefixScope = PrefixScope(library, null);

  List<ExtensionElement> get extensions {
    return _extensions ??= {
      ..._nullPrefixScope._extensions,
      for (var prefix in _library.prefixes)
        ...(prefix.scope as PrefixScope)._extensions,
    }.toList();
  }

  @override
  ScopeLookupResult lookup(String id) {
    return _nullPrefixScope.lookup(id);
  }
}
