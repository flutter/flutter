import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:photo_view/src/utils/ignorable_change_notifier.dart';

/// The interface in which controllers will be implemented.
///
/// It concerns storing the state ([PhotoViewControllerValue]) and streaming its updates.
/// [PhotoViewImageWrapper] will respond to user gestures setting thew fields in the instance of a controller.
///
/// Any instance of a controller must be disposed after unmount. So if you instantiate a [PhotoViewController] or your custom implementation, do not forget to dispose it when not using it anymore.
///
/// The controller exposes value fields like [scale] or [rotationFocus]. Usually those fields will be only getters and setters serving as hooks to the internal [PhotoViewControllerValue].
///
/// The default implementation used by [PhotoView] is [PhotoViewController].
///
/// This was created to allow customization (you can create your own controller class)
///
/// Previously it controlled `scaleState` as well, but duw to some [concerns](https://github.com/renancaraujo/photo_view/issues/127)
/// [ScaleStateListener is responsible for tat value now
///
/// As it is a controller, whoever instantiates it, should [dispose] it afterwards.
///
abstract class PhotoViewControllerBase<T extends PhotoViewControllerValue> {
  /// The output for state/value updates. Usually a broadcast [Stream]
  Stream<T> get outputStateStream;

  /// The state value before the last change or the initial state if the state has not been changed.
  late T prevValue;

  /// The actual state value
  late T value;

  /// Resets the state to the initial value;
  void reset();

  /// Closes streams and removes eventual listeners.
  void dispose();

  /// Add a listener that will ignore updates made internally
  ///
  /// Since it is made for internal use, it is not performatic to use more than one
  /// listener. Prefer [outputStateStream]
  void addIgnorableListener(VoidCallback callback);

  /// Remove a listener that will ignore updates made internally
  ///
  /// Since it is made for internal use, it is not performatic to use more than one
  /// listener. Prefer [outputStateStream]
  void removeIgnorableListener(VoidCallback callback);

  /// The position of the image in the screen given its offset after pan gestures.
  late Offset position;

  /// The scale factor to transform the child (image or a customChild).
  late double? scale;

  /// Nevermind this method :D, look away
  void setScaleInvisibly(double? scale);

  /// The rotation factor to transform the child (image or a customChild).
  late double rotation;

  /// The center of the rotation transformation. It is a coordinate referring to the absolute dimensions of the image.
  Offset? rotationFocusPoint;

  /// Update multiple fields of the state with only one update streamed.
  void updateMultiple({
    Offset? position,
    double? scale,
    double? rotation,
    Offset? rotationFocusPoint,
  });
}

/// The state value stored and streamed by [PhotoViewController].
@immutable
class PhotoViewControllerValue {
  const PhotoViewControllerValue({
    required this.position,
    required this.scale,
    required this.rotation,
    required this.rotationFocusPoint,
  });

  final Offset position;
  final double? scale;
  final double rotation;
  final Offset? rotationFocusPoint;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhotoViewControllerValue &&
          runtimeType == other.runtimeType &&
          position == other.position &&
          scale == other.scale &&
          rotation == other.rotation &&
          rotationFocusPoint == other.rotationFocusPoint;

  @override
  int get hashCode =>
      position.hashCode ^
      scale.hashCode ^
      rotation.hashCode ^
      rotationFocusPoint.hashCode;

  @override
  String toString() {
    return 'PhotoViewControllerValue{position: $position, scale: $scale, rotation: $rotation, rotationFocusPoint: $rotationFocusPoint}';
  }
}

/// The default implementation of [PhotoViewControllerBase].
///
/// Containing a [ValueNotifier] it stores the state in the [value] field and streams
/// updates via [outputStateStream].
///
/// For details of fields and methods, check [PhotoViewControllerBase].
///
class PhotoViewController
    implements PhotoViewControllerBase<PhotoViewControllerValue> {
  PhotoViewController({
    Offset initialPosition = Offset.zero,
    double initialRotation = 0.0,
    double? initialScale,
  })  : _valueNotifier = IgnorableValueNotifier(
          PhotoViewControllerValue(
            position: initialPosition,
            rotation: initialRotation,
            scale: initialScale,
            rotationFocusPoint: null,
          ),
        ),
        super() {
    initial = value;
    prevValue = initial;

    _valueNotifier.addListener(_changeListener);
    _outputCtrl = StreamController<PhotoViewControllerValue>.broadcast();
    _outputCtrl.sink.add(initial);
  }

  final IgnorableValueNotifier<PhotoViewControllerValue> _valueNotifier;

  late PhotoViewControllerValue initial;

  late StreamController<PhotoViewControllerValue> _outputCtrl;

  @override
  Stream<PhotoViewControllerValue> get outputStateStream => _outputCtrl.stream;

  @override
  late PhotoViewControllerValue prevValue;

  @override
  void reset() {
    value = initial;
  }

  void _changeListener() {
    _outputCtrl.sink.add(value);
  }

  @override
  void addIgnorableListener(VoidCallback callback) {
    _valueNotifier.addIgnorableListener(callback);
  }

  @override
  void removeIgnorableListener(VoidCallback callback) {
    _valueNotifier.removeIgnorableListener(callback);
  }

  @override
  void dispose() {
    _outputCtrl.close();
    _valueNotifier.dispose();
  }

  @override
  set position(Offset position) {
    if (value.position == position) {
      return;
    }
    prevValue = value;
    value = PhotoViewControllerValue(
      position: position,
      scale: scale,
      rotation: rotation,
      rotationFocusPoint: rotationFocusPoint,
    );
  }

  @override
  Offset get position => value.position;

  @override
  set scale(double? scale) {
    if (value.scale == scale) {
      return;
    }
    prevValue = value;
    value = PhotoViewControllerValue(
      position: position,
      scale: scale,
      rotation: rotation,
      rotationFocusPoint: rotationFocusPoint,
    );
  }

  @override
  double? get scale => value.scale;

  @override
  void setScaleInvisibly(double? scale) {
    if (value.scale == scale) {
      return;
    }
    prevValue = value;
    _valueNotifier.updateIgnoring(
      PhotoViewControllerValue(
        position: position,
        scale: scale,
        rotation: rotation,
        rotationFocusPoint: rotationFocusPoint,
      ),
    );
  }

  @override
  set rotation(double rotation) {
    if (value.rotation == rotation) {
      return;
    }
    prevValue = value;
    value = PhotoViewControllerValue(
      position: position,
      scale: scale,
      rotation: rotation,
      rotationFocusPoint: rotationFocusPoint,
    );
  }

  @override
  double get rotation => value.rotation;

  @override
  set rotationFocusPoint(Offset? rotationFocusPoint) {
    if (value.rotationFocusPoint == rotationFocusPoint) {
      return;
    }
    prevValue = value;
    value = PhotoViewControllerValue(
      position: position,
      scale: scale,
      rotation: rotation,
      rotationFocusPoint: rotationFocusPoint,
    );
  }

  @override
  Offset? get rotationFocusPoint => value.rotationFocusPoint;

  @override
  void updateMultiple({
    Offset? position,
    double? scale,
    double? rotation,
    Offset? rotationFocusPoint,
  }) {
    prevValue = value;
    value = PhotoViewControllerValue(
      position: position ?? value.position,
      scale: scale ?? value.scale,
      rotation: rotation ?? value.rotation,
      rotationFocusPoint: rotationFocusPoint ?? value.rotationFocusPoint,
    );
  }

  @override
  PhotoViewControllerValue get value => _valueNotifier.value;

  @override
  set value(PhotoViewControllerValue newValue) {
    if (_valueNotifier.value == newValue) {
      return;
    }
    _valueNotifier.value = newValue;
  }
}
