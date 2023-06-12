// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'type_function.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$FunctionType extends FunctionType {
  @override
  final Reference returnType;
  @override
  final BuiltList<Reference> types;
  @override
  final BuiltList<Reference> requiredParameters;
  @override
  final BuiltList<Reference> optionalParameters;
  @override
  final BuiltMap<String, Reference> namedParameters;
  @override
  final bool isNullable;

  factory _$FunctionType([void Function(FunctionTypeBuilder) updates]) =>
      (new FunctionTypeBuilder()..update(updates)).build() as _$FunctionType;

  _$FunctionType._(
      {this.returnType,
      this.types,
      this.requiredParameters,
      this.optionalParameters,
      this.namedParameters,
      this.isNullable})
      : super._() {
    if (types == null) {
      throw new BuiltValueNullFieldError('FunctionType', 'types');
    }
    if (requiredParameters == null) {
      throw new BuiltValueNullFieldError('FunctionType', 'requiredParameters');
    }
    if (optionalParameters == null) {
      throw new BuiltValueNullFieldError('FunctionType', 'optionalParameters');
    }
    if (namedParameters == null) {
      throw new BuiltValueNullFieldError('FunctionType', 'namedParameters');
    }
  }

  @override
  FunctionType rebuild(void Function(FunctionTypeBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  _$FunctionTypeBuilder toBuilder() =>
      new _$FunctionTypeBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is FunctionType &&
        returnType == other.returnType &&
        types == other.types &&
        requiredParameters == other.requiredParameters &&
        optionalParameters == other.optionalParameters &&
        namedParameters == other.namedParameters &&
        isNullable == other.isNullable;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc(
                $jc($jc($jc(0, returnType.hashCode), types.hashCode),
                    requiredParameters.hashCode),
                optionalParameters.hashCode),
            namedParameters.hashCode),
        isNullable.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('FunctionType')
          ..add('returnType', returnType)
          ..add('types', types)
          ..add('requiredParameters', requiredParameters)
          ..add('optionalParameters', optionalParameters)
          ..add('namedParameters', namedParameters)
          ..add('isNullable', isNullable))
        .toString();
  }
}

class _$FunctionTypeBuilder extends FunctionTypeBuilder {
  _$FunctionType _$v;

  @override
  Reference get returnType {
    _$this;
    return super.returnType;
  }

  @override
  set returnType(Reference returnType) {
    _$this;
    super.returnType = returnType;
  }

  @override
  ListBuilder<Reference> get types {
    _$this;
    return super.types ??= new ListBuilder<Reference>();
  }

  @override
  set types(ListBuilder<Reference> types) {
    _$this;
    super.types = types;
  }

  @override
  ListBuilder<Reference> get requiredParameters {
    _$this;
    return super.requiredParameters ??= new ListBuilder<Reference>();
  }

  @override
  set requiredParameters(ListBuilder<Reference> requiredParameters) {
    _$this;
    super.requiredParameters = requiredParameters;
  }

  @override
  ListBuilder<Reference> get optionalParameters {
    _$this;
    return super.optionalParameters ??= new ListBuilder<Reference>();
  }

  @override
  set optionalParameters(ListBuilder<Reference> optionalParameters) {
    _$this;
    super.optionalParameters = optionalParameters;
  }

  @override
  MapBuilder<String, Reference> get namedParameters {
    _$this;
    return super.namedParameters ??= new MapBuilder<String, Reference>();
  }

  @override
  set namedParameters(MapBuilder<String, Reference> namedParameters) {
    _$this;
    super.namedParameters = namedParameters;
  }

  @override
  bool get isNullable {
    _$this;
    return super.isNullable;
  }

  @override
  set isNullable(bool isNullable) {
    _$this;
    super.isNullable = isNullable;
  }

  _$FunctionTypeBuilder() : super._();

  FunctionTypeBuilder get _$this {
    if (_$v != null) {
      super.returnType = _$v.returnType;
      super.types = _$v.types?.toBuilder();
      super.requiredParameters = _$v.requiredParameters?.toBuilder();
      super.optionalParameters = _$v.optionalParameters?.toBuilder();
      super.namedParameters = _$v.namedParameters?.toBuilder();
      super.isNullable = _$v.isNullable;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(FunctionType other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$FunctionType;
  }

  @override
  void update(void Function(FunctionTypeBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$FunctionType build() {
    _$FunctionType _$result;
    try {
      _$result = _$v ??
          new _$FunctionType._(
              returnType: returnType,
              types: types.build(),
              requiredParameters: requiredParameters.build(),
              optionalParameters: optionalParameters.build(),
              namedParameters: namedParameters.build(),
              isNullable: isNullable);
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'types';
        types.build();
        _$failedField = 'requiredParameters';
        requiredParameters.build();
        _$failedField = 'optionalParameters';
        optionalParameters.build();
        _$failedField = 'namedParameters';
        namedParameters.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'FunctionType', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
