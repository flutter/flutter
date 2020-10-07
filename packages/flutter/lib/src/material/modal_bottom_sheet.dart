import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'package:flutter/material.dart';

import 'debug.dart';
import 'material.dart';
import 'material_localizations.dart';
import 'theme.dart';

/// Shows a modal material design bottom sheet.
Future<T> showMaterialModalBottomSheet<T>({
  required BuildContext context,
  double? closeProgressThreshold,
  required WidgetBuilder builder,
  Color? backgroundColor,
  double? elevation,
  ShapeBorder? shape,
  Clip? clipBehavior,
  Color? barrierColor,
  bool bounce = false,
  bool expand = false,
  AnimationController? secondAnimation,
  Curve? animationCurve,
  bool useRootNavigator = false,
  bool isDismissible = true,
  bool enableDrag = true,
  Duration? duration,
}) async {
  assert(context != null);
  assert(builder != null);
  assert(expand != null);
  assert(useRootNavigator != null);
  assert(isDismissible != null);
  assert(enableDrag != null);
  assert(debugCheckHasMediaQuery(context));
  assert(debugCheckHasMaterialLocalizations(context));
  return await Navigator.of(context, rootNavigator: useRootNavigator)!.push(
    ModalBottomSheetRoute<T>(
      builder: builder,
      containerBuilder: _materialContainerBuilder(
        context,
        backgroundColor: backgroundColor,
        elevation: elevation,
        shape: shape,
        clipBehavior: clipBehavior,
        theme: Theme.of(context, shadowThemeOnly: true),
      ),
      closeProgressThreshold: closeProgressThreshold,
      secondAnimationController: secondAnimation,
      bounce: bounce,
      expanded: expand,
      barrierLabel: MaterialLocalizations.of(context)!.modalBarrierDismissLabel,
      modalLabel: _getRouteLabel(context),
      isDismissible: isDismissible,
      modalBarrierColor: barrierColor,
      enableDrag: enableDrag,
      animationCurve: animationCurve,
      duration: duration,
    ),
  );
}

String _getRouteLabel(BuildContext context) {
    final platform = Theme.of(context)?.platform ?? defaultTargetPlatform;
    switch (platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return '';
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        if (MaterialLocalizations.of(context) != null) {
          return MaterialLocalizations.of(context)!.dialogLabel;
        } else {
          return const DefaultMaterialLocalizations().dialogLabel;
        }
    }
}

//Default container builder is the Material Appearance
WidgetWithChildBuilder _materialContainerBuilder(
  BuildContext context, {
  Color? backgroundColor,
  double? elevation,
  ThemeData? theme,
  Clip? clipBehavior,
  ShapeBorder? shape,
}) {
  final BottomSheetThemeData? bottomSheetTheme =
      Theme.of(context)?.bottomSheetTheme;
  final Color? color = backgroundColor ??
      bottomSheetTheme?.modalBackgroundColor ??
      bottomSheetTheme?.backgroundColor;
  final double _elevation = elevation ?? bottomSheetTheme?.elevation ?? 0.0;
  final ShapeBorder? _shape = shape ?? bottomSheetTheme?.shape;
  final Clip _clipBehavior =
      clipBehavior ?? bottomSheetTheme?.clipBehavior ?? Clip.none;

  final WidgetWithChildBuilder builder =
      (BuildContext context, Animation<double> animation, Widget child) =>
          Material(
              color: color,
              elevation: _elevation,
              shape: _shape,
              clipBehavior: _clipBehavior,
              child: child);
  if (theme != null) {
    return (BuildContext context, Animation<double> animation, Widget child) =>
        Theme(
          data: theme,
          child: Builder(
            builder: (BuildContext context) => builder(
              context,
              animation,
              child,
            ),
          ),
        );
  } else {
    return builder;
  }
}
