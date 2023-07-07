// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dds/src/dap/protocol_special.dart';

class JsonSchema {
  late final Uri dollarSchema;
  late final Map<String, JsonType> definitions;

  JsonSchema.fromJson(Map<String, Object?> json) {
    dollarSchema = Uri.parse(json[r'$schema'] as String);
    definitions = (json['definitions'] as Map<String, Object?>).map((key,
            value) =>
        MapEntry(key, JsonType.fromJson(this, value as Map<String, Object?>)));
  }
}

class JsonType {
  final JsonSchema root;
  final List<JsonType>? allOf;
  final List<JsonType>? oneOf;
  final String? description;
  final String? dollarRef;
  final List<String>? enumValues;
  final JsonType? items;
  final Map<String, JsonType>? properties;
  final List<String>? required;
  final String? title;
  final Either2<String, List<String>>? type;

  JsonType.empty(this.root)
      : allOf = null,
        oneOf = null,
        description = null,
        dollarRef = null,
        enumValues = null,
        items = null,
        properties = null,
        required = null,
        title = null,
        type = null;

  JsonType.fromJson(this.root, Map<String, Object?> json)
      : allOf = json['allOf'] == null
            ? null
            : (json['allOf'] as List<Object?>)
                .cast<Map<String, Object?>>()
                .map((item) => JsonType.fromJson(root, item))
                .toList(),
        description = json['description'] as String?,
        dollarRef = json[r'$ref'] as String?,
        enumValues = (json['enum'] as List<Object?>?)?.cast<String>(),
        items = json['items'] == null
            ? null
            : JsonType.fromJson(root, json['items'] as Map<String, Object?>),
        oneOf = json['oneOf'] == null
            ? null
            : (json['oneOf'] as List<Object?>)
                .cast<Map<String, Object?>>()
                .map((item) => JsonType.fromJson(root, item))
                .toList(),
        properties = json['properties'] == null
            ? null
            : (json['properties'] as Map<String, Object?>).map((key, value) =>
                MapEntry(key,
                    JsonType.fromJson(root, value as Map<String, Object?>))),
        required = (json['required'] as List<Object?>?)?.cast<String>(),
        title = json['title'] as String?,
        type = json['type'] == null
            ? null
            : json['type'] is String
                ? Either2<String, List<String>>.t1(json['type'] as String)
                : Either2<String, List<String>>.t2(
                    (json['type'] as List<Object?>).cast<String>());

  /// Creates a dummy type to represent a type that exists outside of the
  /// generated code (in 'lib/src/dap/protocol_common.dart').
  JsonType.named(this.root, String name)
      : allOf = null,
        oneOf = null,
        description = null,
        dollarRef = '#/definitions/$name',
        enumValues = null,
        items = null,
        properties = null,
        required = null,
        title = null,
        type = null;
}
