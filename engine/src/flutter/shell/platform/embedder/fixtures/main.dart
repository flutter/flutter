import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'dart:convert';

void main() {}

@pragma('vm:entry-point')
void customEntrypoint() {
  sayHiFromCustomEntrypoint();
}

void sayHiFromCustomEntrypoint() native 'SayHiFromCustomEntrypoint';


@pragma('vm:entry-point')
void customEntrypoint1() {
  sayHiFromCustomEntrypoint1();
  sayHiFromCustomEntrypoint2();
  sayHiFromCustomEntrypoint3();
}

void sayHiFromCustomEntrypoint1() native 'SayHiFromCustomEntrypoint1';
void sayHiFromCustomEntrypoint2() native 'SayHiFromCustomEntrypoint2';
void sayHiFromCustomEntrypoint3() native 'SayHiFromCustomEntrypoint3';


@pragma('vm:entry-point')
void invokePlatformTaskRunner() {
  window.sendPlatformMessage('OhHi', null, null);
}


Float64List kTestTransform = () {
  final Float64List values = Float64List(16);
  values[0] = 1.0;  // scaleX
  values[4] = 2.0;  // skewX
  values[12] = 3.0; // transX
  values[1] = 4.0;  // skewY
  values[5] = 5.0;  // scaleY
  values[13] = 6.0; // transY
  values[3] = 7.0;  // pers0
  values[7] = 8.0;  // pers1
  values[15] = 9.0; // pers2
  return values;
}();

void signalNativeTest() native 'SignalNativeTest';
void signalNativeMessage(String message) native 'SignalNativeMessage';
void notifySemanticsEnabled(bool enabled) native 'NotifySemanticsEnabled';
void notifyAccessibilityFeatures(bool reduceMotion) native 'NotifyAccessibilityFeatures';
void notifySemanticsAction(int nodeId, int action, List<int> data) native 'NotifySemanticsAction';

/// Returns a future that completes when `window.onSemanticsEnabledChanged`
/// fires.
Future<void> get semanticsChanged {
  final Completer<void> semanticsChanged = Completer<void>();
  window.onSemanticsEnabledChanged = semanticsChanged.complete;
  return semanticsChanged.future;
}

/// Returns a future that completes when `window.onAccessibilityFeaturesChanged`
/// fires.
Future<void> get accessibilityFeaturesChanged {
  final Completer<void> featuresChanged = Completer<void>();
  window.onAccessibilityFeaturesChanged = featuresChanged.complete;
  return featuresChanged.future;
}

class SemanticsActionData {
  const SemanticsActionData(this.id, this.action, this.args);
  final int id;
  final SemanticsAction action;
  final ByteData args;
}

Future<SemanticsActionData> get semanticsAction {
  final Completer<SemanticsActionData> actionReceived = Completer<SemanticsActionData>();
  window.onSemanticsAction = (int id, SemanticsAction action, ByteData args) {
    actionReceived.complete(SemanticsActionData(id, action, args));
  };
  return actionReceived.future;
}

@pragma('vm:entry-point')
void a11y_main() async { // ignore: non_constant_identifier_names
  // Return initial state (semantics disabled).
  notifySemanticsEnabled(window.semanticsEnabled);

  // Await semantics enabled from embedder.
  await semanticsChanged;
  notifySemanticsEnabled(window.semanticsEnabled);

  // Return initial state of accessibility features.
  notifyAccessibilityFeatures(window.accessibilityFeatures.reduceMotion);

  // Await accessibility features changed from embedder.
  await accessibilityFeaturesChanged;
  notifyAccessibilityFeatures(window.accessibilityFeatures.reduceMotion);

  // Fire semantics update.
  final SemanticsUpdateBuilder builder = SemanticsUpdateBuilder()
    ..updateNode(
      id: 42,
      label: 'A: root',
      rect: Rect.fromLTRB(0.0, 0.0, 10.0, 10.0),
      transform: kTestTransform,
      childrenInTraversalOrder: Int32List.fromList(<int>[84, 96]),
      childrenInHitTestOrder: Int32List.fromList(<int>[96, 84]),
    )
    ..updateNode(
      id: 84,
      label: 'B: leaf',
      rect: Rect.fromLTRB(40.0, 40.0, 80.0, 80.0),
      transform: kTestTransform,
    )
    ..updateNode(
      id: 96,
      label: 'C: branch',
      rect: Rect.fromLTRB(40.0, 40.0, 80.0, 80.0),
      transform: kTestTransform,
      childrenInTraversalOrder: Int32List.fromList(<int>[128]),
      childrenInHitTestOrder: Int32List.fromList(<int>[128]),
    )
    ..updateNode(
      id: 128,
      label: 'D: leaf',
      rect: Rect.fromLTRB(40.0, 40.0, 80.0, 80.0),
      transform: kTestTransform,
      additionalActions: Int32List.fromList(<int>[21]),
    )
    ..updateCustomAction(
      id: 21,
      label: 'Archive',
      hint: 'archive message',
    );
  window.updateSemantics(builder.build());
  signalNativeTest();

  // Await semantics action from embedder.
  final SemanticsActionData data = await semanticsAction;
  final List<int> actionArgs = <int>[data.args.getInt8(0), data.args.getInt8(1)];
  notifySemanticsAction(data.id, data.action.index, actionArgs);

  // Await semantics disabled from embedder.
  await semanticsChanged;
  notifySemanticsEnabled(window.semanticsEnabled);
}


@pragma('vm:entry-point')
void platform_messages_response() {
  window.onPlatformMessage = (String name, ByteData data, PlatformMessageResponseCallback callback) {
    callback(data);
  };
  signalNativeTest();
}

@pragma('vm:entry-point')
void platform_messages_no_response() {
  window.onPlatformMessage = (String name, ByteData data, PlatformMessageResponseCallback callback) {
    var list = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    signalNativeMessage(utf8.decode(list));
    // This does nothing because no one is listening on the other side. But complete the loop anyway
    // to make sure all null checking on response handles in the engine is in place.
    callback(data);
  };
  signalNativeTest();
}

@pragma('vm:entry-point')
void null_platform_messages() {
  window.onPlatformMessage =
      (String name, ByteData data, PlatformMessageResponseCallback callback) {
    // This checks if the platform_message null data is converted to Flutter null.
    signalNativeMessage((null == data).toString());
    callback(data);
  };
  signalNativeTest();
}
