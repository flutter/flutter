// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<RunRequest> _$runRequestSerializer = new _$RunRequestSerializer();

class _$RunRequestSerializer implements StructuredSerializer<RunRequest> {
  @override
  final Iterable<Type> types = const [RunRequest, _$RunRequest];
  @override
  final String wireName = 'RunRequest';

  @override
  Iterable<Object?> serialize(Serializers serializers, RunRequest object,
      {FullType specifiedType = FullType.unspecified}) {
    return <Object?>[];
  }

  @override
  RunRequest deserialize(Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    return new RunRequestBuilder().build();
  }
}

class _$RunRequest extends RunRequest {
  factory _$RunRequest([void Function(RunRequestBuilder)? updates]) =>
      (new RunRequestBuilder()..update(updates))._build();

  _$RunRequest._() : super._();

  @override
  RunRequest rebuild(void Function(RunRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RunRequestBuilder toBuilder() => new RunRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RunRequest;
  }

  @override
  int get hashCode {
    return 248087772;
  }

  @override
  String toString() {
    return newBuiltValueToStringHelper(r'RunRequest').toString();
  }
}

class RunRequestBuilder implements Builder<RunRequest, RunRequestBuilder> {
  _$RunRequest? _$v;

  RunRequestBuilder();

  @override
  void replace(RunRequest other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$RunRequest;
  }

  @override
  void update(void Function(RunRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RunRequest build() => _build();

  _$RunRequest _build() {
    final _$result = _$v ?? new _$RunRequest._();
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,no_leading_underscores_for_local_identifiers,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new,unnecessary_lambdas
