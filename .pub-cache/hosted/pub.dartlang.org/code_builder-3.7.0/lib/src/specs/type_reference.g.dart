// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'type_reference.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TypeReference extends TypeReference {
  @override
  final String symbol;
  @override
  final String url;
  @override
  final Reference bound;
  @override
  final BuiltList<Reference> types;
  @override
  final bool isNullable;

  factory _$TypeReference([void Function(TypeReferenceBuilder) updates]) =>
      (new TypeReferenceBuilder()..update(updates)).build() as _$TypeReference;

  _$TypeReference._(
      {this.symbol, this.url, this.bound, this.types, this.isNullable})
      : super._() {
    if (symbol == null) {
      throw new BuiltValueNullFieldError('TypeReference', 'symbol');
    }
    if (types == null) {
      throw new BuiltValueNullFieldError('TypeReference', 'types');
    }
  }

  @override
  TypeReference rebuild(void Function(TypeReferenceBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  _$TypeReferenceBuilder toBuilder() =>
      new _$TypeReferenceBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TypeReference &&
        symbol == other.symbol &&
        url == other.url &&
        bound == other.bound &&
        types == other.types &&
        isNullable == other.isNullable;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc($jc($jc($jc(0, symbol.hashCode), url.hashCode), bound.hashCode),
            types.hashCode),
        isNullable.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('TypeReference')
          ..add('symbol', symbol)
          ..add('url', url)
          ..add('bound', bound)
          ..add('types', types)
          ..add('isNullable', isNullable))
        .toString();
  }
}

class _$TypeReferenceBuilder extends TypeReferenceBuilder {
  _$TypeReference _$v;

  @override
  String get symbol {
    _$this;
    return super.symbol;
  }

  @override
  set symbol(String symbol) {
    _$this;
    super.symbol = symbol;
  }

  @override
  String get url {
    _$this;
    return super.url;
  }

  @override
  set url(String url) {
    _$this;
    super.url = url;
  }

  @override
  Reference get bound {
    _$this;
    return super.bound;
  }

  @override
  set bound(Reference bound) {
    _$this;
    super.bound = bound;
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
  bool get isNullable {
    _$this;
    return super.isNullable;
  }

  @override
  set isNullable(bool isNullable) {
    _$this;
    super.isNullable = isNullable;
  }

  _$TypeReferenceBuilder() : super._();

  TypeReferenceBuilder get _$this {
    if (_$v != null) {
      super.symbol = _$v.symbol;
      super.url = _$v.url;
      super.bound = _$v.bound;
      super.types = _$v.types?.toBuilder();
      super.isNullable = _$v.isNullable;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TypeReference other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$TypeReference;
  }

  @override
  void update(void Function(TypeReferenceBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$TypeReference build() {
    _$TypeReference _$result;
    try {
      _$result = _$v ??
          new _$TypeReference._(
              symbol: symbol,
              url: url,
              bound: bound,
              types: types.build(),
              isNullable: isNullable);
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'types';
        types.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'TypeReference', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
