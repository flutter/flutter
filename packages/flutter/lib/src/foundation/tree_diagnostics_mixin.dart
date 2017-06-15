// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

/// A mixin that helps dump string representations of trees.
abstract class TreeDiagnosticsMixin {
  // This class is intended to be used as a mixin, and should not be
  // extended directly.
  factory TreeDiagnosticsMixin._() => null;

  @override
  String toString() => '$runtimeType#$hashCode';

  /// Returns a string representation of this node and its descendants.
  String toStringDeep([String prefixLineOne = '', String prefixOtherLines = '']) {
    String result = '$prefixLineOne$this\n';
    final String childrenDescription = debugDescribeChildren(prefixOtherLines);
    final String descriptionPrefix = childrenDescription != '' ? '$prefixOtherLines \u2502 ' : '$prefixOtherLines   ';
    final List<String> description = <String>[];
    debugFillDescription(description);
    result += description.map((String description) => '$descriptionPrefix$description\n').join();
    if (childrenDescription == '') {
      final String prefix = prefixOtherLines.trimRight();
      if (prefix != '')
        result += '$prefix\n';
    } else {
      result += childrenDescription;
    }
    return result;
  }

  /// Add additional information to the given description for use by [toStringDeep].
  @protected
  @mustCallSuper
  void debugFillDescription(List<String> description) { }

  /// Returns a description of this node's children for use by [toStringDeep].
  @protected
  String debugDescribeChildren(String prefix) => '';
}
