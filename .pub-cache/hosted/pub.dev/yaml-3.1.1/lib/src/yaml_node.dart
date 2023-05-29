// Copyright (c) 2012, the Dart project authors.
// Copyright (c) 2006, Kirill Simonov.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

import 'dart:collection' as collection;

import 'package:collection/collection.dart';
import 'package:source_span/source_span.dart';

import 'event.dart';
import 'null_span.dart';
import 'style.dart';
import 'yaml_node_wrapper.dart';

/// An interface for parsed nodes from a YAML source tree.
///
/// [YamlMap]s and [YamlList]s implement this interface in addition to the
/// normal [Map] and [List] interfaces, so any maps and lists will be
/// [YamlNode]s regardless of how they're accessed.
///
/// Scalars values like strings and numbers, on the other hand, don't have this
/// interface by default. Instead, they can be accessed as [YamlScalar]s via
/// [YamlMap.nodes] or [YamlList.nodes].
abstract class YamlNode {
  /// The source span for this node.
  ///
  /// [SourceSpan.message] can be used to produce a human-friendly message about
  /// this node.
  SourceSpan get span => _span;
  SourceSpan _span;

  YamlNode._(this._span);

  /// The inner value of this node.
  ///
  /// For [YamlScalar]s, this will return the wrapped value. For [YamlMap] and
  /// [YamlList], it will return [this], since they already implement [Map] and
  /// [List], respectively.
  dynamic get value;
}

/// A read-only [Map] parsed from YAML.
class YamlMap extends YamlNode with collection.MapMixin, UnmodifiableMapMixin {
  /// A view of [this] where the keys and values are guaranteed to be
  /// [YamlNode]s.
  ///
  /// The key type is `dynamic` to allow values to be accessed using
  /// non-[YamlNode] keys, but [Map.keys] and [Map.forEach] will always expose
  /// them as [YamlNode]s. For example, for `{"foo": [1, 2, 3]}` [nodes] will be
  /// a map from a [YamlScalar] to a [YamlList], but since the key type is
  /// `dynamic` `map.nodes["foo"]` will still work.
  final Map<dynamic, YamlNode> nodes;

  /// The style used for the map in the original document.
  final CollectionStyle style;

  @override
  Map get value => this;

  @override
  Iterable get keys => nodes.keys.map((node) => node.value);

  /// Creates an empty YamlMap.
  ///
  /// This map's [span] won't have useful location information. However, it will
  /// have a reasonable implementation of [SourceSpan.message]. If [sourceUrl]
  /// is passed, it's used as the [SourceSpan.sourceUrl].
  ///
  /// [sourceUrl] may be either a [String], a [Uri], or `null`.
  factory YamlMap({sourceUrl}) => YamlMapWrapper(const {}, sourceUrl);

  /// Wraps a Dart map so that it can be accessed (recursively) like a
  /// [YamlMap].
  ///
  /// Any [SourceSpan]s returned by this map or its children will be dummies
  /// without useful location information. However, they will have a reasonable
  /// implementation of [SourceSpan.getLocationMessage]. If [sourceUrl] is
  /// passed, it's used as the [SourceSpan.sourceUrl].
  ///
  /// [sourceUrl] may be either a [String], a [Uri], or `null`.
  factory YamlMap.wrap(Map dartMap,
          {sourceUrl, CollectionStyle style = CollectionStyle.ANY}) =>
      YamlMapWrapper(dartMap, sourceUrl, style: style);

  /// Users of the library should not use this constructor.
  YamlMap.internal(Map<dynamic, YamlNode> nodes, SourceSpan span, this.style)
      : nodes = UnmodifiableMapView<dynamic, YamlNode>(nodes),
        super._(span);

  @override
  dynamic operator [](Object? key) => nodes[key]?.value;
}

// TODO(nweiz): Use UnmodifiableListMixin when issue 18970 is fixed.
/// A read-only [List] parsed from YAML.
class YamlList extends YamlNode with collection.ListMixin {
  final List<YamlNode> nodes;

  /// The style used for the list in the original document.
  final CollectionStyle style;

  @override
  List get value => this;

  @override
  int get length => nodes.length;

  @override
  set length(int index) {
    throw UnsupportedError('Cannot modify an unmodifiable List');
  }

  /// Creates an empty YamlList.
  ///
  /// This list's [span] won't have useful location information. However, it
  /// will have a reasonable implementation of [SourceSpan.message]. If
  /// [sourceUrl] is passed, it's used as the [SourceSpan.sourceUrl].
  ///
  /// [sourceUrl] may be either a [String], a [Uri], or `null`.
  factory YamlList({sourceUrl}) => YamlListWrapper(const [], sourceUrl);

  /// Wraps a Dart list so that it can be accessed (recursively) like a
  /// [YamlList].
  ///
  /// Any [SourceSpan]s returned by this list or its children will be dummies
  /// without useful location information. However, they will have a reasonable
  /// implementation of [SourceSpan.getLocationMessage]. If [sourceUrl] is
  /// passed, it's used as the [SourceSpan.sourceUrl].
  ///
  /// [sourceUrl] may be either a [String], a [Uri], or `null`.
  factory YamlList.wrap(List dartList,
          {sourceUrl, CollectionStyle style = CollectionStyle.ANY}) =>
      YamlListWrapper(dartList, sourceUrl, style: style);

  /// Users of the library should not use this constructor.
  YamlList.internal(List<YamlNode> nodes, SourceSpan span, this.style)
      : nodes = UnmodifiableListView<YamlNode>(nodes),
        super._(span);

  @override
  dynamic operator [](int index) => nodes[index].value;

  @override
  void operator []=(int index, Object? value) {
    throw UnsupportedError('Cannot modify an unmodifiable List');
  }
}

/// A wrapped scalar value parsed from YAML.
class YamlScalar extends YamlNode {
  @override
  final dynamic value;

  /// The style used for the scalar in the original document.
  final ScalarStyle style;

  /// Wraps a Dart value in a [YamlScalar].
  ///
  /// This scalar's [span] won't have useful location information. However, it
  /// will have a reasonable implementation of [SourceSpan.message]. If
  /// [sourceUrl] is passed, it's used as the [SourceSpan.sourceUrl].
  ///
  /// [sourceUrl] may be either a [String], a [Uri], or `null`.
  YamlScalar.wrap(this.value, {sourceUrl, this.style = ScalarStyle.ANY})
      : super._(NullSpan(sourceUrl)) {
    ArgumentError.checkNotNull(style, 'style');
  }

  /// Users of the library should not use this constructor.
  YamlScalar.internal(this.value, ScalarEvent scalar)
      : style = scalar.style,
        super._(scalar.span);

  /// Users of the library should not use this constructor.
  YamlScalar.internalWithSpan(this.value, SourceSpan span)
      : style = ScalarStyle.ANY,
        super._(span);

  @override
  String toString() => value.toString();
}

/// Sets the source span of a [YamlNode].
///
/// This method is not exposed publicly.
void setSpan(YamlNode node, SourceSpan span) {
  node._span = span;
}
