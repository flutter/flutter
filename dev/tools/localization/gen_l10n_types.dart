// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class L10nException implements Exception {
  L10nException(this.message);

  final String message;
}

class OptionalParameter {
  const OptionalParameter(this.name, this.value) : assert(name != null), assert(value != null);

  final String name;
  final Object value;
}

class Placeholder {
  Placeholder(this.resourceId, this.name, Map<String, dynamic> attributes)
    : assert(resourceId != null),
      assert(name != null),
      example = _stringAttribute(resourceId, name, attributes, 'example'),
      type = _stringAttribute(resourceId, name, attributes, 'type') ?? 'Object',
      format = _stringAttribute(resourceId, name, attributes, 'format'),
      optionalParameters = _optionalParameters(resourceId, name, attributes);

  final String resourceId;
  final String name;
  final String example;
  final String type;
  final String format;
  final List<OptionalParameter> optionalParameters;

  bool get requiresFormatting => <String>['DateTime', 'double', 'int', 'num'].contains(type);
  bool get isNumber => <String>['double', 'int', 'num'].contains(type);
  bool get isDate => 'DateTime' == type;

  static String _stringAttribute(
    String resourceId,
    String name,
    Map<String, dynamic> attributes,
    String attributeName,
  ) {
    final dynamic value = attributes[attributeName];
    if (value == null)
      return null;
    if (value is! String || (value as String).isEmpty) {
      throw L10nException(
        'The "$attributeName" value of the "$name" placeholder in message $resourceId '
        'must be a non-empty string.',
      );
    }
    return value as String;
  }

  static List<OptionalParameter> _optionalParameters(
    String resourceId,
    String name,
    Map<String, dynamic> attributes
  ) {
    final dynamic value = attributes['optionalParameters'];
    if (value == null)
      return <OptionalParameter>[];
    if (value is! Map<String, Object>) {
      throw L10nException(
        'The "optionalParameters" value of the "$name" placeholder in message '
        '$resourceId is not a properly formatted Map. Ensure that it is a map '
        'with keys that are strings.'
      );
    }
    final Map<String, dynamic> optionalParameterMap = value as Map<String, dynamic>;
    return optionalParameterMap.keys.map<OptionalParameter>((String parameterName) {
      return OptionalParameter(parameterName, optionalParameterMap[parameterName]);
    }).toList();
  }
}

class Message {
  Message(Map<String, dynamic> bundle, this.resourceId)
    : assert(bundle != null),
      assert(resourceId != null && resourceId.isNotEmpty),
      value = _value(bundle, resourceId),
      description = _description(bundle, resourceId),
      placeholders = _placeholders(bundle, resourceId),
      _pluralMatch = _pluralRE.firstMatch(_value(bundle, resourceId));

  static final RegExp _pluralRE = RegExp(r'\s*\{([\w\s,]*),\s*plural\s*,');

  final String resourceId;
  final String value;
  final String description;
  final List<Placeholder> placeholders;
  final RegExpMatch _pluralMatch;

  bool get isPlural => _pluralMatch != null && _pluralMatch.groupCount == 1;

  bool get placeholdersRequireFormatting => placeholders.any((Placeholder p) => p.requiresFormatting);

  Placeholder getCountPlaceholder() {
    assert(isPlural);
    final String countPlaceholderName = _pluralMatch[1];
    return placeholders.firstWhere(
      (Placeholder p) => p.name == countPlaceholderName,
      orElse: () {
        throw L10nException('Cannot find the $countPlaceholderName placeholder in plural message "$resourceId".');
      }
    );
  }

  static String _value(Map<String, dynamic> bundle, String resourceId) {
    final dynamic value = bundle[resourceId];
    if (value == null)
      throw L10nException('A value for resource "$resourceId" was not found.');
    if (value is! String)
      throw L10nException('The value of "$resourceId" is not a string.');
    return bundle[resourceId] as String;
  }

  static Map<String, dynamic> _attributes(Map<String, dynamic> bundle, String resourceId) {
    final dynamic attributes = bundle['@$resourceId'];
    if (attributes == null) {
      throw L10nException(
        'Resource attribute "@$resourceId" was not found. Please '
        'ensure that each resource has a corresponding @resource.'
      );
    }
    if (attributes is! Map<String, dynamic>) {
      throw L10nException(
        'The resource attribute "@$resourceId" is not a properly formatted Map. '
        'Ensure that it is a map with keys that are strings.'
      );
    }
    return attributes as Map<String, dynamic>;
  }

  static String _description(Map<String, dynamic> bundle, String resourceId) {
    final dynamic value = _attributes(bundle, resourceId)['description'];
    if (value == null)
      return null;
    if (value is! String) {
      throw L10nException(
        'The description for "@$resourceId" is not a properly formatted String.'
      );
    }
    return value as String;
  }

  static List<Placeholder> _placeholders(Map<String, dynamic> bundle, String resourceId) {
    final dynamic value = _attributes(bundle, resourceId)['placeholders'];
    if (value == null)
      return <Placeholder>[];
    if (value is! Map<String, dynamic>) {
      throw L10nException(
        'The "placeholders" attribute for message $resourceId, is not '
        'properly formatted. Ensure that it is a map with string valued keys.'
      );
    }
    final Map<String, dynamic> allPlaceholdersMap = value as Map<String, dynamic>;
    return allPlaceholdersMap.keys.map<Placeholder>((String placeholderName) {
      final dynamic value = allPlaceholdersMap[placeholderName];
      if (value is! Map<String, dynamic>) {
        throw L10nException(
          'The value of the "$placeholderName" placeholder attribute for message '
          '"$resourceId", is not properly formatted. Ensure that it is a map '
          'with string valued keys.'
        );
      }
      return Placeholder(resourceId, placeholderName, value as Map<String, dynamic>);
    }).toList();
  }
}
