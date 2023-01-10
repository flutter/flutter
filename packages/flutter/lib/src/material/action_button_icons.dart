// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'back_button.dart';
import 'drawer_button.dart';
import 'theme.dart';

/// A [ActionButtonIconsData] that overrides the default icons of
/// [BackButton], [CloseButton], [DrawerButton], and [EndDrawerButton] with the
/// overall [Theme]'s [ThemeData.actionButtonIcons].
@immutable
class ActionButtonIconsData with Diagnosticable {
  /// Creates an [ActionButtonIconsData].
  ///
  /// The builders [backButtonIconBuilder], [closeButtonIconBuilder], 
  /// [drawerButtonIconBuilder], [endDrawerButtonIconBuilder] may be null.
  const ActionButtonIconsData({ this.backButtonIconBuilder, this.closeButtonIconBuilder, this.drawerButtonIconBuilder, this.endDrawerButtonIconBuilder });

  /// Overrides [BackButtonIcon]'s icon.
  ///
  /// If [backButtonIconBuilder] is null, then [BackButtonIcon] 
  /// fallbacks to the platform's default back button icon.
  final WidgetBuilder? backButtonIconBuilder;

  /// Overrides [CloseButtonIcon]'s icon.
  ///
  /// If [closeButtonIconBuilder] is null, then [CloseButtonIcon] 
  /// fallbacks to the platform's default close button icon.
  final WidgetBuilder? closeButtonIconBuilder;

  /// Overrides [DrawerButtonIcon]'s icon.
  ///
  /// If [drawerButtonIconBuilder] is null, then [DrawerButtonIcon] 
  /// fallbacks to the platform's default drawer button icon.
  final WidgetBuilder? drawerButtonIconBuilder;

  /// Overrides [EndDrawerButtonIcon]'s icon.
  ///
  /// If [endDrawerButtonIconBuilder] is null, then [EndDrawerButtonIcon] 
  /// fallbacks to the platform's default end drawer button icon.
  final WidgetBuilder? endDrawerButtonIconBuilder;

  /// Linearly interpolate between two action button icons data.
  static ActionButtonIconsData? lerp(
      ActionButtonIconsData? a, ActionButtonIconsData? b, double t) {
    assert(t != null);
    if (a == null && b == null) {
      return null;
    }
    return ActionButtonIconsData(
      backButtonIconBuilder: t < 0.5 ? a?.backButtonIconBuilder : b?.backButtonIconBuilder,
      closeButtonIconBuilder: t < 0.5 ? a?.closeButtonIconBuilder : b?.closeButtonIconBuilder,
      drawerButtonIconBuilder: t < 0.5 ? a?.drawerButtonIconBuilder : b?.drawerButtonIconBuilder,
      endDrawerButtonIconBuilder: t < 0.5 ? a?.endDrawerButtonIconBuilder : b?.endDrawerButtonIconBuilder,
    );
  }

  @override
  int get hashCode {
    final List<Object?> values = <Object?>[
      backButtonIconBuilder,
      closeButtonIconBuilder,
      drawerButtonIconBuilder,
      endDrawerButtonIconBuilder,
    ];
    return Object.hashAll(values);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is ActionButtonIconsData 
        && other.backButtonIconBuilder == backButtonIconBuilder
        && other.closeButtonIconBuilder == closeButtonIconBuilder
        && other.drawerButtonIconBuilder == drawerButtonIconBuilder
        && other.endDrawerButtonIconBuilder == endDrawerButtonIconBuilder;
  }


  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<WidgetBuilder>(
        'backButtonIconBuilder',
        backButtonIconBuilder,
      ),
    );
    properties.add(
      DiagnosticsProperty<WidgetBuilder>(
        'closeButtonIconBuilder',
        closeButtonIconBuilder,
      ),
    );
    properties.add(
      DiagnosticsProperty<WidgetBuilder>(
        'drawerButtonIconBuilder',
        drawerButtonIconBuilder,
      ),
    );
    properties.add(
      DiagnosticsProperty<WidgetBuilder>(
        'endDrawerButtonIconBuilder',
        endDrawerButtonIconBuilder,
      ),
    );
  }
}
