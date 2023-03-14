// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// A callback type that is used by [AppLifecycleListener.onExitRequested] to
/// ask the application if it wants to cancel application termination or not.
typedef AppExitRequestCallback = Future<AppExitResponse> Function();

/// A listener that can be used to listen to changes in the application
/// lifecycle.
///
/// To listen for requests for the application to exit, and to decide whether or
/// not the application should exit when requested, create an
/// [AppLifecycleListener] and set the [onExitRequested] callback. On macOS, in
/// order to receive application exit requests originating from the OS, the
/// `NSPrincipalClass` in your `Info.plist` file must be set to
/// `FlutterApplication`, or a subclass of `FlutterApplication`.
///
/// To listen for changes in the application lifecycle state, define an
/// [onStateChange] callback. The most recent state seen by this
/// [AppLifecycleListener] can be retrieved with the [lifecycleState] accessor.
/// See the [AppLifecycleState] enum for details on the various states.
///
/// {@tool dartpad}
/// This examples shows how an application can optionally decide
/// to abort a request for exiting instead of obeying the request.
///
/// ** See code in examples/api/lib/widgets/app_lifecycle_listener/app_lifecycle_listener.0.dart **
/// {@end-tool}
///
/// See also:
///
/// * [ServicesBinding.exitApplication] for a function to call that will request
///   that the application exits.
/// * [WidgetsBindingObserver.didRequestAppExit] for the handler which this
///   class uses to receive exit requests.
/// * [WidgetsBindingObserver.didChangeAppLifecycleState] for the handler which
///   this class uses to receive lifecycle state changes.
class AppLifecycleListener with WidgetsBindingObserver, Diagnosticable {
  /// Creates an [AppLifecycleListener].
  AppLifecycleListener({
    WidgetsBinding? binding,
    this.onExitRequested,
    this.onStateChange,
  }) : binding = binding ?? WidgetsBinding.instance,
      _lifecycleState = AppLifecycleState.detached {
    this.binding.addObserver(this);
  }

  /// Returns the most recent lifecycle state seen by this
  /// [AppLifecycleListener].
  AppLifecycleState get lifecycleState => _lifecycleState;
  AppLifecycleState _lifecycleState;

  /// The [WidgetsBinding] to listen to for application lifecycle events.
  ///
  /// Typically, this is set to [WidgetsBinding.instance], but may be
  /// substituted for testing or other specialized bindings.
  final WidgetsBinding binding;

  /// Called anytime the state changes, passing the new state.
  final ValueChanged<AppLifecycleState>? onStateChange;

  /// A callback used to ask the application if it will allow exiting the
  /// application for cases where the exit is cancelable.
  ///
  /// Exiting the application isn't always cancelable, but when it is, this
  /// function will be called before exit occurs.
  ///
  /// Responding [AppExitResponse.exit] will continue termination, and
  /// responding [AppExitResponse.cancel] will cancel it. If termination
  /// is not canceled, the application will immediately exit.
  ///
  /// If there are multiple instances of [AppLifecycleListener] in the app, then
  /// if any of them respond [AppExitResponse.cancel], it will cancel the exit.
  /// All listeners will be asked before the application exits, even if one
  /// responds [AppExitResponse.cancel].
  final AppExitRequestCallback? onExitRequested;

  bool _debugDisposed = false;

  /// Call when the listener is no longer in use.
  ///
  /// Do not use the object after calling [dispose].
  ///
  /// Subclasses must call this method in their overridden [dispose], if any.
  @mustCallSuper
  void dispose() {
    assert(_debugAssertNotDisposed());
    binding.removeObserver(this);
    _debugDisposed = true;
  }

  bool _debugAssertNotDisposed() {
    assert(() {
      if (_debugDisposed) {
        throw FlutterError(
          'A $runtimeType was used after being disposed.\n'
          'Once you have called dispose() on a $runtimeType, it '
          'can no longer be used.',
        );
      }
      return true;
    }());
    return true;
  }

  @override
  Future<AppExitResponse> didRequestAppExit() async {
    assert(_debugAssertNotDisposed());
    if (onExitRequested == null) {
      return AppExitResponse.exit;
    }
    return onExitRequested!();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    assert(_debugAssertNotDisposed());
    if (state == _lifecycleState) {
      return;
    }
    _lifecycleState = state;
    onStateChange?.call(_lifecycleState);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<WidgetsBinding>('binding', binding));
    properties.add(FlagProperty('onStateChange', value: onStateChange != null, ifTrue: 'onStateChange', defaultValue: false));
    properties.add(FlagProperty('onExitRequested', value: onExitRequested != null, ifTrue: 'onExitRequested', defaultValue: false));
  }
}
