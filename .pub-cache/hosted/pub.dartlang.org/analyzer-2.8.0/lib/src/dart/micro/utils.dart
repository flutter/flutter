// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/element_locator.dart';

/// Return the [Element] of the given [node], or `null` if [node] is `null` or
/// does not have an element.
Element? getElementOfNode(AstNode? node) {
  if (node == null) {
    return null;
  }
  if (node is SimpleIdentifier && node.parent is LibraryIdentifier) {
    node = node.parent;
  }
  if (node is LibraryIdentifier) {
    node = node.parent;
  }
  if (node is StringLiteral && node.parent is UriBasedDirective) {
    return null;
  }
  var element = ElementLocator.locate(node);
  if (node is SimpleIdentifier && element is PrefixElement) {
    var parent = node.parent;
    if (parent is ImportDirective) {
      element = parent.element;
    } else {
      element = _getImportElementInfo(node);
    }
  }
  return element;
}

/// Return the [ImportElement] that declared [prefix] and imports [element].
///
/// [libraryElement] - the [LibraryElement] where reference is.
/// [prefix] - the import prefix, maybe `null`.
/// [element] - the referenced element.
/// [importElementsMap] - the cache of [Element]s imported by [ImportElement]s.
ImportElement? _getImportElement(LibraryElement libraryElement, String prefix,
    Element element, Map<ImportElement, Set<Element>> importElementsMap) {
  if (element.enclosingElement is! CompilationUnitElement) {
    return null;
  }
  var usedLibrary = element.library;
  // find ImportElement that imports used library with used prefix
  List<ImportElement>? candidates;
  for (var importElement in libraryElement.imports) {
    // required library
    if (importElement.importedLibrary != usedLibrary) {
      continue;
    }
    // required prefix
    var prefixElement = importElement.prefix;
    if (prefixElement == null) {
      continue;
    }
    if (prefix != prefixElement.name) {
      continue;
    }
    // no combinators => only possible candidate
    if (importElement.combinators.isEmpty) {
      return importElement;
    }
    // OK, we have candidate
    candidates ??= [];
    candidates.add(importElement);
  }
  // no candidates, probably element is defined in this library
  if (candidates == null) {
    return null;
  }
  // one candidate
  if (candidates.length == 1) {
    return candidates[0];
  }
  // ensure that each ImportElement has set of elements
  for (var importElement in candidates) {
    if (importElementsMap.containsKey(importElement)) {
      continue;
    }
    var namespace = importElement.namespace;
    var elements = Set<Element>.from(namespace.definedNames.values);
    importElementsMap[importElement] = elements;
  }
  // use import namespace to choose correct one
  for (var entry in importElementsMap.entries) {
    var importElement = entry.key;
    var elements = entry.value;
    if (elements.contains(element)) {
      return importElement;
    }
  }
  // not found
  return null;
}

/// Returns the [ImportElement] that is referenced by [prefixNode] with a
/// [PrefixElement], maybe `null`.
ImportElement? _getImportElementInfo(SimpleIdentifier prefixNode) {
  // prepare environment
  var parent = prefixNode.parent;
  var unit = prefixNode.thisOrAncestorOfType<CompilationUnit>();
  var libraryElement = unit?.declaredElement?.library;
  if (libraryElement == null) {
    return null;
  }
  // prepare used element
  Element? usedElement;
  if (parent is PrefixedIdentifier) {
    var prefixed = parent;
    if (prefixed.prefix == prefixNode) {
      usedElement = prefixed.staticElement;
    }
  } else if (parent is MethodInvocation) {
    var invocation = parent;
    if (invocation.target == prefixNode) {
      usedElement = invocation.methodName.staticElement;
    }
  }
  // we need used Element
  if (usedElement == null) {
    return null;
  }
  // find ImportElement
  var prefix = prefixNode.name;
  var importElementsMap = <ImportElement, Set<Element>>{};
  return _getImportElement(
      libraryElement, prefix, usedElement, importElementsMap);
}

class ReferencesCollector extends GeneralizingAstVisitor<void> {
  final Element element;
  final List<int> offsets = [];

  ReferencesCollector(this.element);

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    if (node.writeElement != null &&
        node.writeElement is PropertyAccessorElement) {
      var property = node.writeElement as PropertyAccessorElement;
      if (property.variable == element || property == element) {
        if (node.leftHandSide is SimpleIdentifier) {
          offsets.add(node.leftHandSide.offset);
        } else if (node.leftHandSide is PrefixedIdentifier) {
          var prefixIdentifier = node.leftHandSide as PrefixedIdentifier;
          offsets.add(prefixIdentifier.identifier.offset);
        } else if (node.leftHandSide is PropertyAccess) {
          var accessor = node.leftHandSide as PropertyAccess;
          offsets.add(accessor.propertyName.offset);
        }
      }
    }
    if (node.readElement != null &&
        node.readElement is PropertyAccessorElement) {
      var property = node.readElement as PropertyAccessorElement;
      if (property.variable == element) {
        offsets.add(node.rightHandSide.offset);
      }
    }
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var e = node.staticElement;
    if (e == element) {
      offsets.add(node.offset);
    } else if (e is PropertyAccessorElement && e.variable == element) {
      offsets.add(node.offset);
    }
  }
}
