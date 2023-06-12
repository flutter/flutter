// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:convert/convert.dart';

/// The reference to a class member.
class ClassMemberReference {
  /// The target class name.
  ///
  /// This is different from the class that actually turned out to define
  /// the referenced member at the time of recording this reference. So, we
  /// will notice added overrides in the target class, or anywhere in between.
  final LibraryQualifiedName target;

  /// The name referenced in the [target].
  final String name;

  @override
  final int hashCode;

  ClassMemberReference(this.target, this.name)
      : hashCode = Object.hash(target, name);

  @override
  bool operator ==(Object other) {
    return other is ClassMemberReference &&
        other.target == target &&
        other.name == name;
  }

  @override
  String toString() {
    return '($target, $name)';
  }

  static int compare(ClassMemberReference first, ClassMemberReference second) {
    var result = LibraryQualifiedName.compare(first.target, second.target);
    if (result != 0) return result;

    return first.name.compareTo(second.name);
  }
}

/// The dependencies of the API or implementation portion of a node.
class Dependencies {
  static final none = Dependencies(Uint8List(0), [], [], [], [], []);

  /// The token signature of this portion of the node. It depends on all
  /// tokens that might affect the node API or implementation resolution.
  final Uint8List tokenSignature;

  /// The names that appear unprefixed in this portion of the node, and are
  /// not defined locally in the node. Locally defined names themselves
  /// depend on some non-local nodes, which will also recorded here.
  ///
  /// This list is sorted.
  final List<String> unprefixedReferencedNames;

  /// The names of import prefixes used to reference names in this node.
  ///
  /// This list is sorted.
  final List<String> importPrefixes;

  /// The names referenced by this node with the import prefix at the
  /// corresponding index in [importPrefixes].
  ///
  /// This list is sorted.
  final List<List<String>> importPrefixedReferencedNames;

  /// The names that appear prefixed with `super` in this portion of the node.
  ///
  /// This list is sorted.
  final List<String> superReferencedNames;

  /// The class members referenced in this portion of the node.
  ///
  /// This list is sorted.
  final List<ClassMemberReference> classMemberReferences;

  /// All referenced nodes, computed from [unprefixedReferencedNames],
  /// [importPrefixedReferencedNames], and [classMemberReferences].
  List<Node>? referencedNodes;

  /// The transitive signature of this portion of the node, computed using
  /// the [tokenSignature] of this node, and API signatures of the
  /// [referencedNodes].
  Uint8List? transitiveSignature;

  Dependencies(
      this.tokenSignature,
      this.unprefixedReferencedNames,
      this.importPrefixes,
      this.importPrefixedReferencedNames,
      this.superReferencedNames,
      this.classMemberReferences);

  String get tokenSignatureHex => hex.encode(tokenSignature);
}

/// A name qualified by a library URI.
class LibraryQualifiedName {
  /// The URI of the defining library.
  /// Not `null`.
  final Uri libraryUri;

  /// The name of this name object.
  /// If the name starts with `_`, then the name is private.
  /// Names of setters end with `=`.
  final String name;

  /// Whether this name is private, and its [name] starts with `_`.
  final bool isPrivate;

  /// The cached, pre-computed hash code.
  @override
  final int hashCode;

  factory LibraryQualifiedName(Uri libraryUri, String name) {
    var isPrivate = name.startsWith('_');
    var hashCode = Object.hash(libraryUri, name);
    return LibraryQualifiedName._internal(
        libraryUri, name, isPrivate, hashCode);
  }

  LibraryQualifiedName._internal(
      this.libraryUri, this.name, this.isPrivate, this.hashCode);

  @override
  bool operator ==(Object other) {
    return other is LibraryQualifiedName &&
        other.hashCode == hashCode &&
        name == other.name &&
        libraryUri == other.libraryUri;
  }

  /// Whether this name us accessible for the library with the given
  /// [libraryUri], i.e. when the name is public, or is defined in a library
  /// with the same URI.
  bool isAccessibleFor(Uri libraryUri) {
    return !isPrivate || this.libraryUri == libraryUri;
  }

  @override
  String toString() => '$libraryUri::$name';

  /// Compare given names by their raw names.
  ///
  /// This method should be used only for sorting, it does not follow the
  /// complete semantics of [==] and [hashCode].
  static int compare(LibraryQualifiedName first, LibraryQualifiedName second) {
    return first.name.compareTo(second.name);
  }
}

/// A dependency node - anything that has a name, and can be referenced.
class Node {
  /// The API or implementation signature used in [Dependencies]
  /// as a marker that this node is changed, explicitly because its token
  /// signature changed, or implicitly - because it references a changed node.
  static final changedSignature = Uint8List.fromList([0xDE, 0xAD, 0xBE, 0xEF]);

  final LibraryQualifiedName name;
  final NodeKind kind;

  /// Dependencies that affect the API of the node, so affect API or
  /// implementation dependencies of the nodes that use this node.
  final Dependencies api;

  /// Additional (to the [api]) dependencies that affect only the
  /// "implementation" of the node, e.g. the body of a method, but are not
  /// visible outside of the node, and so don't affect any other nodes.
  final Dependencies impl;

  /// If the node is a class member, the node of the enclosing class.
  /// Otherwise `null`.
  final Node? enclosingClass;

  /// If the node is a class, the nodes of its type parameters.
  /// Otherwise `null`.
  List<Node>? classTypeParameters;

  /// If the node is a class, the sorted list of members in this class.
  /// Otherwise `null`.
  List<Node>? classMembers;

  Node(this.name, this.kind, this.api, this.impl,
      {this.enclosingClass, this.classTypeParameters});

  /// Return the node that can be referenced by the given [name] from the
  /// library with the given [libraryUri].
  Node? getClassMember(Uri libraryUri, String name) {
    // TODO(scheglov) The list is sorted, use this fact to search faster.
    // TODO(scheglov) Collect superclass members here or outside.
    for (var i = 0; i < classMembers!.length; ++i) {
      var member = classMembers![i];
      var memberName = member.name;
      if (memberName.name == name && memberName.isAccessibleFor(libraryUri)) {
        return member;
      }
    }
    return null;
  }

  /// Set new class members for this class.
  void setClassMembers(List<Node> newClassMembers) {
    classMembers = newClassMembers;
  }

  /// Set new class type parameters for this class.
  void setTypeParameters(List<Node> newTypeParameters) {
    classTypeParameters = newTypeParameters;
  }

  @override
  String toString() {
    if (enclosingClass != null) {
      return '$enclosingClass::${name.name}';
    }
    return name.toString();
  }

  /// Compare given nodes by their names.
  static int compare(Node first, Node second) {
    return LibraryQualifiedName.compare(first.name, second.name);
  }
}

/// Kinds of nodes.
enum NodeKind {
  CLASS,
  CLASS_TYPE_ALIAS,
  CONSTRUCTOR,
  ENUM,
  FUNCTION,
  FUNCTION_TYPE_ALIAS,
  GENERIC_TYPE_ALIAS,
  GETTER,
  METHOD,
  MIXIN,
  SETTER,
  TYPE_PARAMETER,
}
