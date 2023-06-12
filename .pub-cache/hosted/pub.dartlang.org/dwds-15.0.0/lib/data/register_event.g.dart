// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_event.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<RegisterEvent> _$registerEventSerializer =
    new _$RegisterEventSerializer();

class _$RegisterEventSerializer implements StructuredSerializer<RegisterEvent> {
  @override
  final Iterable<Type> types = const [RegisterEvent, _$RegisterEvent];
  @override
  final String wireName = 'RegisterEvent';

  @override
  Iterable<Object?> serialize(Serializers serializers, RegisterEvent object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      'eventData',
      serializers.serialize(object.eventData,
          specifiedType: const FullType(String)),
      'timestamp',
      serializers.serialize(object.timestamp,
          specifiedType: const FullType(int)),
    ];

    return result;
  }

  @override
  RegisterEvent deserialize(
      Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new RegisterEventBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'eventData':
          result.eventData = serializers.deserialize(value,
              specifiedType: const FullType(String))! as String;
          break;
        case 'timestamp':
          result.timestamp = serializers.deserialize(value,
              specifiedType: const FullType(int))! as int;
          break;
      }
    }

    return result.build();
  }
}

class _$RegisterEvent extends RegisterEvent {
  @override
  final String eventData;
  @override
  final int timestamp;

  factory _$RegisterEvent([void Function(RegisterEventBuilder)? updates]) =>
      (new RegisterEventBuilder()..update(updates))._build();

  _$RegisterEvent._({required this.eventData, required this.timestamp})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(
        eventData, r'RegisterEvent', 'eventData');
    BuiltValueNullFieldError.checkNotNull(
        timestamp, r'RegisterEvent', 'timestamp');
  }

  @override
  RegisterEvent rebuild(void Function(RegisterEventBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RegisterEventBuilder toBuilder() => new RegisterEventBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RegisterEvent &&
        eventData == other.eventData &&
        timestamp == other.timestamp;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, eventData.hashCode), timestamp.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RegisterEvent')
          ..add('eventData', eventData)
          ..add('timestamp', timestamp))
        .toString();
  }
}

class RegisterEventBuilder
    implements Builder<RegisterEvent, RegisterEventBuilder> {
  _$RegisterEvent? _$v;

  String? _eventData;
  String? get eventData => _$this._eventData;
  set eventData(String? eventData) => _$this._eventData = eventData;

  int? _timestamp;
  int? get timestamp => _$this._timestamp;
  set timestamp(int? timestamp) => _$this._timestamp = timestamp;

  RegisterEventBuilder();

  RegisterEventBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _eventData = $v.eventData;
      _timestamp = $v.timestamp;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RegisterEvent other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$RegisterEvent;
  }

  @override
  void update(void Function(RegisterEventBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RegisterEvent build() => _build();

  _$RegisterEvent _build() {
    final _$result = _$v ??
        new _$RegisterEvent._(
            eventData: BuiltValueNullFieldError.checkNotNull(
                eventData, r'RegisterEvent', 'eventData'),
            timestamp: BuiltValueNullFieldError.checkNotNull(
                timestamp, r'RegisterEvent', 'timestamp'));
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,no_leading_underscores_for_local_identifiers,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new,unnecessary_lambdas
