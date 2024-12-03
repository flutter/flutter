// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart' show ContentSensitivity, SensitiveContentService;

import 'framework.dart';

/// Data structure used to track the number of widgets with each
/// [ContentSensitivity] level set in a particular Flutter Android
/// `View`.
class ViewContentSensitivityState {
  ViewContentSensitivityState({});

  /// The current [ContentSensitivity] level set for this `View`.
  ContentSensitivity currentContentSensitivitySetting = ContentSensitivity.autoSensitive;

  /// The number of widgets in this `View` with the content sensitivity setting
  /// [ContentSensitivity.sensitive].
  int numSensitiveWidgets = 0;

  /// The number of widgets in this `View` with the content sensitivity setting
  /// [ContentSensitivity.autoSensitive].
  int numAutoSensitiveWidgets = 0;

  /// The number of widgets in this `View` with the content sensitivity setting
  /// [ContentSensitivity.notSensitive].
  int numNotSensitiveWidgets = 0;

  /// Increases the count of widgets with [sensitivityLevel] set.
  void addWidgetWithContentSensitivity(ContentSensitivity sensitivityLevel) {
    switch (sensitivityLevel) {
      case ContentSensitivity.sensitive:
        numSensitiveWidgets +=1;
      case ContentSensitivity.autoSensitive:
        numAutoSensitiveWidgets += 1;
      case ContentSensitivity.notSensitive:
       numNotSensitiveWidgets += 1;
    }
  }

  /// Decreases the count of widgets with [sensitivityLevel] set.
  void removeWidgetWithContentSensitivity(ContentSensitivity sensitivityLevel) { 
    switch (sensitivityLevel) {
      case ContentSensitivity.sensitive:
        numSensitiveWidgets -=1;
      case ContentSensitivity.autoSensitive:
        numAutoSensitiveWidgets -= 1;
      case ContentSensitivity.notSensitive:
       numNotSensitiveWidgets -= 1;
    }
  }

  /// Returns the number of widgets tracked by this state.
  int getTotalNumberOfWidgets() {
    return numSensitiveWidgets + numAutoSensitiveWidgets + numNotSensitiveWidgets;
  }
}

/// Host of the current content sensitivity level.
class SensitiveContentSetting {
  SensitiveContentSetting._();

  final Map<int, ViewContentSensitivityState> _contentSensitivityStates = <int, ViewContentSensitivityState> {};
  final SensitiveContentService _sensitiveContentService = SensitiveContentService();

  static final SensitiveContentSetting _instance = SensitiveContentSetting._();

  /// Registers [SensitiveContent] widget who calls it to the overarching
  /// [ContentSensitivity] setting.
  static void register(int viewId, ContentSensitivity desiredSensitivityLevel) {
     _instance._register(viewId, desiredSensitivityLevel);
  }

  void _register(int viewId, ContentSensitivity desiredSensitivityLevel) {
    if (!_contentSensitivityCounts.containsKey(viewId)) {
      _contentSensitivityStates[viewId] = ViewContentSensitivityState();
    }

    // Update widget count for those with desiredSensitivityLevel.
    ViewContentSensitivityState contentSensitivityStateForView = _contentSensitivityStates[viewId];
    contentSensitivityStateForView.addWidgetWithContentSensitivity(desiredSensitivityLevel);


    // If only one widget in the View sets a ContentSensitivity level, then we can immediately set
    // desiredSensitivityLevel for the View.
    if (contentSensitivityStateForView.getTotalNumberOfWidgets() == 1) {
      // Set content sensitivity level for View as desiredSensitivityLevel and update stored data.
      _sensitiveContentService.setContentSensitivity(viewId, desiredSensitivityLevel);
      contentSensitivityStateForView.currentContentSensitivitySetting = desiredSensitivityLevel;
      return;
    }

    // Verify that desiredSensitivityLevel should be set for the View.
    if (!shouldSetContentSensitivity(currentSensitivityLevel: contentSensitivityStateForView.currentContentSensitivitySetting, desiredSensitivityLevel: desiredSensitivityLevel)) {
      return;
    }

    // Set content sensitivity level for View as desiredSensitivityLevel and update stored data.
    // CAMILLE MIGRATION MARKER <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
    _sensitiveContentService.setContentSensitivity(/*default Flutter view ID */ 0, desiredSensitivityLevel);
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
      // There is no more content to mark sensitive. Reset to the default mode.
      // TODO(camsim99): Make this compatible with multi-window.
      _sensitiveContentService.setContentSensitivity(/*default Flutter view ID */ 0, ContentSensitivity.autoSensitive);
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
          break;
        }
        continue auto;
      auto:
      case ContentSensitivity.autoSensitive:
        if (_contentSensitivityCounts[ContentSensitivity.notSensitive]! > 0) {
          sensitivityLevelToSet = ContentSensitivity.notSensitive;
          break;
        }
        continue not;
      not:
      case ContentSensitivity.notSensitive:
        throw StateError('The SensitiveContentSetting has gone out of sync with the SensitiveContent widgets in the tree.');
    }

    // TODO(camsim99): Make this compatible with multi-window.
    _sensitiveContentService.setContentSensitivity(/*default Flutter view ID */ 0, sensitivityLevelToSet);
  }

  /// Return whether or not ...
  ///
  /// A desired [ContentSensitivity] level should be set only if it is less
  /// severe than any of the other registered [SensitiveContent] widgets.
  // TODO(camsim99): File issue on not caring if a widget is visible or not.
  bool shouldSetContentSensitivity({ContentSensitivity currentSensitivityLevel, desiredSensitivityLevel}) {
    if (currentSensitivityLevel == desiredSensitivityLevel) {
      return false;
    }

    switch(desiredSensitivityLevel) {
      case ContentSensitivity.sensitive:
        return true;
      case ContentSensitivity.autoSensitive:
        return currentSensitivityLevel != ContentSensitivity.sensitive;
      case ContentSensitivity.notSensitive:
        return currentSensitivityLevel == ContentSensitivity.notSensitive;
    }
  }
}

/// Widget to set content sensitivity level.
class SensitiveContent extends StatefulWidget {
  /// Builds a [SensitiveContent].
  const SensitiveContent({
    super.key,
    this.viewId = 0,
    required this.sensitivityLevel,
    required this.child,
  });

  /// The ID of the native Android `View` that [sensitivityLevel] should be set for.
  /// 
  /// By default, this is 0, the ID of the `View` that is created by a `FlutterActivity`,
  /// which is used by default in Flutter Android apps.
  final int viewId;

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
    SensitiveContentSetting.register(widget.viewId, widget.sensitivityLevel);
  }

  @override
  void dispose() {
    SensitiveContentSetting.unregister(widget.viewId, widget.sensitivityLevel);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
