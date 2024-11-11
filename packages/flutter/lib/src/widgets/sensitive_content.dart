// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'framework.dart';

/// Specifies the sensitivity level that a [SensitiveContent] widget could
/// set for the Flutter app screen on Android.
// TODO(camsim99): Implement `autoSensitive` mode that will attempt to match
// the behavior of `CONTENT_SENSITIVITY_AUTO` on Android that has implemented
// based on autofill hints.
// TODO(camsim99): File issue for implementing `autoSensitive` mode.
enum ContentSensitivity {
  /// The screen does not display sensitive content.
  /// 
  /// See https://developer.android.com/reference/android/view/View#CONTENT_SENSITIVITY_NOT_SENSITIVE.
  notSensitive,
  
  /// The screen displays sensitive content and the window hosting the screen
  /// will be marked as secure during an active media projection session.
  /// 
  /// See https://developer.android.com/reference/android/view/View#CONTENT_SENSITIVITY_NOT_SENSITIVE.
  sensitive,
}

/// Host of the current content sensitivity level.
class SensitiveContentSetting extends InheritedWidget {
  /// Creates a [SensitiveContentSetting].
  const SensitiveContentSetting({
    super.key,
    required this.sensitivityLevel,
    required super.child,
});

  /// The content sensitivity setting for the relevant Flutter view.
  final ContentSensitivity sensitivityLevel;

  /// Return content sensitivity setting of this [SensitiveContentSetting].
  static ContentSensitivity of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SensitiveContentSetting>()!.sensitivityLevel;
  }

  @override
  bool updateShouldNotify(SensitiveContentSetting oldWidget) {
    return sensitivityLevel == oldWidget.sensitivityLevel;
  }
}

/// A widget that sets the sensitivity of the Flutter app screen.
/// 
/// Currently this is a no-op on non-Android platforms.
// NOTE(camsim99): This has to be inserted in the widget tree somewhere high up
// for this to work as expected.
class SensitiveContentZone extends StatefulWidget {
  /// Creates a widget that sets the sensitivity of the Flutter app
  /// screen.
  ///
  /// This widget does nothing on non-Android platforms.
  const SensitiveContentZone({
    super.key,
    required this.child,
  });

  /// The child widget of this [SensitiveContentZone].
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  /// Finds ancestor [SensitiveContentZoneState] widget.
  static SensitiveContentZoneState of(BuildContext context) {
    return context.findAncestorStateOfType<SensitiveContentZoneState>()!;
  }

  @override
  State<SensitiveContentZone> createState() => SensitiveContentZoneState();
}

/// State of [SensitiveContentZone] widget.
class SensitiveContentZoneState extends State<SensitiveContentZone> {
  // TODO(camsim99): Figure out what to do here since *technically*
  // autoSensitive is the default mode on Android.
  ContentSensitivity _sensitivityLevel = ContentSensitivity.notSensitive;

  /// Makes call to native side to set content sensitivity.
  void setSensitivityLevel(ContentSensitivity newSensitivityLevel) {
    if (_sensitivityLevel != newSensitivityLevel) {
      setState( () {
        // Update state.
        _sensitivityLevel = newSensitivityLevel;

        // Make native call to update content sensitivity:
        final ContentSensitivity currentNativeSensitivityLevel = SensitiveContentUtils.getCurrentSensitivityLevel();
        if (currentNativeSensitivityLevel == newSensitivityLevel) {
          return;
        }

        SensitiveContentUtils.setSensitivityLevel(newSensitivityLevel);
      });
    }
  }

  @override
  Widget build(BuildContext context) => SensitiveContentSetting(sensitivityLevel: _sensitivityLevel, child: widget.child);
}

/// Widget to set content sensitivity level.
// TODO(camsim99): Make compatible with multiview.
class SensitiveContent extends StatelessWidget {
  /// Builds a [SensitiveContent].
  const SensitiveContent({
    super.key,
    required this.sensitivityLevel,
    required this.child,
  });

  /// The sensitivity level of that the [SensitiveContent] widget should set.
  final ContentSensitivity sensitivityLevel;

  /// The child of this [SensitiveContent].
  ///
  /// If the [sensitivtyLevel] is set to [ContentSensitivity.sensitive], then
  /// the entire screen will be obscured when the screen is project regardless
  /// of the parent/child widgets.
  /// 
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  void _setContentSensitvity(BuildContext context) {
    final ContentSensitivity currentContentSensitivityLevel = SensitiveContentSetting.of(context);
    if (currentContentSensitivityLevel == ContentSensitivity.sensitive) {
      // At least one other widget requires that content still be obscured.
      return;
    }

    SensitiveContentZone.of(context).setSensitivityLevel(sensitivityLevel);
  }

  @override
  Widget build(BuildContext context) {
    // Make call to native to mark appropriate content sensitivity.
    _setContentSensitvity(context);

    return child;
  }
}
