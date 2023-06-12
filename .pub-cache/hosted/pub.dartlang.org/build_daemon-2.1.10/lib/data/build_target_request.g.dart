// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_target_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<BuildTargetRequest> _$buildTargetRequestSerializer =
    new _$BuildTargetRequestSerializer();

class _$BuildTargetRequestSerializer
    implements StructuredSerializer<BuildTargetRequest> {
  @override
  final Iterable<Type> types = const [BuildTargetRequest, _$BuildTargetRequest];
  @override
  final String wireName = 'BuildTargetRequest';

  @override
  Iterable<Object> serialize(Serializers serializers, BuildTargetRequest object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'target',
      serializers.serialize(object.target,
          specifiedType: const FullType(BuildTarget)),
    ];

    return result;
  }

  @override
  BuildTargetRequest deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new BuildTargetRequestBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'target':
          result.target = serializers.deserialize(value,
              specifiedType: const FullType(BuildTarget)) as BuildTarget;
          break;
      }
    }

    return result.build();
  }
}

class _$BuildTargetRequest extends BuildTargetRequest {
  @override
  final BuildTarget target;

  factory _$BuildTargetRequest(
          [void Function(BuildTargetRequestBuilder) updates]) =>
      (new BuildTargetRequestBuilder()..update(updates)).build();

  _$BuildTargetRequest._({this.target}) : super._() {
    if (target == null) {
      throw new BuiltValueNullFieldError('BuildTargetRequest', 'target');
    }
  }

  @override
  BuildTargetRequest rebuild(
          void Function(BuildTargetRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BuildTargetRequestBuilder toBuilder() =>
      new BuildTargetRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BuildTargetRequest && target == other.target;
  }

  @override
  int get hashCode {
    return $jf($jc(0, target.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('BuildTargetRequest')
          ..add('target', target))
        .toString();
  }
}

class BuildTargetRequestBuilder
    implements Builder<BuildTargetRequest, BuildTargetRequestBuilder> {
  _$BuildTargetRequest _$v;

  BuildTarget _target;
  BuildTarget get target => _$this._target;
  set target(BuildTarget target) => _$this._target = target;

  BuildTargetRequestBuilder();

  BuildTargetRequestBuilder get _$this {
    if (_$v != null) {
      _target = _$v.target;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BuildTargetRequest other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$BuildTargetRequest;
  }

  @override
  void update(void Function(BuildTargetRequestBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$BuildTargetRequest build() {
    final _$result = _$v ?? new _$BuildTargetRequest._(target: target);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
