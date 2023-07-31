// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'serializers.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializers _$serializers = (new Serializers().toBuilder()
      ..add(BatchedDebugEvents.serializer)
      ..add(BatchedEvents.serializer)
      ..add(BuildResult.serializer)
      ..add(BuildStatus.serializer)
      ..add(ConnectRequest.serializer)
      ..add(DebugEvent.serializer)
      ..add(DevToolsRequest.serializer)
      ..add(DevToolsResponse.serializer)
      ..add(ErrorResponse.serializer)
      ..add(ExtensionEvent.serializer)
      ..add(ExtensionRequest.serializer)
      ..add(ExtensionResponse.serializer)
      ..add(IsolateExit.serializer)
      ..add(IsolateStart.serializer)
      ..add(RegisterEvent.serializer)
      ..add(RunRequest.serializer)
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(DebugEvent)]),
          () => new ListBuilder<DebugEvent>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(ExtensionEvent)]),
          () => new ListBuilder<ExtensionEvent>()))
    .build();

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,no_leading_underscores_for_local_identifiers,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new,unnecessary_lambdas
