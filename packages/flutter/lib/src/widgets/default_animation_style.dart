// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'implicit_animations.dart';
library;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

import 'framework.dart';
import 'inherited_notifier.dart';
import 'inherited_theme.dart';

/// Defines a default configuration for animation [Duration]s and [Curve]s.
///
/// If an [ImplicitlyAnimatedWidget]'s duration or curve is not defined,
/// it will default to the values specified in the closest ancestor
/// `DefaultAnimationStyle`, if one exists; otherwise it will use
/// [fallbackDuration] and/or [fallbackCurve] respectively.
class DefaultAnimationStyle extends StatefulWidget {
  /// Creates a default configuration for animation [Duration]s and [Curve]s.
  const DefaultAnimationStyle({
    super.key,
    required this.style,
    this.inherit = true,
    required this.child,
  });

  /// The animation style to be used by the widget's descendants.
  final AnimationStyle style;

  /// Determines whether null values from the provided `style` are filled in with
  /// non-null properties from further up in the widget tree, if applicable.
  ///
  /// Defaults to `true`.
  final bool inherit;

  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  /// Returns the [AnimationStyle] corresponding to the nearest ancestor
  /// [DefaultAnimationStyle] widget.
  ///
  /// If no such widget is found, returns an [AnimationStyle] object with
  /// each property set to `null`.
  static AnimationStyle of(BuildContext context, {bool createDependency = true}) {
    final _InheritedAnimationStyle? inherited = createDependency
        ? context.dependOnInheritedWidgetOfExactType()
        : context.getInheritedWidgetOfExactType();

    return inherited?.notifier?.value ?? const AnimationStyle();
  }

  /// Returns a [ValueListenable] object from the nearest ancestor
  /// [DefaultAnimationStyle] widget.
  ///
  /// This can be useful for responding to animation style updates
  /// without notifying the respective [BuildContext] to rebuild.
  static ValueListenable<AnimationStyle> getNotifier(BuildContext context) {
    const fallback = AlwaysStoppedAnimation<AnimationStyle>(AnimationStyle());
    if (!context.mounted) {
      return fallback;
    }

    final _InheritedAnimationStyle? inheritedWidget = context.getInheritedWidgetOfExactType();
    return inheritedWidget?.notifier ?? fallback;
  }

  /// A duration of 300 ms, used by widgets that depend on an ancestor [DefaultAnimationStyle]
  /// when no such ancestor can be found.
  static const Duration fallbackDuration = Duration(milliseconds: 300);

  /// A linear curve, used by widgets that depend on an ancestor [DefaultAnimationStyle]
  /// when no such ancestor can be found.
  static const Curve fallbackCurve = Curves.linear;

  @override
  State<DefaultAnimationStyle> createState() => _DefaultAnimationStyleState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<AnimationStyle>('style', style));
    properties.add(FlagProperty('inherit', value: inherit));
  }
}

class _DefaultAnimationStyleState extends State<DefaultAnimationStyle> {
  late final ValueNotifier<AnimationStyle> notifier = ValueNotifier<AnimationStyle>(widget.style);
  late ValueListenable<AnimationStyle> ancestor = DefaultAnimationStyle.getNotifier(context);

  @override
  void initState() {
    super.initState();
    ancestor.addListener(_updateStyle);
  }

  @override
  void activate() {
    super.activate();
    final ValueListenable<AnimationStyle> newAncestorNotifier = DefaultAnimationStyle.getNotifier(
      context,
    );
    if (newAncestorNotifier == ancestor) {
      return;
    }
    ancestor.removeListener(_updateStyle);
    ancestor = newAncestorNotifier..addListener(_updateStyle);
  }

  void _updateStyle() {
    final AnimationStyle style = widget.style;
    notifier.value = widget.inherit ? ancestor.value.merge(style) : style;
  }

  @override
  void dispose() {
    ancestor.removeListener(_updateStyle);
    notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _updateStyle();
    return _InheritedAnimationStyle(notifier: notifier, child: widget.child);
  }
}

class _InheritedAnimationStyle extends InheritedNotifier<ValueListenable<AnimationStyle>>
    implements InheritedTheme {
  const _InheritedAnimationStyle({required super.notifier, required super.child});

  @override
  Widget wrap(BuildContext context, Widget child) {
    return DefaultAnimationStyle(style: notifier!.value, child: child);
  }
}
