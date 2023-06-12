// ignore_for_file: public_member_api_docs

part of 'provider.dart';

void Function(
  String eventKind,
  Map<Object?, Object?> event,
)? _debugPostEventOverride;

void debugPostEvent(
  String eventKind, [
  Map<Object?, Object?> event = const {},
]) {
  if (_debugPostEventOverride != null) {
    _debugPostEventOverride!(eventKind, event);
  } else {
    developer.postEvent(eventKind, event);
  }
}

PostEventSpy spyPostEvent() {
  assert(_debugPostEventOverride == null, 'postEvent is already spied');

  final spy = PostEventSpy._();
  _debugPostEventOverride = spy._postEvent;
  return spy;
}

@protected
class PostEventCall {
  PostEventCall._(this.eventKind, this.event);
  final String eventKind;
  final Map<Object?, Object?> event;
}

@protected
class PostEventSpy {
  PostEventSpy._();
  final logs = <PostEventCall>[];

  void dispose() {
    assert(
      _debugPostEventOverride == _postEvent,
      'disposed a spy different from the current spy',
    );
    _debugPostEventOverride = null;
  }

  void _postEvent(
    String eventKind,
    Map<Object?, Object?> event,
  ) {
    logs.add(PostEventCall._(eventKind, event));
  }
}

@immutable
class ProviderNode {
  const ProviderNode({
    required this.id,
    required this.childrenNodeIds,
    required this.type,
    required _InheritedProviderScopeElement element,
  }) : _element = element;

  final String id;
  final String type;
  final List<String> childrenNodeIds;
  final _InheritedProviderScopeElement _element;

  Object? get value => _element._delegateState.value;
}

@protected
class ProviderBinding {
  ProviderBinding._();

  static final debugInstance = kDebugMode
      ? ProviderBinding._()
      : throw UnsupportedError('Cannot use ProviderBinding in release mode');

  Map<String, ProviderNode> _providerDetails = {};
  Map<String, ProviderNode> get providerDetails => _providerDetails;
  set providerDetails(Map<String, ProviderNode> value) {
    debugPostEvent('provider:provider_list_changed', <dynamic, dynamic>{});
    _providerDetails = value;
  }

  void providerDidChange(String providerId) {
    debugPostEvent(
      'provider:provider_changed',
      <dynamic, dynamic>{'id': providerId},
    );
  }
}
