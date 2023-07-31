// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/exhaustiveness/static_type.dart';

/// Interface implemented by analyze/CFE to support type operations need for the
/// shared [StaticType]s.
abstract class TypeOperations<Type extends Object> {
  /// Returns the type for `Object`.
  Type get nullableObjectType;

  /// Returns `true` if [s] is a subtype of [t].
  bool isSubtypeOf(Type s, Type t);

  /// Returns `true` if [type] is a potentially nullable type.
  bool isNullable(Type type);

  /// Returns the non-nullable type corresponding to [type]. For instance
  /// `Foo` for `Foo?`. If [type] is already non-nullable, it itself is
  /// returned.
  Type getNonNullable(Type type);

  /// Returns `true` if [type] is the `Null` type.
  bool isNullType(Type type);

  /// Returns `true` if [type] is the `Never` type.
  bool isNeverType(Type type);

  /// Returns `true` if [type] is the `Object?` type.
  bool isNullableObject(Type type);

  /// Returns `true` if [type] is the `Object` type.
  bool isNonNullableObject(Type type);

  /// Returns `true` if [type] is the `bool` type.
  bool isBoolType(Type type);

  /// Returns the `bool` type.
  Type get boolType;

  /// Returns `true` if [type] is a record type.
  bool isRecordType(Type type);

  /// Returns a map of the field names and corresponding types available on
  /// [type]. For an interface type, these are the fields and getters, and for
  /// record types these are the record fields.
  Map<String, Type> getFieldTypes(Type type);

  /// Returns a human-readable representation of the [type].
  String typeToString(Type type);
}

/// Interface implemented by analyzer/CFE to support [StaticType]s for enums.
abstract class EnumOperations<Type extends Object, EnumClass extends Object,
    EnumElement extends Object, EnumElementValue extends Object> {
  /// Returns the enum class declaration for the [type] or `null` if
  /// [type] is not an enum type.
  EnumClass? getEnumClass(Type type);

  /// Returns the enum elements defined by [enumClass].
  Iterable<EnumElement> getEnumElements(EnumClass enumClass);

  /// Returns the value defined by the [enumElement]. The encoding is specific
  /// the implementation of this interface but must ensure constant value
  /// identity.
  EnumElementValue getEnumElementValue(EnumElement enumElement);

  /// Returns the declared name of the [enumElement].
  String getEnumElementName(EnumElement enumElement);

  /// Returns the static type of the [enumElement].
  Type getEnumElementType(EnumElement enumElement);
}

/// Interface implemented by analyzer/CFE to support [StaticType]s for sealed
/// classes.
abstract class SealedClassOperations<Type extends Object,
    Class extends Object> {
  /// Returns the sealed class declaration for [type] or `null` if [type] is not
  /// a sealed class type.
  Class? getSealedClass(Type type);

  /// Returns the direct subclasses of [sealedClass] that either extend,
  /// implement or mix it in.
  List<Class> getDirectSubclasses(Class sealedClass);

  /// Returns the instance of [subClass] that implements [sealedClassType].
  ///
  /// `null` might be returned if [subClass] cannot implement [sealedClassType].
  /// For instance
  ///
  ///     sealed class A<T> {}
  ///     class B<T> extends A<T> {}
  ///     class C extends A<int> {}
  ///
  /// here `C` has no implementation of `A<String>`.
  ///
  /// It is assumed that `TypeOperations.isSealedClass` is `true` for
  /// [sealedClassType] and that [subClass] is in `getDirectSubclasses` for
  /// `getSealedClass` of [sealedClassType].
  ///
  // TODO(johnniwinther): What should this return for generic types?
  Type? getSubclassAsInstanceOf(Class subClass, Type sealedClassType);
}

/// Interface for looking up fields and their corresponding [StaticType]s of
/// a given type.
abstract class FieldLookup<Type extends Object> {
  /// Returns a map of the field names and corresponding [StaticType]s available
  /// on [type]. For an interface type, these are the fields and getters, and
  /// for record types these are the record fields.
  Map<String, StaticType> getFieldTypes(Type type);
}

/// Cache used for computing [StaticType]s used for exhaustiveness checking.
///
/// This implementation is shared between analyzer and CFE, and implemented
/// using the analyzer/CFE implementations of [TypeOperations],
/// [EnumOperations], and [SealedClassOperations].
class ExhaustivenessCache<
    Type extends Object,
    Class extends Object,
    EnumClass extends Object,
    EnumElement extends Object,
    EnumElementValue extends Object> implements FieldLookup<Type> {
  final TypeOperations<Type> _typeOperations;
  final EnumOperations<Type, EnumClass, EnumElement, EnumElementValue>
      enumOperations;
  final SealedClassOperations<Type, Class> _sealedClassOperations;

  /// Cache for [EnumInfo] for enum classes.
  Map<EnumClass, EnumInfo<Type, EnumClass, EnumElement, EnumElementValue>>
      _enumInfo = {};

  /// Cache for [SealedClassInfo] for sealed classes.
  Map<Class, SealedClassInfo<Type, Class>> _sealedClassInfo = {};

  /// Cache for [UniqueStaticType]s.
  Map<Object, StaticType> _uniqueTypeMap = {};

  /// Cache for the [StaticType] for `bool`.
  late BoolStaticType _boolStaticType =
      new BoolStaticType(_typeOperations, this, _typeOperations.boolType);

  /// Cache for [StaticType]s for fields available on a [Type].
  Map<Type, Map<String, StaticType>> _fieldCache = {};

  ExhaustivenessCache(
      this._typeOperations, this.enumOperations, this._sealedClassOperations);

  /// Returns the [EnumInfo] for [enumClass].
  EnumInfo<Type, EnumClass, EnumElement, EnumElementValue> _getEnumInfo(
      EnumClass enumClass) {
    return _enumInfo[enumClass] ??=
        new EnumInfo(_typeOperations, this, enumOperations, enumClass);
  }

  /// Returns the [SealedClassInfo] for [sealedClass].
  SealedClassInfo<Type, Class> _getSealedClassInfo(Class sealedClass) {
    return _sealedClassInfo[sealedClass] ??=
        new SealedClassInfo(_sealedClassOperations, sealedClass);
  }

  /// Returns the [StaticType] for the boolean [value].
  StaticType getBoolValueStaticType(bool value) {
    return value ? _boolStaticType.trueType : _boolStaticType.falseType;
  }

  /// Returns the [StaticType] for [type].
  StaticType getStaticType(Type type) {
    if (_typeOperations.isNeverType(type)) {
      return StaticType.neverType;
    } else if (_typeOperations.isNullType(type)) {
      return StaticType.nullType;
    } else if (_typeOperations.isNonNullableObject(type)) {
      return StaticType.nonNullableObject;
    } else if (_typeOperations.isNullableObject(type)) {
      return StaticType.nullableObject;
    }

    StaticType staticType;
    Type nonNullable = _typeOperations.getNonNullable(type);
    if (_typeOperations.isBoolType(nonNullable)) {
      staticType = _boolStaticType;
    } else if (_typeOperations.isRecordType(nonNullable)) {
      staticType = new RecordStaticType(_typeOperations, this, nonNullable);
    } else {
      EnumClass? enumClass = enumOperations.getEnumClass(nonNullable);
      if (enumClass != null) {
        staticType = new EnumStaticType(
            _typeOperations, this, nonNullable, _getEnumInfo(enumClass));
      } else {
        Class? sealedClass = _sealedClassOperations.getSealedClass(nonNullable);
        if (sealedClass != null) {
          staticType = new SealedClassStaticType(
              _typeOperations,
              this,
              nonNullable,
              this,
              _sealedClassOperations,
              _getSealedClassInfo(sealedClass));
        } else {
          staticType =
              new TypeBasedStaticType(_typeOperations, this, nonNullable);
        }
      }
    }
    if (_typeOperations.isNullable(type)) {
      staticType = staticType.nullable;
    }
    return staticType;
  }

  /// Returns the [StaticType] for the [enumElementValue] declared by
  /// [enumClass].
  StaticType getEnumElementStaticType(
      EnumClass enumClass, EnumElementValue enumElementValue) {
    return _getEnumInfo(enumClass).getEnumElement(enumElementValue);
  }

  /// Creates a new unique [StaticType].
  StaticType getUnknownStaticType() {
    return getUniqueStaticType(
        _typeOperations.nullableObjectType, new Object(), '?');
  }

  /// Returns a [StaticType] of the given [type] with the given
  /// [textualRepresentation] that unique identifies the [uniqueValue].
  ///
  /// This is used for constants that are neither bool nor enum values.
  StaticType getUniqueStaticType(
      Type type, Object uniqueValue, String textualRepresentation) {
    Type nonNullable = _typeOperations.getNonNullable(type);
    StaticType staticType = _uniqueTypeMap[uniqueValue] ??=
        new UniqueStaticType(_typeOperations, this, nonNullable, uniqueValue,
            textualRepresentation);
    if (_typeOperations.isNullable(type)) {
      staticType = staticType.nullable;
    }
    return staticType;
  }

  @override
  Map<String, StaticType> getFieldTypes(Type type) {
    Map<String, StaticType>? fields = _fieldCache[type];
    if (fields == null) {
      _fieldCache[type] = fields = {};
      for (MapEntry<String, Type> entry
          in _typeOperations.getFieldTypes(type).entries) {
        fields[entry.key] = getStaticType(entry.value);
      }
    }
    return fields;
  }
}

/// [EnumInfo] stores information to compute the static type for and the type
/// of and enum class and its enum elements.
class EnumInfo<Type extends Object, EnumClass extends Object,
    EnumElement extends Object, EnumElementValue extends Object> {
  final TypeOperations<Type> _typeOperations;
  final FieldLookup<Type> _fieldLookup;
  final EnumOperations<Type, EnumClass, EnumElement, EnumElementValue>
      _enumOperations;
  final EnumClass _enumClass;
  Map<EnumElementValue, EnumElementStaticType<Type, EnumElement>>?
      _enumElements;

  EnumInfo(this._typeOperations, this._fieldLookup, this._enumOperations,
      this._enumClass);

  /// Returns a map of the enum elements and their corresponding [StaticType]s
  /// declared by [_enumClass].
  Map<EnumElementValue, EnumElementStaticType<Type, EnumElement>>
      get enumElements => _enumElements ??= _createEnumElements();

  /// Returns the [StaticType] corresponding to [enumElementValue].
  EnumElementStaticType<Type, EnumElement> getEnumElement(
      EnumElementValue enumElementValue) {
    return enumElements[enumElementValue]!;
  }

  Map<EnumElementValue, EnumElementStaticType<Type, EnumElement>>
      _createEnumElements() {
    Map<EnumElementValue, EnumElementStaticType<Type, EnumElement>> elements =
        {};
    for (EnumElement element in _enumOperations.getEnumElements(_enumClass)) {
      EnumElementValue value = _enumOperations.getEnumElementValue(element);
      elements[value] = new EnumElementStaticType<Type, EnumElement>(
          _typeOperations,
          _fieldLookup,
          _enumOperations.getEnumElementType(element),
          element,
          _enumOperations.getEnumElementName(element));
    }
    return elements;
  }
}

/// [SealedClassInfo] stores information to compute the static type for a
/// sealed class.
class SealedClassInfo<Type extends Object, Class extends Object> {
  final SealedClassOperations<Type, Class> _sealedClassOperations;
  final Class _sealedClass;
  List<Class>? _subClasses;

  SealedClassInfo(this._sealedClassOperations, this._sealedClass);

  /// Returns the classes that directly extends, implements or mix in
  /// [_sealedClass].
  Iterable<Class> get subClasses =>
      _subClasses ??= _sealedClassOperations.getDirectSubclasses(_sealedClass);
}

/// [StaticType] based on a non-nullable [Type].
///
/// All [StaticType] implementation in this library are based on [Type] through
/// this class. Additionally, the `static_type.dart` library has fixed
/// [StaticType] implementations for `Object`, `Null`, `Never` and nullable
/// types.
class TypeBasedStaticType<Type extends Object> extends NonNullableStaticType {
  final TypeOperations<Type> _typeOperations;
  final FieldLookup<Type> _fieldLookup;
  final Type _type;

  TypeBasedStaticType(this._typeOperations, this._fieldLookup, this._type);

  @override
  Map<String, StaticType> get fields => _fieldLookup.getFieldTypes(_type);

  /// Returns a non-null value for static types that are unique subtypes of
  /// the [_type]. For instance individual elements of an enum.
  Object? get identity => null;

  @override
  bool isSubtypeOfInternal(StaticType other) {
    return other is TypeBasedStaticType<Type> &&
        (other.identity == null || identical(identity, other.identity)) &&
        _typeOperations.isSubtypeOf(_type, other._type);
  }

  @override
  bool get isSealed => false;

  @override
  String get name => _typeOperations.typeToString(_type);

  @override
  int get hashCode => Object.hash(_type, identity);

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    return other is TypeBasedStaticType<Type> &&
        _type == other._type &&
        identity == other.identity;
  }

  Type get typeForTesting => _type;
}

/// [StaticType] for an instantiation of an enum that support access to the
/// enum values that populate its type through the [subtypes] property.
class EnumStaticType<Type extends Object, EnumElement extends Object>
    extends TypeBasedStaticType<Type> {
  final EnumInfo<Type, Object, EnumElement, Object> _enumInfo;
  List<EnumElementStaticType<Type, EnumElement>>? _enumElements;

  EnumStaticType(
      super.typeOperations, super.fieldLookup, super.type, this._enumInfo);

  @override
  bool get isSealed => true;

  @override
  Iterable<StaticType> get subtypes => enumElements;

  List<EnumElementStaticType<Type, EnumElement>> get enumElements =>
      _enumElements ??= _createEnumElements();

  List<EnumElementStaticType<Type, EnumElement>> _createEnumElements() {
    List<EnumElementStaticType<Type, EnumElement>> elements = [];
    for (EnumElementStaticType<Type, EnumElement> enumElement
        in _enumInfo.enumElements.values) {
      if (_typeOperations.isSubtypeOf(enumElement._type, _type)) {
        elements.add(enumElement);
      }
    }
    return elements;
  }
}

/// [StaticType] for a single enum element.
///
/// In the [StaticType] model, individual enum elements are represented as
/// unique subtypes of the enum type, modelled using [EnumStaticType].
class EnumElementStaticType<Type extends Object, EnumElement extends Object>
    extends TypeBasedStaticType<Type> {
  final EnumElement enumElement;

  @override
  final String name;

  EnumElementStaticType(super.typeOperations, super.fieldLookup, super.type,
      this.enumElement, this.name);

  @override
  Object? get identity => enumElement;
}

/// [StaticType] for a sealed class type.
class SealedClassStaticType<Type extends Object, Class extends Object>
    extends TypeBasedStaticType<Type> {
  final ExhaustivenessCache<Type, dynamic, dynamic, dynamic, Class> _cache;
  final SealedClassOperations<Type, Class> _sealedClassOperations;
  final SealedClassInfo<Type, Class> _sealedInfo;
  Iterable<StaticType>? _subtypes;

  SealedClassStaticType(super.typeOperations, super.fieldLookup, super.type,
      this._cache, this._sealedClassOperations, this._sealedInfo);

  @override
  bool get isSealed => true;

  @override
  Iterable<StaticType> get subtypes => _subtypes ??= _createSubtypes();

  List<StaticType> _createSubtypes() {
    List<StaticType> subtypes = [];
    for (Class subClass in _sealedInfo.subClasses) {
      Type? subtype =
          _sealedClassOperations.getSubclassAsInstanceOf(subClass, _type);
      if (subtype != null) {
        assert(_typeOperations.isSubtypeOf(subtype, _type));
        subtypes.add(_cache.getStaticType(subtype));
      }
    }
    return subtypes;
  }
}

/// [StaticType] for an object uniquely defined by its [identity].
class UniqueStaticType<Type extends Object> extends TypeBasedStaticType<Type> {
  @override
  final Object identity;

  @override
  final String name;

  UniqueStaticType(super.typeOperations, super.fieldLookup, super.type,
      this.identity, this.name);
}

/// [StaticType] for the `bool` type.
class BoolStaticType<Type extends Object> extends TypeBasedStaticType<Type> {
  BoolStaticType(super.typeOperations, super.fieldLookup, super.type);

  @override
  bool get isSealed => true;

  late StaticType trueType =
      new UniqueStaticType(_typeOperations, _fieldLookup, _type, true, 'true');

  late StaticType falseType = new UniqueStaticType(
      _typeOperations, _fieldLookup, _type, false, 'false');

  @override
  Iterable<StaticType> get subtypes => [trueType, falseType];
}

/// [StaticType] for a record type.
///
/// This models that type aspect of the record using only the structure of the
/// record type. This means that the type for `(Object, String)` and
/// `(String, int)` will be subtypes of each other.
///
/// This is necessary to avoid invalid conclusions on the disjointness of
/// spaces base on the their types. For instance in
///
///     method((String, Object) o) {
///       if (o case (Object _, String s)) {}
///     }
///
/// the case is not empty even though `(String, Object)` and `(Object, String)`
/// are not related type-wise.
///
/// Not that the fields of the record types _are_ using the type, so that
/// the `$1` field of `(String, Object)` is known to contain only `String`s.
class RecordStaticType<Type extends Object> extends TypeBasedStaticType<Type> {
  RecordStaticType(super.typeOperations, super.fieldLookup, super.type);

  @override
  bool get isRecord => true;

  @override
  bool isSubtypeOfInternal(StaticType other) {
    if (other is! RecordStaticType<Type>) {
      return false;
    }
    assert(identity == null);
    if (fields.length != other.fields.length) {
      return false;
    }
    for (MapEntry<String, StaticType> field in fields.entries) {
      StaticType? type = other.fields[field.key];
      if (type == null) {
        return false;
      }
    }
    return true;
  }
}
