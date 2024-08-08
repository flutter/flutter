// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui hide TextStyle;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'focus_manager.dart';
import 'framework.dart';

/// Describes how [EditableText] widgets should behave.
///
/// {@template flutter.widgets.TapOutsideBehavior}
/// Used by [TapOutsideConfiguration] to configure the [EditableText] widgets in a
/// subtree.
///
/// This class can be extended to further customize a [TapOutsideBehavior] for a
/// subtree. For example, overriding [TapOutsideBehavior.defaultOnTapOutside] sets the
/// default [EditableText.onTapOutside] for [EditableText]s that inherit this [TapOutsideConfiguration].
/// {@endtemplate}
///
/// See also:
///
///   * [TapOutsideConfiguration], the inherited widget that controls how
///     [EditableText] widgets behave in a subtree.
@immutable
class TapOutsideBehavior {
  /// Creates a description of how [EditableText] widgets should behave.
  const TapOutsideBehavior();

  /// The default behavior used if [EditableText.onTapOutside] is null.
  ///
  /// The `event` argument is the [PointerDownEvent] that caused the notification.
  void defaultOnTapOutside(PointerDownEvent event, FocusNode focusNode) {
    /// The focus dropping behavior is only present on desktop platforms
    /// and mobile browsers.
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        // On mobile platforms, we don't unfocus on touch events unless they're
        // in the web browser, but we do unfocus for all other kinds of events.
        switch (event.kind) {
          case ui.PointerDeviceKind.touch:
            if (kIsWeb) {
              focusNode.unfocus();
            }
          case ui.PointerDeviceKind.mouse:
          case ui.PointerDeviceKind.stylus:
          case ui.PointerDeviceKind.invertedStylus:
          case ui.PointerDeviceKind.unknown:
            focusNode.unfocus();
          case ui.PointerDeviceKind.trackpad:
            throw UnimplementedError(
                'Unexpected pointer down event for trackpad');
        }
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        focusNode.unfocus();
    }
  }

  /// Called whenever a [TapOutsideConfiguration] is rebuilt with a new
  /// [TapOutsideBehavior] of the same [runtimeType].
  ///
  /// If the new instance represents different information than the old
  /// instance, then the method should return true, otherwise it should return
  /// false.
  ///
  /// If this method returns true, all the widgets that inherit from the
  /// [TapOutsideConfiguration] will rebuild using the new [TapOutsideBehavior]. If this
  /// method returns false, the rebuilds might be optimized away.
  bool shouldNotify(covariant TapOutsideBehavior oldDelegate) => false;

  @override
  String toString() => objectRuntimeType(this, 'TapOutsideBehavior');
}

/// Behavior which always, regardless of platform, call [FocusNode.unfocus] on tap outside the [EditableText].
class AlwaysUnfocusTapOutsideBehavior extends TapOutsideBehavior {
  /// Creates a AlwaysUnfocusTapOutsideBehavior that always unfocuses the [FocusNode] on tap outside the [EditableText].
  const AlwaysUnfocusTapOutsideBehavior();

  @override
  void defaultOnTapOutside(PointerDownEvent event, FocusNode focusNode) {
    focusNode.unfocus();
  }
}

/// Behavior which, regardless of platform, do nothing on tap outside the [EditableText].
class NeverUnfocusTapOutsideBehavior extends TapOutsideBehavior {
  /// Creates a NeverUnfocusTapOutsideBehavior that never unfocuses the [FocusNode] on tap outside the [EditableText].
  const NeverUnfocusTapOutsideBehavior();

  @override
  void defaultOnTapOutside(PointerDownEvent event, FocusNode focusNode) {}
}

/// Controls how [EditableText] widgets behave in a subtree.
///
/// The touch outside configuration determines the [TapOutsideBehavior] used by descendants of [child].
class TapOutsideConfiguration extends InheritedWidget {
  /// Creates a widget that controls how [EditableText] widgets behave in a subtree.
  const TapOutsideConfiguration({
    super.key,
    required this.behavior,
    required super.child,
  });

  /// How [EditableText] widgets that are descendants of [child] should behave.
  final TapOutsideBehavior behavior;

  /// The [TapOutsideBehavior] for [EditableText] widgets in the given [BuildContext].
  ///
  /// If no [TapOutsideConfiguration] widget is in scope of the given `context`,
  /// a default [TapOutsideBehavior] instance is returned.
  static TapOutsideBehavior of(BuildContext context) {
    final TapOutsideConfiguration? configuration =
        context.dependOnInheritedWidgetOfExactType<TapOutsideConfiguration>();
    return configuration?.behavior ?? const TapOutsideBehavior();
  }

  @override
  bool updateShouldNotify(TapOutsideConfiguration oldWidget) {
    return behavior.runtimeType != oldWidget.behavior.runtimeType ||
        (behavior != oldWidget.behavior &&
            behavior.shouldNotify(oldWidget.behavior));
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<TapOutsideBehavior>('behavior', behavior));
  }
}
