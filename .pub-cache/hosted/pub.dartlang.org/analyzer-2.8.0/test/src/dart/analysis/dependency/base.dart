// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/analysis/dependency/library_builder.dart';
import 'package:analyzer/src/dart/analysis/dependency/node.dart';
import 'package:test/test.dart';

import '../../resolution/context_collection_resolution.dart';

class BaseDependencyTest extends PubPackageResolutionTest {
  late final String a;
  late final String b;
  late final String c;
  late final Uri aUri;
  late final Uri bUri;
  late final Uri cUri;

  bool hasDartCore = false;

  void assertNodes(List<Node> actualNodes, List<ExpectedNode> expectedNodes,
      {Node? expectedEnclosingClass}) {
    expect(actualNodes, hasLength(expectedNodes.length));
    for (var expectedNode in expectedNodes) {
      var topNode = _getNode(
        actualNodes,
        uri: expectedNode.uri,
        name: expectedNode.name,
        kind: expectedNode.kind,
      );
      expect(topNode.enclosingClass, expectedEnclosingClass);

      if (expectedNode.classMembers != null) {
        assertNodes(topNode.classMembers!, expectedNode.classMembers!,
            expectedEnclosingClass: topNode);
      } else {
        expect(topNode.classMembers, isNull);
      }

      if (expectedNode.classTypeParameters != null) {
        assertNodes(
          topNode.classTypeParameters!,
          expectedNode.classTypeParameters!,
          expectedEnclosingClass: topNode,
        );
      } else {
        expect(topNode.classTypeParameters, isNull);
      }
    }
  }

  Future<Library> buildTestLibrary(String path, String content) async {
//    if (!hasDartCore) {
//      hasDartCore = true;
//      await _addLibraryByUri('dart:core');
//      await _addLibraryByUri('dart:async');
//      await _addLibraryByUri('dart:math');
//      await _addLibraryByUri('dart:_internal');
//    }

    newFile(path, content: content);
    driverFor(path).changeFile(path);

    var units = await _resolveLibrary(path);
    var uri = units.first.declaredElement!.source.uri;

    return buildLibrary(uri, units);

//    tracker.addLibrary(uri, units);
//
//    var library = tracker.libraries[uri];
//    expect(library, isNotNull);
//
//    return library;
  }

  Node getNode(Library library,
      {required String name,
      NodeKind? kind,
      String? memberOf,
      String? typeParameterOf}) {
    var uri = library.uri;
    var nodes = library.declaredNodes;
    if (memberOf != null) {
      var class_ = _getNode(nodes, uri: uri, name: memberOf);
      expect(
        class_.kind,
        anyOf(NodeKind.CLASS, NodeKind.ENUM, NodeKind.MIXIN),
      );
      nodes = class_.classMembers!;
    } else if (typeParameterOf != null) {
      var class_ = _getNode(nodes, uri: uri, name: typeParameterOf);
      expect(class_.kind, anyOf(NodeKind.CLASS, NodeKind.MIXIN));
      nodes = class_.classTypeParameters!;
    }
    return _getNode(nodes, uri: uri, name: name, kind: kind);
  }

  @override
  void setUp() {
    super.setUp();
//    var logger = PerformanceLog(null);
//    tracker = DependencyTracker(logger);
    a = convertPath('$testPackageLibPath/a.dart');
    b = convertPath('$testPackageLibPath/b.dart');
    c = convertPath('$testPackageLibPath/c.dart');
    aUri = Uri.parse('package:test/a.dart');
    bUri = Uri.parse('package:test/b.dart');
    cUri = Uri.parse('package:test/c.dart');
  }

//  Future _addLibraryByUri(String uri) async {
//    var path = driver.sourceFactory.forUri(uri).fullName;
//    var unitResult = await driver.getUnitElement(path);
//
//    var signature = ApiSignature();
//    signature.addString(unitResult.signature);
//    var signatureBytes = signature.toByteList();
//
//    tracker.addLibraryElement(unitResult.element.library, signatureBytes);
//  }

  Node _getNode(List<Node> nodes,
      {required Uri uri, required String name, NodeKind? kind}) {
    var nameObj = LibraryQualifiedName(uri, name);
    for (var node in nodes) {
      if (node.name == nameObj) {
        if (kind != null && node.kind != kind) {
          fail('Expected $kind "$name", found ${node.kind}');
        }
        return node;
      }
    }
    fail('Expected to find $uri::$name in:\n    ${nodes.join('\n    ')}');
  }

  Future<List<CompilationUnit>> _resolveLibrary(String libraryPath) async {
    var session = contextFor(libraryPath).currentSession;
    var resolvedLibrary = await session.getResolvedLibrary(libraryPath);
    resolvedLibrary as ResolvedLibraryResult;
    return resolvedLibrary.units.map((ru) => ru.unit).toList();
  }
}

class ExpectedNode {
  final Uri uri;
  final String name;
  final NodeKind kind;
  final List<ExpectedNode>? classMembers;
  final List<ExpectedNode>? classTypeParameters;

  ExpectedNode(
    this.uri,
    this.name,
    this.kind, {
    this.classMembers,
    this.classTypeParameters,
  });
}
