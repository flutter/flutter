// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;

import 'libs/strict_concurrency_annotations.dart';

// For Flutter subclasses of these classes, do not require explicit annotations,
// since they are obviously @MainActor.
const List<String> mainActorIsolatedClassNames = [
  "UIView",
  "UIViewController",
  "UIAppilcationDelegate",
  "UISceneDelegate",
  "UIWindowScene",
  "UIResponder",
];

typedef Violation = ({String typeName, String? superclass});

/// This script checks `@protocol` and `@interface Name : Superclass`
/// declarations in the iOS embedder public header files for missing swift concurrency
/// annotations.
///
/// The implementation currently does not check concurrency annotations on
/// individual methods because in most cases they have the same isolation
/// domain / thread-safety promise as the class / protocol and requiring each
/// and every method to be annotated is unnecessary.
void main(List<String> args) async {
  final List<File> files = [for (final path in args) File(path)];

  var failures = 0;

  final List<(String, String)> classPairs = [];

  for (final file in files) {
    print('processing: $file');
    final result = await file
        .openRead()
        .map(utf8.decode)
        .transform(LineSplitter())
        .fold<ParsingState>(.initial, processLine);
    print('> $result');
    for (final (:typeName, :superclass) in result.violations) {
      if (superclass == null) {
        print('Did you forget to add Swift concurrency annotations to protocol $typeName?');
        failures += 1;
      } else {
        classPairs.add((typeName, superclass));
      }
    }
  }

  print(classPairs);
  // Find the classes who are not direct or indirect subclasses of known
  // main-actor-isolated classes.
  final unannotatedClasses = forestFromPairs(
    classPairs,
  ).where((Node<String> root) => !mainActorIsolatedClassNames.contains(root.value));
  print('----');
  for (final x in forestFromPairs(classPairs)) {
    print(x);
  }
  print('----');

  for (final unannotated in unannotatedClasses) {
    // Roots are always non-Flutter classes.
    for (final child in unannotated.children) {
      print('Did you forget to add Swift concurrency annotations to class ${child.value}?');
    }
  }

  exit(failures);
}

ParsingState processLine(ParsingState state, String line) {
  final ParsingState(:scope, :violations) = state;

  final scope = state.scope ?? ObjcClassDecl.parse(line) ?? ObjcProtocolDecl.parse(line);
  if (scope == null) {
    return state;
  }

  if (line.isEmpty) {
    return ParsingState((null, violations..add((typeName: scope, superclass: null))));
  }

  return switch ((parsedLine?.$1, pendingAnnotation)) {
    // This line is not meaningful to us.
    (null, _) => ParsingState((pendingAnnotation, violations)),
    // Encountering a new concurrency annotation.
    (final StrictConcurrencyAnnotation newAnnotatoin, _) => ParsingState((
      newAnnotatoin,
      violations,
    )),
    // A nonsendable nonisolated protocol must be explicitly marked as NONSENDABLE,
    // and a comment must be provided to justify the use of NONSENDABLE.
    (
      ObjcProtocol(:final protocolName),
      null || StrictConcurrencyAnnotationNonSendable(comment: null),
    ) =>
      ParsingState((null, violations..add((typeName: protocolName, superclass: null)))),
    // The class declaration is suspicious. But unlike protocols they could be a subclass of
    // a main-actor-isolated class thus need further inspection.
    (
      ObjcClass(:final className, :final superclass),
      null || StrictConcurrencyAnnotationNonSendable(comment: null),
    ) =>
      ParsingState((null, violations..add((typeName: className, superclass: superclass)))),
    // Acceptable annotation spotted on the protocol / class declaration.
    // Consume the pending annotation.
    (
      ObjcProtocol() || ObjcClass(),
      .mainActor || .sendable || StrictConcurrencyAnnotationNonSendable(),
    ) =>
      ParsingState((null, violations)),
  };
}

sealed class ParseState {
  ParseState parseNextLine(String nextLine);
}

final class EmptyLine implements ParseState {
  ParseState parseNextLine(String nextLine) {
    if (ObjcProtocolDecl._matcher.parse(line) case final parsed) {
      return parsed;
    } else if (ObjcClassDecl._matcher.parse(line) case final parsed) {
      return parsed;
    }
    return null;
  }
}

final class ObjcClassDecl implements ParseState {
  final String name;
  final String location;

  ObjcClassDecl._fromList(List<String?> list)
    : assert(list.length == 2),
      assert(!list.contains(null)),
      this.name = list[0] ?? "",
      this.location = list[1] ?? "";

  static final _matcher = Matcher.pattern(
    r'ObjCInterfaceDecl\s0x[a-z0-9]+\s(<.*>)\s\w+:\d+\s([a-zA-Z_][a-zA-Z0-9_]*)',
    ObjcClassDecl._fromList,
  );

  static (ObjcClassDecl, String)? parse(String string) => _matcher.parse(string);

  @override
  String toString() => 'class $name';
}

final class ObjcSuperclass implements ParseState {
  final ObjcClassDecl classDeclaration;
  final String superclass;

  ObjcSuperclass(this.classDeclaration, this.superclass);

  static Matcher<ObjcSuperclass> matches(ObjcClassDecl classDeclaration) => Matcher.pattern(
    r"|-super ObjCInterface 0x[a-z0-9]+ '([a-zA-Z_][a-zA-Z0-9_]*)'",
    (List<String?> list) => ObjcSuperclass(classDeclaration, list[0]),
  );

  ParseState parseNextLine(String nextLine) {}
}

// |-SwiftAttrAttr 0x71f47b728 <line:287:47, col:73> "@_nonSendable"
enum SwiftAttr {
  mainActor._('|-SwiftAttrAttr 0x[a-z0-9]+ <.*> "@UIActor"'),
  sendable._('|-SwiftAttrAttr 0x[a-z0-9]+ <.*> "@Sendable"'),
  nonsendable._('|-SwiftAttrAttr 0x[a-z0-9]+ <.*> "@_nonSendable"');

  final String _pattern;
  const SwiftAttr._(this._pattern);

  Matcher<SwiftAttr> get _matcher => Matcher<SwiftAttr>.pattern(RegExp(_pattern), () => this);

  static Matcher<SwiftAttr> matches(ObjcClassDecl classDeclaration) => Matcher.pattern(
    r"|-super ObjCInterface 0x[a-z0-9]+ '([a-zA-Z_][a-zA-Z0-9_]*)'",
    (List<String?> list) => ObjcSuperclass(classDeclaration, list[0]),
  );
}

final class ObjcProtocolDecl implements ParseState {
  final String name;
  final String location;

  ObjcProtocolDecl._fromList(List<String?> list)
    : assert(list.length == 2),
      assert(!list.contains(null)),
      this.name = list[0] ?? "",
      this.location = list[1] ?? "";

  static final _matcher = Matcher.pattern(
    r'ObjCProtocolDecl\s0x[a-z0-9]+\s(<.*>)\s\w+:\d+\s([a-zA-Z_][a-zA-Z0-9_]*)',
    ObjcProtocolDecl._fromList,
  );

  // This function does not parse or consume protocol conformance tokens since
  // they are irrelevant to strict concurrency.
  static (ObjcProtocolDecl, String)? parse(String string) => _matcher.parse(string);

  @override
  String toString() => 'protocol $name';
}

extension type const ParsedUnit((String, String, String?, String?) _v) {
  String get typeName => _v.$1;
  String get location => _v.$2;
  String? get superclass => _v.$3;
  String? get annotation => _v.$4;
}

// example:
// @interface FlutterEngine : NSObject <FlutterPluginRegistry, AnotherProtocol>

// example:
// @interface FlutterEngine : NSObject <FlutterPluginRegistry, AnotherProtocol>

/// Constructs a class hierarchy forest from an association list of
/// superclass-class pairs.
Iterable<Node<T>> forestFromPairs<T extends Object>(Iterable<(T, T)> pairs) {
  final Set<Node<T>> allRoots = {};
  final Map<T, Node<T>> nodeRegistry = {};

  for (final (parent, child) in pairs) {
    final childNode = nodeRegistry.putIfAbsent(child, () => Node._(child, {}));
    allRoots.remove(childNode);
    nodeRegistry.putIfAbsent(parent, () {
      final newNode = Node._(parent, {childNode});
      // This means the parent wasn't added as a child or a parent.
      // This is a new root node.
      final wasAddedBefore = allRoots.add(newNode);
      assert(!wasAddedBefore);
      return newNode;
    });
  }
  return allRoots;
}

final class Node<T> {
  Node._(this.value, this.children);

  final T value;
  final Set<Node<T>> children;

  @override
  String toString() => '$value, $children';
}
