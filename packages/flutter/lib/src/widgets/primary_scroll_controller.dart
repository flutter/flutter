// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'framework.dart';
import 'scroll_configuration.dart';
import 'scroll_controller.dart';

const Set<TargetPlatform> _kMobilePlatforms = <TargetPlatform>{
  TargetPlatform.android,
  TargetPlatform.iOS,
  TargetPlatform.fuchsia,
};

/// Associates a [ScrollController] with a subtree.
///
// TODO(Piinks): update docs if this concept tracks
///
/// When a [ScrollView] has [ScrollView.primary] set to true and is not given
/// an explicit [ScrollController], the [ScrollView] uses [of] to find the
/// [ScrollController] associated with its subtree.
///
/// This mechanism can be used to provide default behavior for scroll views in a
/// subtree. For example, the [Scaffold] uses this mechanism to implement the
/// scroll-to-top gesture on iOS.
///
/// Another default behavior handled by the PrimaryScrollController is default
/// [ScrollAction]s. If a ScrollAction is not handled by an otherwise focused
/// part of the application, the ScrollAction will be evaluated using the scroll
/// view associated with a PrimaryScrollController, for example, when executing
/// [Shortcuts] key events like page up and down.
///
/// See also:
///   * [ScrollAction], an [Action] that scrolls the [Scrollable] that encloses
///     the current [primaryFocus] or is attached to the PrimaryScrollController.
///   * [Shortcuts], a widget that establishes a [ShortcutManager] to be used
///     by its descendants when invoking an [Action] via a keyboard key
///     combination that maps to an [Intent].
class PrimaryScrollController extends InheritedWidget {
  /// Creates a widget that associates a [ScrollController] with a subtree.
  const PrimaryScrollController({
    super.key,
    required ScrollController this.controller,
    this.autoForPlatforms = _kMobilePlatforms,
    this.scrollDirection = Axis.vertical,
    required super.child,
  }) : assert(controller != null);

  /// Creates a subtree without an associated [ScrollController].
  const PrimaryScrollController.none({
    super.key,
    required super.child,
  }) : autoForPlatforms = const <TargetPlatform>{},
       scrollDirection = null,
       controller = null;

  /// The [ScrollController] associated with the subtree.
  ///
  /// See also:
  ///
  ///  * [ScrollView.controller], which discusses the purpose of specifying a
  ///    scroll controller.
  final ScrollController? controller;

  /// The [Axis] this controller is configured for [ScrollView]s to
  /// automatically inherit.
  ///
  /// Used in conjunction with [autoForPlatforms]. If the current
  /// [TargetPlatform] is not included in [autoForPlatforms], this is ignored.
  ///
  /// When null, no ScrollView in any Axis will automatically inherit this
  /// controller. Defaults to [Axis.vertical].
  final Axis? scrollDirection;

  /// The [TargetPlatform]s this controller is configured for [ScrollView]s to
  /// automatically inherit.
  ///
  /// Used in conjunction with [scrollDirection]. If the given [Axis] is not
  /// [scrollDirection], this is ignored.
  ///
  /// When empty, no ScrollView in any Axis will automatically inherit this
  /// controller. Defaults to [TargetPlatformVariant.mobile].
  // TODO(Piinks): Consider a better name if this concept tracks
  final Set<TargetPlatform> autoForPlatforms;

  /// Returns true if this PrimaryScrollController is configured to be
  /// automatically inherited for the current [TargetPlatform] and the given
  /// [Axis].
  ///
  /// If a [ScrollController] has already been provided to
  /// [ScrollView.controller], or [ScrollView.primary] is false, this is
  /// disregarded.
  static bool shouldInherit(BuildContext context, Axis scrollDirection) {
    final PrimaryScrollController? result = context.findAncestorWidgetOfExactType<PrimaryScrollController>();
    final TargetPlatform platform = ScrollConfiguration.of(context).getPlatform(context);
    if (result == null)
      return false;

    if (result.autoForPlatforms.contains(platform))
      return result.scrollDirection == scrollDirection;
    return false;
  }

  /// Returns the [ScrollController] most closely associated with the given
  /// context.
  ///
  /// Returns null if there is no [ScrollController] associated with the given
  /// context.
  static ScrollController? of(BuildContext context) {
    final PrimaryScrollController? result = context.dependOnInheritedWidgetOfExactType<PrimaryScrollController>();
    return result?.controller;
  }

  @override
  bool updateShouldNotify(PrimaryScrollController oldWidget) => controller != oldWidget.controller;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ScrollController>('controller', controller, ifNull: 'no controller', showName: false));
  }
}
