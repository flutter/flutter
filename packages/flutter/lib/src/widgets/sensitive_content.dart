// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'framework.dart';

/// Specifies the sensitivity level that a [SensitiveContent] widget could
/// set for the Flutter app screen on Android.
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

  /// 
  /// 
  /// See https://developer.android.com/reference/android/view/View#CONTENT_SENSITIVITY_AUTO.
  // TODO(camsim99): Implement `autoSensitive` mode that will attempt to match
  // the behavior of `CONTENT_SENSITIVITY_AUTO` on Android that has implemented
  // based on autofill hints.
  autoSensitive,
}

/// Host of the current content sensitivity level.
class SensitiveContentSetting {
  SensitiveContentSetting._();

  late ContentSensitivity _currentSensitivityLevel;

  final Map<ContentSensitivity, int> _contentSensitivityCounts = <ContentSensitivity, int> {
    ContentSensitivity.sensitive: 0,
    ContentSensitivity.autoSensitive: 0,
    ContentSensitivity.notSensitive: 0,
  };

  static final SensitiveContentSetting _instance = SensitiveContentSetting._();

  int _getTotalSensitiveContentWidgets() {
    int total = 0;
    for (final ContentSensitivity key in _contentSensitivityCounts.keys) {
      total += _contentSensitivityCounts[key]!;
    }
    return total;
  }


  /// Registers [SensitiveContent] widget who calls it to the overarching
  /// [ContentSensitivity] setting.
  static void register(ContentSensitivity desiredSensitivityLevel) {
     _instance._register(desiredSensitivityLevel);
  }

  void _register(ContentSensitivity desiredSensitivityLevel) {
    _contentSensitivityCounts[desiredSensitivityLevel] = _contentSensitivityCounts[desiredSensitivityLevel]! + 1;

    if (_getTotalSensitiveContentWidgets() == 1) {
      // There are no other attempts to alter ContentSensitivity, so
      // set the desired level.
      SensitiveContentUtils.setContentSensitivity(desiredSensitivityLevel);
      return;
    }
    if (!shouldSetContentSensitivity(desiredSensitivityLevel)) {
      return;
    }

    // Update stored data.
    SensitiveContentUtils.setContentSensitivity(desiredSensitivityLevel);
    _currentSensitivityLevel = desiredSensitivityLevel;
  }

  /// Unregisters [SensitiveContent] widget who calls it from the overarching
  /// [ContentSensitivity] setting.
  static void unregister(ContentSensitivity widgetSensitivityLevel) {
     _instance._unregister(widgetSensitivityLevel);
  }

  void _unregister(ContentSensitivity widgetSensitivityLevel) {
     _contentSensitivityCounts[widgetSensitivityLevel] = _contentSensitivityCounts[widgetSensitivityLevel]! - 1;

    if (_getTotalSensitiveContentWidgets() == 0) {
      // There is no more content to mark sensitive. Reset to the defualt mode.
      // TODO(camsim99): Determine if we should set `autoSensitive`
      // since this is technically the default, though it will not work for Flutter.
      SensitiveContentUtils.setContentSensitivity(ContentSensitivity.autoSensitive);
      return;
    }

    if (widgetSensitivityLevel != _currentSensitivityLevel
      || _contentSensitivityCounts[widgetSensitivityLevel]! > 0) {
      // Either another SensitiveContent widget has set a more severe ContentSensitivity
      // level or there are other widgets that have requested the same level.
      return;
    }

    // TODO(camsim99): Ensure this switch works as expected.
    ContentSensitivity? sensitivityLevelToSet;
    switch (widgetSensitivityLevel) {
      case ContentSensitivity.sensitive:
        if (_contentSensitivityCounts[ContentSensitivity.autoSensitive]! > 0) {
          sensitivityLevelToSet = ContentSensitivity.autoSensitive;
          return;
        }
      case ContentSensitivity.autoSensitive:
        if (_contentSensitivityCounts[ContentSensitivity.notSensitive]! > 0) {
          sensitivityLevelToSet = ContentSensitivity.notSensitive;
          return;
        }
      case ContentSensitivity.notSensitive:
        throw StateError('The SensitiveContentSetting has gone out of sync with the SensitiveContent widgets in the tree.');
    }

    SensitiveContentUtils.setContentSensitivity(sensitivityLevelToSet!);
  }

  /// A desired [ContentSensitivity] level should be set only if it is less
  /// severe than any of the other registered [SensitiveContent] widgets.
  // TODO(camsim99): Gather feedback on not caring if a widget is visible or not.
  bool shouldSetContentSensitivity(ContentSensitivity desiredSensitivityLevel) {
    if (desiredSensitivityLevel == _currentSensitivityLevel) {
      return false;
    }

    switch(desiredSensitivityLevel) {
      case ContentSensitivity.sensitive:
        return true;
      case ContentSensitivity.autoSensitive:
        return _currentSensitivityLevel != ContentSensitivity.sensitive;
      case ContentSensitivity.notSensitive:
        return _currentSensitivityLevel == ContentSensitivity.notSensitive;
    }
  }
}

/// Widget to set content sensitivity level.
// TODO(camsim99): Make compatible with multiview.
class SensitiveContent extends StatefulWidget {
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

  @override
  State<SensitiveContent> createState() => _SensitiveContentState();
}

class _SensitiveContentState extends State<SensitiveContent> {
  @override
  void initState() {
    super.initState();
    SensitiveContentSetting.register(widget.sensitivityLevel);
  }

  @override
  void dispose() {
    SensitiveContentSetting.unregister(widget.sensitivityLevel);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
