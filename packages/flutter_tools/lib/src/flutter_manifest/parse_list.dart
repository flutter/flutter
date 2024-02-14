// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:yaml/yaml.dart';

import 'parse_result.dart';

ParseResult<List<T>> parseList<T>(Object? yamlList, String context, String typeAlias) {
  final List<T> result = <T>[];
  final List<String> errors = <String>[];

  if (yamlList is! YamlList) {
    return ErrorParseResult<List<T>>(
      <String>['Expected $context to be a list of $typeAlias, but got $yamlList (${yamlList.runtimeType}).']
    );
  }

  for (final (int i, Object? item) in yamlList.indexed) {
    if (item is! T) {
      // ignore: avoid_dynamic_calls
      errors.add('Expected $context to be a list of $typeAlias, but element at index $i was a ${yamlList[i].runtimeType}.');
    } else {
      result.add(item);
    }
  }

  if (errors.isEmpty) {
    return ValueParseResult<List<T>>(result);
  }
  return ErrorParseResult<List<T>>(errors);
}
