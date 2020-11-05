// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(dnfield): Remove unused_import ignores when https://github.com/dart-lang/sdk/issues/35164 is resolved.

// @dart = 2.10

part of dart.ui;

@pragma('vm:entry-point')
// ignore: unused_element
void _updateWindowMetrics(
  Object id,
  double devicePixelRatio,
  double width,
  double height,
  double viewPaddingTop,
  double viewPaddingRight,
  double viewPaddingBottom,
  double viewPaddingLeft,
  double viewInsetTop,
  double viewInsetRight,
  double viewInsetBottom,
  double viewInsetLeft,
  double systemGestureInsetTop,
  double systemGestureInsetRight,
  double systemGestureInsetBottom,
  double systemGestureInsetLeft,
) {
  PlatformDispatcher.instance._updateWindowMetrics(
    id,
    devicePixelRatio,
    width,
    height,
    viewPaddingTop,
    viewPaddingRight,
    viewPaddingBottom,
    viewPaddingLeft,
    viewInsetTop,
    viewInsetRight,
    viewInsetBottom,
    viewInsetLeft,
    systemGestureInsetTop,
    systemGestureInsetRight,
    systemGestureInsetBottom,
    systemGestureInsetLeft,
  );
}

typedef _LocaleClosure = String Function();

@pragma('vm:entry-point')
// ignore: unused_element
_LocaleClosure? _getLocaleClosure() => PlatformDispatcher.instance._localeClosure;

@pragma('vm:entry-point')
// ignore: unused_element
void _updateLocales(List<String> locales) {
  PlatformDispatcher.instance._updateLocales(locales);
}

@pragma('vm:entry-point')
// ignore: unused_element
void _updateUserSettingsData(String jsonData) {
  PlatformDispatcher.instance._updateUserSettingsData(jsonData);
}

@pragma('vm:entry-point')
// ignore: unused_element
void _updateLifecycleState(String state) {
  PlatformDispatcher.instance._updateLifecycleState(state);
}

@pragma('vm:entry-point')
// ignore: unused_element
void _updateSemanticsEnabled(bool enabled) {
  PlatformDispatcher.instance._updateSemanticsEnabled(enabled);
}

@pragma('vm:entry-point')
// ignore: unused_element
void _updateAccessibilityFeatures(int values) {
  PlatformDispatcher.instance._updateAccessibilityFeatures(values);
}

@pragma('vm:entry-point')
// ignore: unused_element
void _dispatchPlatformMessage(String name, ByteData? data, int responseId) {
  PlatformDispatcher.instance._dispatchPlatformMessage(name, data, responseId);
}

@pragma('vm:entry-point')
// ignore: unused_element
void _dispatchPointerDataPacket(ByteData packet) {
  PlatformDispatcher.instance._dispatchPointerDataPacket(packet);
}

@pragma('vm:entry-point')
// ignore: unused_element
void _dispatchSemanticsAction(int id, int action, ByteData? args) {
  PlatformDispatcher.instance._dispatchSemanticsAction(id, action, args);
}

@pragma('vm:entry-point')
// ignore: unused_element
void _beginFrame(int microseconds) {
  PlatformDispatcher.instance._beginFrame(microseconds);
}

@pragma('vm:entry-point')
// ignore: unused_element
void _reportTimings(List<int> timings) {
  PlatformDispatcher.instance._reportTimings(timings);
}

@pragma('vm:entry-point')
// ignore: unused_element
void _drawFrame() {
  PlatformDispatcher.instance._drawFrame();
}

// ignore: always_declare_return_types, prefer_generic_function_type_aliases
typedef _ListStringArgFunction(List<String> args);

@pragma('vm:entry-point')
// ignore: unused_element
void _runMainZoned(Function startMainIsolateFunction,
                   Function userMainFunction,
                   List<String> args) {
  startMainIsolateFunction(() {
    runZonedGuarded<void>(() {
      if (userMainFunction is _ListStringArgFunction) {
        (userMainFunction as dynamic)(args);
      } else {
        userMainFunction();
      }
    }, (Object error, StackTrace stackTrace) {
      _reportUnhandledException(error.toString(), stackTrace.toString());
    });
  }, null);
}

void _reportUnhandledException(String error, String stackTrace) native 'PlatformConfiguration_reportUnhandledException';

/// Invokes [callback] inside the given [zone].
void _invoke(void Function()? callback, Zone zone) {
  if (callback == null) {
    return;
  }

  assert(zone != null); // ignore: unnecessary_null_comparison

  if (identical(zone, Zone.current)) {
    callback();
  } else {
    zone.runGuarded(callback);
  }
}

/// Invokes [callback] inside the given [zone] passing it [arg].
///
/// The 1 in the name refers to the number of arguments expected by
/// the callback (and thus passed to this function, in addition to the
/// callback itself and the zone in which the callback is executed).
void _invoke1<A>(void Function(A a)? callback, Zone zone, A arg) {
  if (callback == null) {
    return;
  }

  assert(zone != null); // ignore: unnecessary_null_comparison

  if (identical(zone, Zone.current)) {
    callback(arg);
  } else {
    zone.runUnaryGuarded<A>(callback, arg);
  }
}

/// Invokes [callback] inside the given [zone] passing it [arg1] and [arg2].
///
/// The 2 in the name refers to the number of arguments expected by
/// the callback (and thus passed to this function, in addition to the
/// callback itself and the zone in which the callback is executed).
void _invoke2<A1, A2>(void Function(A1 a1, A2 a2)? callback, Zone zone, A1 arg1, A2 arg2) {
  if (callback == null) {
    return;
  }

  assert(zone != null); // ignore: unnecessary_null_comparison

  if (identical(zone, Zone.current)) {
    callback(arg1, arg2);
  } else {
    zone.runGuarded(() {
      callback(arg1, arg2);
    });
  }
}

/// Invokes [callback] inside the given [zone] passing it [arg1], [arg2], and [arg3].
///
/// The 3 in the name refers to the number of arguments expected by
/// the callback (and thus passed to this function, in addition to the
/// callback itself and the zone in which the callback is executed).
void _invoke3<A1, A2, A3>(void Function(A1 a1, A2 a2, A3 a3)? callback, Zone zone, A1 arg1, A2 arg2, A3 arg3) {
  if (callback == null) {
    return;
  }

  assert(zone != null); // ignore: unnecessary_null_comparison

  if (identical(zone, Zone.current)) {
    callback(arg1, arg2, arg3);
  } else {
    zone.runGuarded(() {
      callback(arg1, arg2, arg3);
    });
  }
}
