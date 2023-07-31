// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

// ignore: import_of_legacy_library_into_null_safe
import 'package:uri/uri.dart';

abstract class Jsonable {
  toJson();
}

JsonBuilder get buildJson => JsonBuilder();
JsonParser parseJson(Map? j, {bool consumeMap: false}) =>
    JsonParser(j, consumeMap);

class JsonBuilder {
  final bool _stringEmpties;
  JsonBuilder({bool stringEmpties: true}) : this._stringEmpties = stringEmpties;

  final Map json = {};

//  void addObject(String fieldName, o) {
//    if (o != null) {
//      json[fieldName] = o.toJson();
//    }
//  }

  void add(String fieldName, v, [transform(v)?]) {
    if (v != null) {
      final transformed = _transformValue(v, transform);
      if (transformed != null) {
        json[fieldName] = transformed;
      }
    }
  }

  void addAll(Map map) {
    json.addAll(map);
  }

  _transformValue(value, [transform(v)?]) {
    if (transform != null) {
      return transform(value);
    }
    if (value is Jsonable) {
      return value.toJson();
    }
    if (value is Map) {
      final result = {};
      value.forEach((k, v) {
        final transformedValue = _transformValue(v);
        final transformedKey = _transformValue(k);
        if (transformedValue != null && transformedKey != null) {
          result[transformedKey] = transformedValue;
        }
      });
      return result.isNotEmpty || !_stringEmpties ? result : null;
    }
    if (value is Iterable) {
      final list = value.map((v) => _transformValue(v, null)).toList();
      return list.isNotEmpty || !_stringEmpties ? list : null;
    }
    if (value is RegExp) {
      return value.pattern;
    }
    if (value is UriTemplate) {
      return value.template;
    }
    if (value is DateTime) {
      return value.toIso8601String();
    }
    if (value is bool || value is num) {
      return value;
    }
    return value.toString();
  }
}

typedef T Converter<T>(value);

Converter<T> _converter<T>(Converter<T>? convert) => convert ?? ((v) => v as T);

class JsonParser {
  final Map? _json;
  final bool _consumeMap;

  JsonParser(Map? json, bool consumeMap)
      : this._json = consumeMap ? Map.from(json!) : json,
        this._consumeMap = consumeMap;

  List<T> list<T>(String fieldName, [Converter<T>? create]) {
    final List? l = _getField(fieldName);
    return l != null ? l.map(_converter(create)).toList(growable: false) : [];
  }

  T? single<T>(String fieldName, [T create(i)?]) {
    final j = _getField(fieldName);
    return j != null ? _converter(create)(j) : null;
  }

  Map<K, V> mapValues<K, V>(String fieldName,
      [Converter<V>? convertValue, Converter<K>? convertKey]) {
    final Map? m = _getField(fieldName);

    if (m == null) {
      return {};
    }

    Converter<K> _convertKey = _converter(convertKey);
    Converter<V> _convertValue = _converter(convertValue);

    Map<K, V> result = Map<K, V>();
    m.forEach((k, v) {
      result[_convertKey(k)] = _convertValue(v);
    });

    return result;
  }

  Map<K, V> mapEntries<K, V, T>(
      String fieldName, V Function(K k, T v) convert) {
    final Map? m = _getField(fieldName);

    if (m == null) {
      return {};
    }

    Map<K, V> result = Map<K, V>();
    m.forEach((k, v) {
      result[k] = convert(k, v);
    });

    return result;
  }

  T? _getField<T>(String fieldName) =>
      (_consumeMap ? _json!.remove(fieldName) : _json![fieldName]);

  Map? get unconsumed {
    if (!_consumeMap) {
      throw StateError('unconsumed called on non consuming parser');
    }

    return _json;
  }
}
