// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/exhaustiveness/static_type.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/static_types.dart';

class TestEnvironment {
  late final _TypeOperations _typeOperations = new _TypeOperations(this);
  late final _EnumOperations _enumOperations = new _EnumOperations();
  late final _SealedClassOperations _sealedClassOperations =
      new _SealedClassOperations(this);
  late final _ExhaustivenessCache _exhaustivenessCache =
      new _ExhaustivenessCache(
          _typeOperations, _enumOperations, _sealedClassOperations);

  TestEnvironment() {
    _addClass(_Class.Object);
    _addClass(_Class.Never);
    _addClass(_Class.Bool);
  }

  Map<String, _Class> _classes = {};
  Map<_Class, Map<String, _Type>> _fields = {};
  Map<_Class, Set<_InterfaceType>> _supertypes = {};
  Map<_Class, Set<_InterfaceType>> _subtypes = {};

  void _addClass(_Class cls) {
    assert(!_classes.containsKey(cls.name), "Duplicate class '${cls.name}'");
    _classes[cls.name] = cls;
  }

  void _addSupertype(_InterfaceType type, _InterfaceType supertype) {
    (_supertypes[type.cls] ??= {}).add(supertype);
    (_subtypes[supertype.cls] ??= {}).add(type);
  }

  _Type _typeFromStaticType(StaticType type) {
    if (type is TypeBasedStaticType<_Type>) {
      return type.typeForTesting;
    } else if (type is NullableStaticType) {
      return new _NullableType(_typeFromStaticType(type.underlying));
    } else if (type == StaticType.nullType) {
      return _Type.Null;
    } else if (type == StaticType.nonNullableObject) {
      return _Type.Object;
    } else if (type == StaticType.nullableObject) {
      return _Type.NullableObject;
    } else if (type == StaticType.neverType) {
      return _Type.Never;
    }
    throw new UnsupportedError(
        "Unexpected StaticType $type (${type.runtimeType}).");
  }

  Set<_InterfaceType> _getSupertypes(_Class cls) {
    return _supertypes[cls] ?? const {};
  }

  Set<_InterfaceType> _getSubtypes(_Class cls) {
    return _subtypes[cls] ?? const {};
  }

  Map<String, _Type> _getFields(_Class cls) {
    return _fields[cls] ?? const {};
  }

  StaticType createClass(String name,
      {bool isSealed = false,
      List<StaticType> inherits = const [],
      Map<String, StaticType> fields = const {}}) {
    _Class cls = new _Class(name, isSealed: isSealed);
    _addClass(cls);
    _InterfaceType type = new _InterfaceType(cls);
    _addSupertype(type, _Type.Object);
    for (StaticType inherit in inherits) {
      _Type supertype = _typeFromStaticType(inherit);
      if (supertype is _InterfaceType) {
        _addSupertype(type, supertype);
      } else {
        throw new UnsupportedError(
            "Unexpected supertype $supertype (${supertype.runtimeType}).");
      }
    }

    if (fields.isNotEmpty) {
      Map<String, _Type> fieldMap = _fields[cls] ??= {};
      for (MapEntry<String, StaticType> entry in fields.entries) {
        assert(!fieldMap.containsKey(entry.key),
            "Duplicate field '${entry.key}' in $cls.");
        fieldMap[entry.key] = _typeFromStaticType(entry.value);
      }
    }

    int sealed = 0;
    for (_InterfaceType supertype in _getSupertypes(cls)) {
      if (supertype.cls.isSealed) sealed++;
    }

    // We don't allow a sealed type's subtypes to be shared with some other
    // sibling supertype, as in D here:
    //
    //   (A) (B)
    //   / \ / \
    //  C   D   E
    //
    // We could remove this restriction but doing so will require
    // expandTypes() to be more complex. In the example here, if we subtract
    // E from A, the result should be C|D. That requires knowing that B should
    // be expanded, which expandTypes() doesn't currently handle.
    if (sealed > 1) {
      throw new ArgumentError('Can only have one sealed supertype.');
    }

    return _exhaustivenessCache.getStaticType(type);
  }

  StaticType createRecordType(Map<String, StaticType> named) {
    Map<String, _Type> namedTypes = {};
    for (MapEntry<String, StaticType> entry in named.entries) {
      namedTypes[entry.key] = _typeFromStaticType(entry.value);
    }
    _Type type = new _RecordType([], namedTypes);
    return _exhaustivenessCache.getStaticType(type);
  }
}

class _Type {
  static const _InterfaceType Object = _InterfaceType(_Class.Object);
  static const _Type NullableObject = _NullableType(_Type.Object);
  static const _InterfaceType Never = _InterfaceType(_Class.Never);
  static const _InterfaceType Bool = _InterfaceType(_Class.Bool);
  static const _Type Null = _NullableType(_Type.Never);
}

class _Class {
  final String name;
  final bool isSealed;

  const _Class(this.name, {this.isSealed = false});

  @override
  String toString() => name;

  static const _Class Object = const _Class('Object');
  static const _Class Bool = const _Class('bool');
  static const _Class Never = const _Class('Never');
}

class _EnumClass extends _Class {
  _EnumClass(super.name, {required super.isSealed});
}

// TODO(johnniwinther): Support testing of enums elements.
typedef _EnumElement = Object;

// TODO(johnniwinther): Support testing of enums element values.
typedef _EnumElementValue = Object;

class _InterfaceType implements _Type {
  final _Class cls;

  const _InterfaceType(this.cls);

  @override
  int get hashCode => cls.hashCode;

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    return other is _InterfaceType && cls == other.cls;
  }

  @override
  String toString() => cls.name;
}

class _NullableType implements _Type {
  final _Type type;

  const _NullableType(this.type);

  @override
  int get hashCode => type.hashCode;

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    return other is _NullableType && type == other.type;
  }

  @override
  String toString() => identical(this, _Type.Null) ? 'Null' : '$type?';
}

class _RecordType implements _Type {
  final List<_Type> positional;
  final Map<String, _Type> named;

  _RecordType(this.positional, this.named);

  @override
  int get hashCode => Object.hash(
      Object.hashAll(positional),
      Object.hashAllUnordered(named.keys),
      Object.hashAllUnordered(named.values));

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! _RecordType) return false;
    if (positional.length != other.positional.length) return false;
    if (named.length != other.named.length) return false;
    for (int i = 0; i < positional.length; i++) {
      if (positional[i] != other.positional[i]) {
        return false;
      }
    }
    for (MapEntry<String, _Type> entry in named.entries) {
      if (entry.value != other.named[entry.key]) return false;
    }
    return true;
  }

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('(');
    String comma = '';
    for (_Type type in positional) {
      sb.write(comma);
      sb.write(type);
      comma = ', ';
    }
    if (named.isNotEmpty) {
      sb.write(comma);
      sb.write('{');
      comma = '';
      for (MapEntry<String, _Type> entry in named.entries) {
        sb.write(comma);
        sb.write(entry.key);
        sb.write(': ');
        sb.write(entry.value);
        comma = ', ';
      }
      sb.write('}');
    }
    sb.write(')');
    return sb.toString();
  }
}

class _TypeOperations implements TypeOperations<_Type> {
  final TestEnvironment env;

  _TypeOperations(this.env);

  @override
  _Type get boolType => _Type.Bool;

  @override
  Map<String, _Type> getFieldTypes(_Type type) {
    if (type is _InterfaceType) {
      Map<String, _Type> fields = {};
      for (_InterfaceType supertype in env._getSupertypes(type.cls)) {
        fields.addAll(getFieldTypes(supertype));
      }
      fields.addAll(env._getFields(type.cls));
      return fields;
    } else if (type is _RecordType) {
      Map<String, _Type> fields = {};
      fields.addAll(getFieldTypes(_Type.Object));
      for (int i = 0; i < type.positional.length; i++) {
        fields['\$${i + 1}'] = type.positional[i];
      }
      fields.addAll(type.named);
      return fields;
    } else {
      return getFieldTypes(_Type.Object);
    }
  }

  @override
  _Type getNonNullable(_Type type) {
    if (type is _NullableType) {
      return type.type;
    }
    return type;
  }

  @override
  bool isBoolType(_Type type) {
    return type == _Type.Bool;
  }

  @override
  bool isNeverType(_Type type) {
    return type == _Type.Never;
  }

  @override
  bool isNonNullableObject(_Type type) {
    return type == _Type.Object;
  }

  @override
  bool isNullType(_Type type) {
    return type == _Type.Null;
  }

  @override
  bool isNullable(_Type type) {
    return type is _NullableType;
  }

  @override
  bool isNullableObject(_Type type) {
    return type == _Type.NullableObject;
  }

  @override
  bool isSubtypeOf(_Type s, _Type t) {
    if (s == t) return true;
    if (t == _Type.NullableObject) return true;
    if (s == _Type.Never) return true;
    if (s == _Type.Null && t is _NullableType) return true;
    if (s is _NullableType) {
      if (t is _NullableType) {
        return isSubtypeOf(s.type, t.type);
      }
      return false;
    } else {
      if (t is _NullableType) {
        return isSubtypeOf(s, t.type);
      } else {
        if (s is _InterfaceType && t is _InterfaceType) {
          if (t.cls == _Class.Object) return true;
          for (_InterfaceType supertype in env._getSupertypes(s.cls)) {
            if (isSubtypeOf(supertype, t)) {
              return true;
            }
          }
        }
        return false;
      }
    }
  }

  @override
  _Type get nullableObjectType => _Type.NullableObject;

  @override
  String typeToString(_Type type) {
    return type.toString();
  }

  @override
  bool isRecordType(_Type type) {
    return type is _RecordType;
  }
}

class _EnumOperations
    implements
        EnumOperations<_Type, _EnumClass, _EnumElement, _EnumElementValue> {
  @override
  _EnumClass? getEnumClass(_Type type) {
    if (type is _InterfaceType) {
      _Class cls = type.cls;
      if (cls is _EnumClass) {
        return cls;
      }
    }
    return null;
  }

  @override
  String getEnumElementName(_EnumElement enumElement) {
    // TODO(johnniwinther): Support testing of enums.
    throw new UnimplementedError('_EnumOperations.getEnumElementName');
  }

  @override
  _Type getEnumElementType(_EnumElement enumElement) {
    // TODO(johnniwinther): Support testing of enums.
    throw new UnimplementedError('_EnumOperations.getEnumElementType');
  }

  @override
  _EnumElementValue getEnumElementValue(_EnumElement enumElement) {
    // TODO(johnniwinther): Support testing of enums.
    throw new UnimplementedError('_EnumOperations.getEnumElementValue');
  }

  @override
  Iterable<_EnumElement> getEnumElements(_EnumClass enumClass) {
    // TODO(johnniwinther): Support testing of enums.
    throw new UnimplementedError('_EnumOperations.getEnumElements');
  }
}

class _SealedClassOperations implements SealedClassOperations<_Type, _Class> {
  final TestEnvironment env;

  _SealedClassOperations(this.env);

  @override
  List<_Class> getDirectSubclasses(_Class sealedClass) {
    List<_Class> classes = [];
    for (_InterfaceType subtype in env._getSubtypes(sealedClass)) {
      classes.add(subtype.cls);
    }
    return classes;
  }

  @override
  _Class? getSealedClass(_Type type) {
    if (type is _InterfaceType) {
      _Class cls = type.cls;
      if (cls.isSealed) {
        return cls;
      }
    }
    return null;
  }

  @override
  _Type? getSubclassAsInstanceOf(_Class subClass, _Type sealedClassType) {
    return new _InterfaceType(subClass);
  }
}

class _ExhaustivenessCache extends ExhaustivenessCache<_Type, _Class,
    _EnumClass, _EnumElement, _EnumElementValue> {
  _ExhaustivenessCache(
      super.typeOperations, super.enumOperations, super.sealedClassOperations);
}
