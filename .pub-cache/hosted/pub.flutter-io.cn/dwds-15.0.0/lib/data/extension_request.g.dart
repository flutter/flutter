// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'extension_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<ExtensionRequest> _$extensionRequestSerializer =
    new _$ExtensionRequestSerializer();
Serializer<ExtensionResponse> _$extensionResponseSerializer =
    new _$ExtensionResponseSerializer();
Serializer<ExtensionEvent> _$extensionEventSerializer =
    new _$ExtensionEventSerializer();
Serializer<BatchedEvents> _$batchedEventsSerializer =
    new _$BatchedEventsSerializer();

class _$ExtensionRequestSerializer
    implements StructuredSerializer<ExtensionRequest> {
  @override
  final Iterable<Type> types = const [ExtensionRequest, _$ExtensionRequest];
  @override
  final String wireName = 'ExtensionRequest';

  @override
  Iterable<Object?> serialize(Serializers serializers, ExtensionRequest object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      'id',
      serializers.serialize(object.id, specifiedType: const FullType(int)),
      'command',
      serializers.serialize(object.command,
          specifiedType: const FullType(String)),
    ];
    Object? value;
    value = object.commandParams;
    if (value != null) {
      result
        ..add('commandParams')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
    }
    return result;
  }

  @override
  ExtensionRequest deserialize(
      Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new ExtensionRequestBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'id':
          result.id = serializers.deserialize(value,
              specifiedType: const FullType(int))! as int;
          break;
        case 'command':
          result.command = serializers.deserialize(value,
              specifiedType: const FullType(String))! as String;
          break;
        case 'commandParams':
          result.commandParams = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
      }
    }

    return result.build();
  }
}

class _$ExtensionResponseSerializer
    implements StructuredSerializer<ExtensionResponse> {
  @override
  final Iterable<Type> types = const [ExtensionResponse, _$ExtensionResponse];
  @override
  final String wireName = 'ExtensionResponse';

  @override
  Iterable<Object?> serialize(Serializers serializers, ExtensionResponse object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      'id',
      serializers.serialize(object.id, specifiedType: const FullType(int)),
      'success',
      serializers.serialize(object.success,
          specifiedType: const FullType(bool)),
      'result',
      serializers.serialize(object.result,
          specifiedType: const FullType(String)),
    ];
    Object? value;
    value = object.error;
    if (value != null) {
      result
        ..add('error')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
    }
    return result;
  }

  @override
  ExtensionResponse deserialize(
      Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new ExtensionResponseBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'id':
          result.id = serializers.deserialize(value,
              specifiedType: const FullType(int))! as int;
          break;
        case 'success':
          result.success = serializers.deserialize(value,
              specifiedType: const FullType(bool))! as bool;
          break;
        case 'result':
          result.result = serializers.deserialize(value,
              specifiedType: const FullType(String))! as String;
          break;
        case 'error':
          result.error = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
      }
    }

    return result.build();
  }
}

class _$ExtensionEventSerializer
    implements StructuredSerializer<ExtensionEvent> {
  @override
  final Iterable<Type> types = const [ExtensionEvent, _$ExtensionEvent];
  @override
  final String wireName = 'ExtensionEvent';

  @override
  Iterable<Object?> serialize(Serializers serializers, ExtensionEvent object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      'params',
      serializers.serialize(object.params,
          specifiedType: const FullType(String)),
      'method',
      serializers.serialize(object.method,
          specifiedType: const FullType(String)),
    ];

    return result;
  }

  @override
  ExtensionEvent deserialize(
      Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new ExtensionEventBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'params':
          result.params = serializers.deserialize(value,
              specifiedType: const FullType(String))! as String;
          break;
        case 'method':
          result.method = serializers.deserialize(value,
              specifiedType: const FullType(String))! as String;
          break;
      }
    }

    return result.build();
  }
}

class _$BatchedEventsSerializer implements StructuredSerializer<BatchedEvents> {
  @override
  final Iterable<Type> types = const [BatchedEvents, _$BatchedEvents];
  @override
  final String wireName = 'BatchedEvents';

  @override
  Iterable<Object?> serialize(Serializers serializers, BatchedEvents object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      'events',
      serializers.serialize(object.events,
          specifiedType: const FullType(
              BuiltList, const [const FullType(ExtensionEvent)])),
    ];

    return result;
  }

  @override
  BatchedEvents deserialize(
      Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new BatchedEventsBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'events':
          result.events.replace(serializers.deserialize(value,
                  specifiedType: const FullType(
                      BuiltList, const [const FullType(ExtensionEvent)]))!
              as BuiltList<Object?>);
          break;
      }
    }

    return result.build();
  }
}

class _$ExtensionRequest extends ExtensionRequest {
  @override
  final int id;
  @override
  final String command;
  @override
  final String? commandParams;

  factory _$ExtensionRequest(
          [void Function(ExtensionRequestBuilder)? updates]) =>
      (new ExtensionRequestBuilder()..update(updates))._build();

  _$ExtensionRequest._(
      {required this.id, required this.command, this.commandParams})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(id, r'ExtensionRequest', 'id');
    BuiltValueNullFieldError.checkNotNull(
        command, r'ExtensionRequest', 'command');
  }

  @override
  ExtensionRequest rebuild(void Function(ExtensionRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ExtensionRequestBuilder toBuilder() =>
      new ExtensionRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ExtensionRequest &&
        id == other.id &&
        command == other.command &&
        commandParams == other.commandParams;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc($jc(0, id.hashCode), command.hashCode), commandParams.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ExtensionRequest')
          ..add('id', id)
          ..add('command', command)
          ..add('commandParams', commandParams))
        .toString();
  }
}

class ExtensionRequestBuilder
    implements Builder<ExtensionRequest, ExtensionRequestBuilder> {
  _$ExtensionRequest? _$v;

  int? _id;
  int? get id => _$this._id;
  set id(int? id) => _$this._id = id;

  String? _command;
  String? get command => _$this._command;
  set command(String? command) => _$this._command = command;

  String? _commandParams;
  String? get commandParams => _$this._commandParams;
  set commandParams(String? commandParams) =>
      _$this._commandParams = commandParams;

  ExtensionRequestBuilder();

  ExtensionRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _command = $v.command;
      _commandParams = $v.commandParams;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ExtensionRequest other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$ExtensionRequest;
  }

  @override
  void update(void Function(ExtensionRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ExtensionRequest build() => _build();

  _$ExtensionRequest _build() {
    final _$result = _$v ??
        new _$ExtensionRequest._(
            id: BuiltValueNullFieldError.checkNotNull(
                id, r'ExtensionRequest', 'id'),
            command: BuiltValueNullFieldError.checkNotNull(
                command, r'ExtensionRequest', 'command'),
            commandParams: commandParams);
    replace(_$result);
    return _$result;
  }
}

class _$ExtensionResponse extends ExtensionResponse {
  @override
  final int id;
  @override
  final bool success;
  @override
  final String result;
  @override
  final String? error;

  factory _$ExtensionResponse(
          [void Function(ExtensionResponseBuilder)? updates]) =>
      (new ExtensionResponseBuilder()..update(updates))._build();

  _$ExtensionResponse._(
      {required this.id,
      required this.success,
      required this.result,
      this.error})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(id, r'ExtensionResponse', 'id');
    BuiltValueNullFieldError.checkNotNull(
        success, r'ExtensionResponse', 'success');
    BuiltValueNullFieldError.checkNotNull(
        result, r'ExtensionResponse', 'result');
  }

  @override
  ExtensionResponse rebuild(void Function(ExtensionResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ExtensionResponseBuilder toBuilder() =>
      new ExtensionResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ExtensionResponse &&
        id == other.id &&
        success == other.success &&
        result == other.result &&
        error == other.error;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc($jc($jc(0, id.hashCode), success.hashCode), result.hashCode),
        error.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ExtensionResponse')
          ..add('id', id)
          ..add('success', success)
          ..add('result', result)
          ..add('error', error))
        .toString();
  }
}

class ExtensionResponseBuilder
    implements Builder<ExtensionResponse, ExtensionResponseBuilder> {
  _$ExtensionResponse? _$v;

  int? _id;
  int? get id => _$this._id;
  set id(int? id) => _$this._id = id;

  bool? _success;
  bool? get success => _$this._success;
  set success(bool? success) => _$this._success = success;

  String? _result;
  String? get result => _$this._result;
  set result(String? result) => _$this._result = result;

  String? _error;
  String? get error => _$this._error;
  set error(String? error) => _$this._error = error;

  ExtensionResponseBuilder();

  ExtensionResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _success = $v.success;
      _result = $v.result;
      _error = $v.error;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ExtensionResponse other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$ExtensionResponse;
  }

  @override
  void update(void Function(ExtensionResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ExtensionResponse build() => _build();

  _$ExtensionResponse _build() {
    final _$result = _$v ??
        new _$ExtensionResponse._(
            id: BuiltValueNullFieldError.checkNotNull(
                id, r'ExtensionResponse', 'id'),
            success: BuiltValueNullFieldError.checkNotNull(
                success, r'ExtensionResponse', 'success'),
            result: BuiltValueNullFieldError.checkNotNull(
                result, r'ExtensionResponse', 'result'),
            error: error);
    replace(_$result);
    return _$result;
  }
}

class _$ExtensionEvent extends ExtensionEvent {
  @override
  final String params;
  @override
  final String method;

  factory _$ExtensionEvent([void Function(ExtensionEventBuilder)? updates]) =>
      (new ExtensionEventBuilder()..update(updates))._build();

  _$ExtensionEvent._({required this.params, required this.method}) : super._() {
    BuiltValueNullFieldError.checkNotNull(params, r'ExtensionEvent', 'params');
    BuiltValueNullFieldError.checkNotNull(method, r'ExtensionEvent', 'method');
  }

  @override
  ExtensionEvent rebuild(void Function(ExtensionEventBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ExtensionEventBuilder toBuilder() =>
      new ExtensionEventBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ExtensionEvent &&
        params == other.params &&
        method == other.method;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, params.hashCode), method.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ExtensionEvent')
          ..add('params', params)
          ..add('method', method))
        .toString();
  }
}

class ExtensionEventBuilder
    implements Builder<ExtensionEvent, ExtensionEventBuilder> {
  _$ExtensionEvent? _$v;

  String? _params;
  String? get params => _$this._params;
  set params(String? params) => _$this._params = params;

  String? _method;
  String? get method => _$this._method;
  set method(String? method) => _$this._method = method;

  ExtensionEventBuilder();

  ExtensionEventBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _params = $v.params;
      _method = $v.method;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ExtensionEvent other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$ExtensionEvent;
  }

  @override
  void update(void Function(ExtensionEventBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ExtensionEvent build() => _build();

  _$ExtensionEvent _build() {
    final _$result = _$v ??
        new _$ExtensionEvent._(
            params: BuiltValueNullFieldError.checkNotNull(
                params, r'ExtensionEvent', 'params'),
            method: BuiltValueNullFieldError.checkNotNull(
                method, r'ExtensionEvent', 'method'));
    replace(_$result);
    return _$result;
  }
}

class _$BatchedEvents extends BatchedEvents {
  @override
  final BuiltList<ExtensionEvent> events;

  factory _$BatchedEvents([void Function(BatchedEventsBuilder)? updates]) =>
      (new BatchedEventsBuilder()..update(updates))._build();

  _$BatchedEvents._({required this.events}) : super._() {
    BuiltValueNullFieldError.checkNotNull(events, r'BatchedEvents', 'events');
  }

  @override
  BatchedEvents rebuild(void Function(BatchedEventsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BatchedEventsBuilder toBuilder() => new BatchedEventsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BatchedEvents && events == other.events;
  }

  @override
  int get hashCode {
    return $jf($jc(0, events.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'BatchedEvents')
          ..add('events', events))
        .toString();
  }
}

class BatchedEventsBuilder
    implements Builder<BatchedEvents, BatchedEventsBuilder> {
  _$BatchedEvents? _$v;

  ListBuilder<ExtensionEvent>? _events;
  ListBuilder<ExtensionEvent> get events =>
      _$this._events ??= new ListBuilder<ExtensionEvent>();
  set events(ListBuilder<ExtensionEvent>? events) => _$this._events = events;

  BatchedEventsBuilder();

  BatchedEventsBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _events = $v.events.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BatchedEvents other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$BatchedEvents;
  }

  @override
  void update(void Function(BatchedEventsBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  BatchedEvents build() => _build();

  _$BatchedEvents _build() {
    _$BatchedEvents _$result;
    try {
      _$result = _$v ?? new _$BatchedEvents._(events: events.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'events';
        events.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            r'BatchedEvents', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,no_leading_underscores_for_local_identifiers,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new,unnecessary_lambdas
