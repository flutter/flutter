// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isolate_events.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<IsolateExit> _$isolateExitSerializer = new _$IsolateExitSerializer();
Serializer<IsolateStart> _$isolateStartSerializer =
    new _$IsolateStartSerializer();

class _$IsolateExitSerializer implements StructuredSerializer<IsolateExit> {
  @override
  final Iterable<Type> types = const [IsolateExit, _$IsolateExit];
  @override
  final String wireName = 'IsolateExit';

  @override
  Iterable<Object?> serialize(Serializers serializers, IsolateExit object,
      {FullType specifiedType = FullType.unspecified}) {
    return <Object?>[];
  }

  @override
  IsolateExit deserialize(Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    return new IsolateExitBuilder().build();
  }
}

class _$IsolateStartSerializer implements StructuredSerializer<IsolateStart> {
  @override
  final Iterable<Type> types = const [IsolateStart, _$IsolateStart];
  @override
  final String wireName = 'IsolateStart';

  @override
  Iterable<Object?> serialize(Serializers serializers, IsolateStart object,
      {FullType specifiedType = FullType.unspecified}) {
    return <Object?>[];
  }

  @override
  IsolateStart deserialize(
      Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    return new IsolateStartBuilder().build();
  }
}

class _$IsolateExit extends IsolateExit {
  factory _$IsolateExit([void Function(IsolateExitBuilder)? updates]) =>
      (new IsolateExitBuilder()..update(updates))._build();

  _$IsolateExit._() : super._();

  @override
  IsolateExit rebuild(void Function(IsolateExitBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  IsolateExitBuilder toBuilder() => new IsolateExitBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is IsolateExit;
  }

  @override
  int get hashCode {
    return 814065794;
  }

  @override
  String toString() {
    return newBuiltValueToStringHelper(r'IsolateExit').toString();
  }
}

class IsolateExitBuilder implements Builder<IsolateExit, IsolateExitBuilder> {
  _$IsolateExit? _$v;

  IsolateExitBuilder();

  @override
  void replace(IsolateExit other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$IsolateExit;
  }

  @override
  void update(void Function(IsolateExitBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  IsolateExit build() => _build();

  _$IsolateExit _build() {
    final _$result = _$v ?? new _$IsolateExit._();
    replace(_$result);
    return _$result;
  }
}

class _$IsolateStart extends IsolateStart {
  factory _$IsolateStart([void Function(IsolateStartBuilder)? updates]) =>
      (new IsolateStartBuilder()..update(updates))._build();

  _$IsolateStart._() : super._();

  @override
  IsolateStart rebuild(void Function(IsolateStartBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  IsolateStartBuilder toBuilder() => new IsolateStartBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is IsolateStart;
  }

  @override
  int get hashCode {
    return 97463111;
  }

  @override
  String toString() {
    return newBuiltValueToStringHelper(r'IsolateStart').toString();
  }
}

class IsolateStartBuilder
    implements Builder<IsolateStart, IsolateStartBuilder> {
  _$IsolateStart? _$v;

  IsolateStartBuilder();

  @override
  void replace(IsolateStart other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$IsolateStart;
  }

  @override
  void update(void Function(IsolateStartBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  IsolateStart build() => _build();

  _$IsolateStart _build() {
    final _$result = _$v ?? new _$IsolateStart._();
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,no_leading_underscores_for_local_identifiers,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new,unnecessary_lambdas
