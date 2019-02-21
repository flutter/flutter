import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

Float64List kIdentityTransform = () {
  final Float64List values = Float64List(16);
  values[0] = 1.0;
  values[5] = 1.0;
  values[10] = 1.0;
  values[15] = 1.0;
  return values;
}();

void signalNativeTest() native 'SignalNativeTest';
void notifySemanticsEnabled(bool enabled) native 'NotifyTestData1';
void notifyAccessibilityFeatures(bool reduceMotion) native 'NotifyTestData1';
void notifySemanticsAction(int nodeId, int action, List<int> data) native 'NotifyTestData3';

/// Returns a future that completes when `window.onSemanticsEnabledChanged`
/// fires.
Future get semanticsChanged {
  final Completer semanticsChanged = Completer();
  window.onSemanticsEnabledChanged = semanticsChanged.complete;
  return semanticsChanged.future;
}

/// Returns a future that completes when `window.onAccessibilityFeaturesChanged`
/// fires.
Future get accessibilityFeaturesChanged {
  final Completer featuresChanged = Completer();
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
  final Completer actionReceived = Completer<SemanticsActionData>();
  window.onSemanticsAction = (int id, SemanticsAction action, ByteData args) {
    actionReceived.complete(SemanticsActionData(id, action, args));
  };
  return actionReceived.future;
}

main() async {
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
      transform: kIdentityTransform,
      childrenInTraversalOrder: Int32List.fromList(<int>[84, 96]),
      childrenInHitTestOrder: Int32List.fromList(<int>[96, 84]),
    )
    ..updateNode(
      id: 84,
      label: 'B: leaf',
      rect: Rect.fromLTRB(40.0, 40.0, 80.0, 80.0),
      transform: kIdentityTransform,
    )
    ..updateNode(
      id: 96,
      label: 'C: branch',
      rect: Rect.fromLTRB(40.0, 40.0, 80.0, 80.0),
      transform: kIdentityTransform,
      childrenInTraversalOrder: Int32List.fromList(<int>[128]),
      childrenInHitTestOrder: Int32List.fromList(<int>[128]),
    )
    ..updateNode(
      id: 128,
      label: 'D: leaf',
      rect: Rect.fromLTRB(40.0, 40.0, 80.0, 80.0),
      transform: kIdentityTransform,
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
