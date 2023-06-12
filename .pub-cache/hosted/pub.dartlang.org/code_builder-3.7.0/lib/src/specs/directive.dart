// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_value/built_value.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../base.dart';
import '../visitors.dart';

part 'directive.g.dart';

@immutable
abstract class Directive
    implements Built<Directive, DirectiveBuilder>, Spec, Comparable<Directive> {
  factory Directive([void Function(DirectiveBuilder) updates]) = _$Directive;

  factory Directive.import(
    String url, {
    String as,
    List<String> show = const [],
    List<String> hide = const [],
  }) =>
      Directive((builder) => builder
        ..as = as
        ..type = DirectiveType.import
        ..url = url
        ..show.addAll(show)
        ..hide.addAll(hide));

  factory Directive.importDeferredAs(
    String url,
    String as, {
    List<String> show = const [],
    List<String> hide = const [],
  }) =>
      Directive((builder) => builder
        ..as = as
        ..type = DirectiveType.import
        ..url = url
        ..deferred = true
        ..show.addAll(show)
        ..hide.addAll(hide));

  factory Directive.export(
    String url, {
    List<String> show = const [],
    List<String> hide = const [],
  }) =>
      Directive((builder) => builder
        ..type = DirectiveType.export
        ..url = url
        ..show.addAll(show)
        ..hide.addAll(hide));

  factory Directive.part(String url) => Directive((builder) => builder
    ..type = DirectiveType.part
    ..url = url);

  factory Directive.partOf(String url) => Directive((builder) => builder
    ..type = DirectiveType.partOf
    ..url = url);

  Directive._();

  @nullable
  String get as;

  String get url;

  DirectiveType get type;

  List<String> get show;

  List<String> get hide;

  bool get deferred;

  @override
  R accept<R>(
    SpecVisitor<R> visitor, [
    R context,
  ]) =>
      visitor.visitDirective(this, context);

  @override
  int compareTo(Directive other) => _compareDirectives(this, other);
}

abstract class DirectiveBuilder
    implements Builder<Directive, DirectiveBuilder> {
  factory DirectiveBuilder() = _$DirectiveBuilder;

  DirectiveBuilder._();

  bool deferred = false;

  String as;

  String url;

  List<String> show = <String>[];

  List<String> hide = <String>[];

  DirectiveType type;
}

enum DirectiveType {
  import,
  export,
  part,
  partOf,
}

/// Sort import URIs represented by [a] and [b] to honor the
/// "Effective Dart" ordering rules which are enforced by the
/// `directives_ordering` lint.
///
/// 1. `import`s before `export`s
/// 2. `dart:`
/// 3. `package:`
/// 4. relative
/// 5. `part`s
int _compareDirectives(Directive a, Directive b) {
  // NOTE: using the fact that `import` is before `export` in the
  // `DirectiveType` enum – which allows us to compare using `indexOf`.
  var value = DirectiveType.values
      .indexOf(a.type)
      .compareTo(DirectiveType.values.indexOf(b.type));

  if (value == 0) {
    final uriA = Uri.parse(a.url);
    final uriB = Uri.parse(b.url);

    if (uriA.hasScheme) {
      if (uriB.hasScheme) {
        // If both import URIs have schemes, compare them based on scheme
        // `dart` will sort before `package` which is what we want
        // schemes are case-insensitive, so compare accordingly
        value = compareAsciiLowerCase(uriA.scheme, uriB.scheme);
      } else {
        value = -1;
      }
    } else if (uriB.hasScheme) {
      value = 1;
    }

    // If both schemes are the same, compare based on path
    if (value == 0) {
      value = compareAsciiLowerCase(uriA.path, uriB.path);
    }

    assert((value == 0) == (a.url == b.url));
  }

  return value;
}
