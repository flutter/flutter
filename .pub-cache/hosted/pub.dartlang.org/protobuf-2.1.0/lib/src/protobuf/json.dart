// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of protobuf;

Map<String, dynamic> _writeToJsonMap(_FieldSet fs) {
  dynamic convertToMap(dynamic fieldValue, int fieldType) {
    var baseType = PbFieldType._baseType(fieldType);

    if (_isRepeated(fieldType)) {
      return List.from(fieldValue.map((e) => convertToMap(e, baseType)));
    }

    switch (baseType) {
      case PbFieldType._BOOL_BIT:
      case PbFieldType._STRING_BIT:
      case PbFieldType._INT32_BIT:
      case PbFieldType._SINT32_BIT:
      case PbFieldType._UINT32_BIT:
      case PbFieldType._FIXED32_BIT:
      case PbFieldType._SFIXED32_BIT:
        return fieldValue;
      case PbFieldType._FLOAT_BIT:
      case PbFieldType._DOUBLE_BIT:
        final value = fieldValue as double;
        if (value.isNaN) {
          return nan;
        }
        if (value.isInfinite) {
          return value.isNegative ? negativeInfinity : infinity;
        }
        if (fieldValue.toInt() == fieldValue) {
          return fieldValue.toInt();
        }
        return value;
      case PbFieldType._BYTES_BIT:
        // Encode 'bytes' as a base64-encoded string.
        return base64Encode(fieldValue as List<int>);
      case PbFieldType._ENUM_BIT:
        return fieldValue.value; // assume |value| < 2^52
      case PbFieldType._INT64_BIT:
      case PbFieldType._SINT64_BIT:
      case PbFieldType._SFIXED64_BIT:
        return fieldValue.toString();
      case PbFieldType._UINT64_BIT:
      case PbFieldType._FIXED64_BIT:
        return fieldValue.toStringUnsigned();
      case PbFieldType._GROUP_BIT:
      case PbFieldType._MESSAGE_BIT:
        return fieldValue.writeToJsonMap();
      default:
        throw 'Unknown type $fieldType';
    }
  }

  List _writeMap(dynamic fieldValue, MapFieldInfo fi) =>
      List.from(fieldValue.entries.map((MapEntry e) => {
            '${PbMap._keyFieldNumber}': convertToMap(e.key, fi.keyFieldType),
            '${PbMap._valueFieldNumber}':
                convertToMap(e.value, fi.valueFieldType)
          }));

  var result = <String, dynamic>{};
  for (var fi in fs._infosSortedByTag) {
    var value = fs._values[fi.index!];
    if (value == null || (value is List && value.isEmpty)) {
      continue; // It's missing, repeated, or an empty byte array.
    }
    if (_isMapField(fi.type)) {
      result['${fi.tagNumber}'] =
          _writeMap(value, fi as MapFieldInfo<dynamic, dynamic>);
      continue;
    }
    result['${fi.tagNumber}'] = convertToMap(value, fi.type);
  }
  if (fs._hasExtensions) {
    for (var tagNumber in _sorted(fs._extensions!._tagNumbers)) {
      var value = fs._extensions!._values[tagNumber];
      if (value is List && value.isEmpty) {
        continue; // It's repeated or an empty byte array.
      }
      var fi = fs._extensions!._getInfoOrNull(tagNumber)!;
      result['$tagNumber'] = convertToMap(value, fi.type);
    }
  }
  return result;
}

// Merge fields from a previously decoded JSON object.
// (Called recursively on nested messages.)
void _mergeFromJsonMap(
    _FieldSet fs, Map<String, dynamic> json, ExtensionRegistry? registry) {
  final keys = json.keys;
  final meta = fs._meta;
  for (var key in keys) {
    var fi = meta.byTagAsString[key];
    if (fi == null) {
      if (registry == null) continue; // Unknown tag; skip
      fi = registry.getExtension(fs._messageName, int.parse(key));
      if (fi == null) continue; // Unknown tag; skip
    }
    if (fi.isMapField) {
      _appendJsonMap(
          meta, fs, json[key], fi as MapFieldInfo<dynamic, dynamic>, registry);
    } else if (fi.isRepeated) {
      _appendJsonList(meta, fs, json[key], fi, registry);
    } else {
      _setJsonField(meta, fs, json[key], fi, registry);
    }
  }
}

void _appendJsonList(BuilderInfo meta, _FieldSet fs, List jsonList,
    FieldInfo fi, ExtensionRegistry? registry) {
  final repeated = fi._ensureRepeatedField(meta, fs);
  // Micro optimization. Using "for in" generates the following and iterator
  // alloc:
  //   for (t1 = J.get$iterator$ax(json), t2 = fi.tagNumber, t3 = fi.type,
  //       t4 = J.getInterceptor$ax(repeated); t1.moveNext$0();)
  for (var i = 0, len = jsonList.length; i < len; i++) {
    var value = jsonList[i];
    var convertedValue =
        _convertJsonValue(meta, fs, value, fi.tagNumber, fi.type, registry);
    // In the case of an unknown enum value, the converted value may return
    // null. The default enum value should be used in these cases, which is
    // stored in the FieldInfo.
    convertedValue ??= fi.defaultEnumValue;
    repeated.add(convertedValue);
  }
}

void _appendJsonMap(BuilderInfo meta, _FieldSet fs, List jsonList,
    MapFieldInfo fi, ExtensionRegistry? registry) {
  final entryMeta = fi.mapEntryBuilderInfo;
  final map = fi._ensureMapField(meta, fs) as PbMap<dynamic, dynamic>;
  for (var jsonEntryDynamic in jsonList) {
    var jsonEntry = jsonEntryDynamic as Map<String, dynamic>;
    final entryFieldSet = _FieldSet(null, entryMeta, null);
    final convertedKey = _convertJsonValue(
        entryMeta,
        entryFieldSet,
        jsonEntry['${PbMap._keyFieldNumber}'],
        PbMap._keyFieldNumber,
        fi.keyFieldType,
        registry);
    var convertedValue = _convertJsonValue(
        entryMeta,
        entryFieldSet,
        jsonEntry['${PbMap._valueFieldNumber}'],
        PbMap._valueFieldNumber,
        fi.valueFieldType,
        registry);
    // In the case of an unknown enum value, the converted value may return
    // null. The default enum value should be used in these cases, which is
    // stored in the FieldInfo.
    convertedValue ??= fi.defaultEnumValue;
    map[convertedKey] = convertedValue;
  }
}

void _setJsonField(BuilderInfo meta, _FieldSet fs, json, FieldInfo fi,
    ExtensionRegistry? registry) {
  final value =
      _convertJsonValue(meta, fs, json, fi.tagNumber, fi.type, registry);
  if (value == null) return;
  // _convertJsonValue throws exception when it fails to do conversion.
  // Therefore we run _validateField for debug builds only to validate
  // correctness of conversion.
  assert(() {
    fs._validateField(fi, value);
    return true;
  }());
  fs._setFieldUnchecked(meta, fi, value);
}

/// Converts [value] from the JSON format to the Dart data type suitable for
/// inserting into the corresponding [GeneratedMessage] field.
///
/// Returns the converted value. Returns `null` if it is an unknown enum value,
/// in which case the caller should figure out the default enum value to return
/// instead.
///
/// Throws [ArgumentError] if it cannot convert the value.
dynamic _convertJsonValue(BuilderInfo meta, _FieldSet fs, value, int tagNumber,
    int fieldType, ExtensionRegistry? registry) {
  String expectedType; // for exception message
  switch (PbFieldType._baseType(fieldType)) {
    case PbFieldType._BOOL_BIT:
      if (value is bool) {
        return value;
      } else if (value is String) {
        if (value == 'true') {
          return true;
        } else if (value == 'false') {
          return false;
        }
      } else if (value is num) {
        if (value == 1) {
          return true;
        } else if (value == 0) {
          return false;
        }
      }
      expectedType = 'bool (true, false, "true", "false", 1, 0)';
      break;
    case PbFieldType._BYTES_BIT:
      if (value is String) {
        return base64Decode(value);
      }
      expectedType = 'Base64 String';
      break;
    case PbFieldType._STRING_BIT:
      if (value is String) {
        return value;
      }
      expectedType = 'String';
      break;
    case PbFieldType._FLOAT_BIT:
    case PbFieldType._DOUBLE_BIT:
      // Allow quoted values, although we don't emit them.
      if (value is double) {
        return value;
      } else if (value is num) {
        return value.toDouble();
      } else if (value is String) {
        return double.parse(value);
      }
      expectedType = 'num or stringified num';
      break;
    case PbFieldType._ENUM_BIT:
      // Allow quoted values, although we don't emit them.
      if (value is String) {
        value = int.parse(value);
      }
      if (value is int) {
        // The following call will return null if the enum value is unknown.
        // In that case, we want the caller to ignore this value, so we return
        // null from this method as well.
        return meta._decodeEnum(tagNumber, registry, value);
      }
      expectedType = 'int or stringified int';
      break;
    case PbFieldType._INT32_BIT:
    case PbFieldType._SINT32_BIT:
    case PbFieldType._UINT32_BIT:
    case PbFieldType._SFIXED32_BIT:
      if (value is int) return value;
      if (value is String) return int.parse(value);
      expectedType = 'int or stringified int';
      break;
    case PbFieldType._FIXED32_BIT:
      int? validatedValue;
      if (value is int) validatedValue = value;
      if (value is String) validatedValue = int.parse(value);
      if (validatedValue != null && validatedValue < 0) {
        validatedValue += 2 * (1 << 31);
      }
      if (validatedValue != null) return validatedValue;
      expectedType = 'int or stringified int';
      break;
    case PbFieldType._INT64_BIT:
    case PbFieldType._SINT64_BIT:
    case PbFieldType._UINT64_BIT:
    case PbFieldType._FIXED64_BIT:
    case PbFieldType._SFIXED64_BIT:
      if (value is int) return Int64(value);
      if (value is String) return Int64.parseInt(value);
      expectedType = 'int or stringified int';
      break;
    case PbFieldType._GROUP_BIT:
    case PbFieldType._MESSAGE_BIT:
      if (value is Map) {
        final messageValue = value as Map<String, dynamic>;
        var subMessage = meta._makeEmptyMessage(tagNumber, registry);
        _mergeFromJsonMap(subMessage._fieldSet, messageValue, registry);
        return subMessage;
      }
      expectedType = 'nested message or group';
      break;
    default:
      throw ArgumentError('Unknown type $fieldType');
  }
  throw ArgumentError('Expected type $expectedType, got $value');
}
