import 'dart:async';
import 'dart:ui';

import 'package:flutter/widgets.dart' show VoidCallback;
import 'package:photo_view/src/photo_view_scale_state.dart';
import 'package:photo_view/src/utils/ignorable_change_notifier.dart';

typedef ScaleStateListener = void Function(double prevScale, double nextScale);

/// A controller responsible only by [scaleState].
///
/// Scale state is a common value with represents the step in which the [PhotoView.scaleStateCycle] is.
/// This cycle is triggered by the "doubleTap" gesture.
///
/// Any change in its [scaleState] should animate the scale of image/content.
///
/// As it is a controller, whoever instantiates it, should [dispose] it afterwards.
///
/// The updates should be done via [scaleState] setter and the updated listened via [outputScaleStateStream]
///
class PhotoViewScaleStateController {
  late final IgnorableValueNotifier<PhotoViewScaleState> _scaleStateNotifier =
      IgnorableValueNotifier(PhotoViewScaleState.initial)
        ..addListener(_scaleStateChangeListener);
  final StreamController<PhotoViewScaleState> _outputScaleStateCtrl =
      StreamController<PhotoViewScaleState>.broadcast()
        ..sink.add(PhotoViewScaleState.initial);

  /// The output for state/value updates
  Stream<PhotoViewScaleState> get outputScaleStateStream =>
      _outputScaleStateCtrl.stream;

  /// The state value before the last change or the initial state if the state has not been changed.
  PhotoViewScaleState prevScaleState = PhotoViewScaleState.initial;

  /// The actual state value
  PhotoViewScaleState get scaleState => _scaleStateNotifier.value;

  /// Updates scaleState and notify all listeners (and the stream)
  set scaleState(PhotoViewScaleState newValue) {
    if (_scaleStateNotifier.value == newValue) {
      return;
    }

    prevScaleState = _scaleStateNotifier.value;
    _scaleStateNotifier.value = newValue;
  }

  /// Checks if its actual value is different than previousValue
  bool get hasChanged => prevScaleState != scaleState;

  /// Check if is `zoomedIn` & `zoomedOut`
  bool get isZooming =>
      scaleState == PhotoViewScaleState.zoomedIn ||
      scaleState == PhotoViewScaleState.zoomedOut;

  /// Resets the state to the initial value;
  void reset() {
    prevScaleState = scaleState;
    scaleState = PhotoViewScaleState.initial;
  }

  /// Closes streams and removes eventual listeners
  void dispose() {
    _outputScaleStateCtrl.close();
    _scaleStateNotifier.dispose();
  }

  /// Nevermind this method :D, look away
  /// Seriously: It is used to change scale state without trigging updates on the []
  void setInvisibly(PhotoViewScaleState newValue) {
    if (_scaleStateNotifier.value == newValue) {
      return;
    }
    prevScaleState = _scaleStateNotifier.value;
    _scaleStateNotifier.updateIgnoring(newValue);
  }

  void _scaleStateChangeListener() {
    _outputScaleStateCtrl.sink.add(scaleState);
  }

  /// Add a listener that will ignore updates made internally
  ///
  /// Since it is made for internal use, it is not performatic to use more than one
  /// listener. Prefer [outputScaleStateStream]
  void addIgnorableListener(VoidCallback callback) {
    _scaleStateNotifier.addIgnorableListener(callback);
  }

  /// Remove a listener that will ignore updates made internally
  ///
  /// Since it is made for internal use, it is not performatic to use more than one
  /// listener. Prefer [outputScaleStateStream]
  void removeIgnorableListener(VoidCallback callback) {
    _scaleStateNotifier.removeIgnorableListener(callback);
  }
}
