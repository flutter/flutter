// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connect_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<ConnectRequest> _$connectRequestSerializer =
    new _$ConnectRequestSerializer();

class _$ConnectRequestSerializer
    implements StructuredSerializer<ConnectRequest> {
  @override
  final Iterable<Type> types = const [ConnectRequest, _$ConnectRequest];
  @override
  final String wireName = 'ConnectRequest';

  @override
  Iterable<Object?> serialize(Serializers serializers, ConnectRequest object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      'appId',
      serializers.serialize(object.appId,
          specifiedType: const FullType(String)),
      'instanceId',
      serializers.serialize(object.instanceId,
          specifiedType: const FullType(String)),
      'entrypointPath',
      serializers.serialize(object.entrypointPath,
          specifiedType: const FullType(String)),
    ];

    return result;
  }

  @override
  ConnectRequest deserialize(
      Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new ConnectRequestBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'appId':
          result.appId = serializers.deserialize(value,
              specifiedType: const FullType(String))! as String;
          break;
        case 'instanceId':
          result.instanceId = serializers.deserialize(value,
              specifiedType: const FullType(String))! as String;
          break;
        case 'entrypointPath':
          result.entrypointPath = serializers.deserialize(value,
              specifiedType: const FullType(String))! as String;
          break;
      }
    }

    return result.build();
  }
}

class _$ConnectRequest extends ConnectRequest {
  @override
  final String appId;
  @override
  final String instanceId;
  @override
  final String entrypointPath;

  factory _$ConnectRequest([void Function(ConnectRequestBuilder)? updates]) =>
      (new ConnectRequestBuilder()..update(updates))._build();

  _$ConnectRequest._(
      {required this.appId,
      required this.instanceId,
      required this.entrypointPath})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(appId, r'ConnectRequest', 'appId');
    BuiltValueNullFieldError.checkNotNull(
        instanceId, r'ConnectRequest', 'instanceId');
    BuiltValueNullFieldError.checkNotNull(
        entrypointPath, r'ConnectRequest', 'entrypointPath');
  }

  @override
  ConnectRequest rebuild(void Function(ConnectRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ConnectRequestBuilder toBuilder() =>
      new ConnectRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ConnectRequest &&
        appId == other.appId &&
        instanceId == other.instanceId &&
        entrypointPath == other.entrypointPath;
  }

  @override
  int get hashCode {
    return $jf($jc($jc($jc(0, appId.hashCode), instanceId.hashCode),
        entrypointPath.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ConnectRequest')
          ..add('appId', appId)
          ..add('instanceId', instanceId)
          ..add('entrypointPath', entrypointPath))
        .toString();
  }
}

class ConnectRequestBuilder
    implements Builder<ConnectRequest, ConnectRequestBuilder> {
  _$ConnectRequest? _$v;

  String? _appId;
  String? get appId => _$this._appId;
  set appId(String? appId) => _$this._appId = appId;

  String? _instanceId;
  String? get instanceId => _$this._instanceId;
  set instanceId(String? instanceId) => _$this._instanceId = instanceId;

  String? _entrypointPath;
  String? get entrypointPath => _$this._entrypointPath;
  set entrypointPath(String? entrypointPath) =>
      _$this._entrypointPath = entrypointPath;

  ConnectRequestBuilder();

  ConnectRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _appId = $v.appId;
      _instanceId = $v.instanceId;
      _entrypointPath = $v.entrypointPath;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ConnectRequest other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$ConnectRequest;
  }

  @override
  void update(void Function(ConnectRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ConnectRequest build() => _build();

  _$ConnectRequest _build() {
    final _$result = _$v ??
        new _$ConnectRequest._(
            appId: BuiltValueNullFieldError.checkNotNull(
                appId, r'ConnectRequest', 'appId'),
            instanceId: BuiltValueNullFieldError.checkNotNull(
                instanceId, r'ConnectRequest', 'instanceId'),
            entrypointPath: BuiltValueNullFieldError.checkNotNull(
                entrypointPath, r'ConnectRequest', 'entrypointPath'));
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,no_leading_underscores_for_local_identifiers,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new,unnecessary_lambdas
