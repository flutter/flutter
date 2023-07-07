// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:source_span/source_span.dart';
import 'package:yaml/src/event.dart';
import 'package:yaml/yaml.dart';

bool _contains(YamlList l1, YamlNode n2) {
  for (YamlNode n1 in l1.nodes) {
    if (n1.value == n2.value) {
      return true;
    }
  }
  return false;
}

/// Merges two maps (of yaml) with simple override semantics, suitable for
/// merging two maps where one map defines default values that are added to
/// (and possibly overridden) by an overriding map.
class Merger {
  /// Merges a default [o1] with an overriding object [o2].
  ///
  ///   * lists are merged (without duplicates).
  ///   * lists of scalar values can be promoted to simple maps when merged with
  ///     maps of strings to booleans (e.g., ['opt1', 'opt2'] becomes
  ///     {'opt1': true, 'opt2': true}.
  ///   * maps are merged recursively.
  ///   * if map values cannot be merged, the overriding value is taken.
  ///
  YamlNode merge(YamlNode o1, YamlNode o2) {
    // Handle promotion first.
    YamlMap listToMap(YamlList list) {
      Map<YamlNode, YamlNode> map =
          HashMap<YamlNode, YamlNode>(); // equals: _equals, hashCode: _hashCode
      ScalarEvent event =
          ScalarEvent(o1.span as FileSpan, 'true', ScalarStyle.PLAIN);
      for (var element in list.nodes) {
        map[element] = YamlScalar.internal(true, event);
      }
      return YamlMap.internal(map, o1.span, CollectionStyle.BLOCK);
    }

    if (_isListOfString(o1) && _isMapToBools(o2)) {
      o1 = listToMap(o1 as YamlList);
    } else if (_isMapToBools(o1) && _isListOfString(o2)) {
      o2 = listToMap(o2 as YamlList);
    }

    if (o1 is YamlMap && o2 is YamlMap) {
      return mergeMap(o1, o2);
    }
    if (o1 is YamlList && o2 is YamlList) {
      return mergeList(o1, o2);
    }
    // Default to override, unless the overriding value is `null`.
    if (o2 is YamlScalar && o2.value == null) {
      return o1;
    }
    return o2;
  }

  /// Merge lists, avoiding duplicates.
  YamlList mergeList(YamlList l1, YamlList l2) {
    List<YamlNode> list = <YamlNode>[];
    list.addAll(l1.nodes);
    for (YamlNode n2 in l2.nodes) {
      if (!_contains(l1, n2)) {
        list.add(n2);
      }
    }
    return YamlList.internal(list, l1.span, CollectionStyle.BLOCK);
  }

  /// Merge maps (recursively).
  YamlMap mergeMap(YamlMap m1, YamlMap m2) {
    Map<YamlNode, YamlNode> merged =
        HashMap<YamlNode, YamlNode>(); // equals: _equals, hashCode: _hashCode
    m1.nodeMap.forEach((k, v) {
      merged[k] = v;
    });
    m2.nodeMap.forEach((k, v) {
      var value = k.value;
      var mergedKey =
          merged.keys.firstWhere((key) => key.value == value, orElse: () => k)
              as YamlScalar;
      var o1 = merged[mergedKey];
      if (o1 != null) {
        merged[mergedKey] = merge(o1, v);
      } else {
        merged[mergedKey] = v;
      }
    });
    return YamlMap.internal(merged, m1.span, CollectionStyle.BLOCK);
  }

  static bool _isListOfString(Object? o) =>
      o is YamlList &&
      o.nodes.every((e) => e is YamlScalar && e.value is String);

  static bool _isMapToBools(Object? o) =>
      o is YamlMap &&
      o.nodes.values.every((v) => v is YamlScalar && v.value is bool);
}

extension YamlMapExtensions on YamlMap {
  /// Return [nodes] as a Map with [YamlNode] keys.
  Map<YamlNode, YamlNode> get nodeMap => nodes.cast<YamlNode, YamlNode>();

  /// Return the [YamlNode] associated with the given [key], or `null` if there
  /// is no matching key.
  YamlNode? getKey(String key) {
    for (YamlNode k in nodes.keys) {
      if (k is YamlScalar && k.value == key) {
        return k;
      }
    }
    return null;
  }

  /// Return the [YamlNode] representing the key that corresponds to the value
  /// represented by the [value] node.
  YamlNode? keyAtValue(YamlNode value) {
    for (var entry in nodes.entries) {
      if (entry.value == value) {
        return entry.key;
      }
    }
    return null;
  }

  /// Return the value associated with the key whose value matches the given
  /// [key], or `null` if there is no matching key.
  YamlNode? valueAt(String key) {
    for (var keyNode in nodes.keys) {
      if (keyNode is YamlScalar && keyNode.value == key) {
        return nodes[keyNode];
      }
    }
    return null;
  }
}
