import 'package:flutter_unity_widget/src/helpers/types.dart';

class UnityEvent<T> {
  /// The ID of the Unity this event is associated to.
  final int unityId;

  /// The value wrapped by this event
  final T value;

  /// Build a Unity Event, that relates a mapId with a given value.
  ///
  /// The `unityId` is the id of the map that triggered the event.
  /// `value` may be `null` in events that don't transport any meaningful data.
  UnityEvent(this.unityId, this.value);
}

class UnitySceneLoadedEvent extends UnityEvent<SceneLoaded?> {
  UnitySceneLoadedEvent(int unityId, SceneLoaded? value)
      : super(unityId, value);
}

class UnityLoadedEvent extends UnityEvent<void> {
  UnityLoadedEvent(int unityId, void value) : super(unityId, value);
}

class UnityUnLoadedEvent extends UnityEvent<void> {
  UnityUnLoadedEvent(int unityId, void value) : super(unityId, value);
}

class UnityCreatedEvent extends UnityEvent<void> {
  UnityCreatedEvent(int unityId, void value) : super(unityId, value);
}

class UnityMessageEvent extends UnityEvent<dynamic> {
  UnityMessageEvent(int unityId, dynamic value) : super(unityId, value);
}
