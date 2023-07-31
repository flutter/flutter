// Copyright (c) 2014, the Dart project authors.
// Copyright (c) 2006, Kirill Simonov.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

import 'dart:collection';

import 'package:collection/collection.dart' as pkg_collection;
import 'package:source_span/source_span.dart';

import 'null_span.dart';
import 'style.dart';
import 'yaml_node.dart';

/// A wrapper that makes a normal Dart map behave like a [YamlMap].
class YamlMapWrapper extends MapBase
    with pkg_collection.UnmodifiableMapMixin
    implements YamlMap {
  @override
  final CollectionStyle style;

  final Map _dartMap;

  @override
  final SourceSpan span;

  @override
  final Map<dynamic, YamlNode> nodes;

  @override
  Map get value => this;

  @override
  Iterable get keys => _dartMap.keys;

  YamlMapWrapper(Map dartMap, sourceUrl,
      {CollectionStyle style = CollectionStyle.ANY})
      : this._(dartMap, NullSpan(sourceUrl), style: style);

  YamlMapWrapper._(Map dartMap, this.span, {this.style = CollectionStyle.ANY})
      : _dartMap = dartMap,
        nodes = _YamlMapNodes(dartMap, span) {
    ArgumentError.checkNotNull(style, 'style');
  }

  @override
  dynamic operator [](Object? key) {
    var value = _dartMap[key];
    if (value is Map) return YamlMapWrapper._(value, span);
    if (value is List) return YamlListWrapper._(value, span);
    return value;
  }

  @override
  int get hashCode => _dartMap.hashCode;

  @override
  bool operator ==(Object other) =>
      other is YamlMapWrapper && other._dartMap == _dartMap;
}

/// The implementation of [YamlMapWrapper.nodes] as a wrapper around the Dart
/// map.
class _YamlMapNodes extends MapBase<dynamic, YamlNode>
    with pkg_collection.UnmodifiableMapMixin<dynamic, YamlNode> {
  final Map _dartMap;

  final SourceSpan _span;

  @override
  Iterable get keys =>
      _dartMap.keys.map((key) => YamlScalar.internalWithSpan(key, _span));

  _YamlMapNodes(this._dartMap, this._span);

  @override
  YamlNode? operator [](Object? key) {
    // Use "as" here because key being assigned to invalidates type propagation.
    if (key is YamlScalar) key = key.value;
    if (!_dartMap.containsKey(key)) return null;
    return _nodeForValue(_dartMap[key], _span);
  }

  @override
  int get hashCode => _dartMap.hashCode;

  @override
  bool operator ==(Object other) =>
      other is _YamlMapNodes && other._dartMap == _dartMap;
}

// TODO(nweiz): Use UnmodifiableListMixin when issue 18970 is fixed.
/// A wrapper that makes a normal Dart list behave like a [YamlList].
class YamlListWrapper extends ListBase implements YamlList {
  @override
  final CollectionStyle style;

  final List _dartList;

  @override
  final SourceSpan span;

  @override
  final List<YamlNode> nodes;

  @override
  List get value => this;

  @override
  int get length => _dartList.length;

  @override
  set length(int index) {
    throw UnsupportedError('Cannot modify an unmodifiable List.');
  }

  YamlListWrapper(List dartList, sourceUrl,
      {CollectionStyle style = CollectionStyle.ANY})
      : this._(dartList, NullSpan(sourceUrl), style: style);

  YamlListWrapper._(List dartList, this.span,
      {this.style = CollectionStyle.ANY})
      : _dartList = dartList,
        nodes = _YamlListNodes(dartList, span) {
    ArgumentError.checkNotNull(style, 'style');
  }

  @override
  dynamic operator [](int index) {
    var value = _dartList[index];
    if (value is Map) return YamlMapWrapper._(value, span);
    if (value is List) return YamlListWrapper._(value, span);
    return value;
  }

  @override
  void operator []=(int index, Object? value) {
    throw UnsupportedError('Cannot modify an unmodifiable List.');
  }

  @override
  int get hashCode => _dartList.hashCode;

  @override
  bool operator ==(Object other) =>
      other is YamlListWrapper && other._dartList == _dartList;
}

// TODO(nweiz): Use UnmodifiableListMixin when issue 18970 is fixed.
/// The implementation of [YamlListWrapper.nodes] as a wrapper around the Dart
/// list.
class _YamlListNodes extends ListBase<YamlNode> {
  final List _dartList;

  final SourceSpan _span;

  @override
  int get length => _dartList.length;

  @override
  set length(int index) {
    throw UnsupportedError('Cannot modify an unmodifiable List.');
  }

  _YamlListNodes(this._dartList, this._span);

  @override
  YamlNode operator [](int index) => _nodeForValue(_dartList[index], _span);

  @override
  void operator []=(int index, Object? value) {
    throw UnsupportedError('Cannot modify an unmodifiable List.');
  }

  @override
  int get hashCode => _dartList.hashCode;

  @override
  bool operator ==(Object other) =>
      other is _YamlListNodes && other._dartList == _dartList;
}

YamlNode _nodeForValue(value, SourceSpan span) {
  if (value is Map) return YamlMapWrapper._(value, span);
  if (value is List) return YamlListWrapper._(value, span);
  return YamlScalar.internalWithSpan(value, span);
}
