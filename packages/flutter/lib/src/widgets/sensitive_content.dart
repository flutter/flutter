// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart' show ContentSensitivity, SensitiveContentService;

import 'framework.dart';

/// Data structure used to track the number of widgets with each
/// [ContentSensitivity] level set in a particular Flutter Android
/// `View`.
class ViewContentSensitivityState {
  /// Creates a [ViewContentSensitivityState].
  ViewContentSensitivityState();

  /// The current [ContentSensitivity] level set for this `View`.
  ContentSensitivity currentContentSensitivitySetting = ContentSensitivity.autoSensitive;

  /// Map containing the number of widgets that have set each of the different [ContentSensitivity]
  /// levels.
  final Map<ContentSensitivity, int> contentSensitivityCounts = <ContentSensitivity, int> {
    ContentSensitivity.sensitive: 0,
    ContentSensitivity.autoSensitive: 0,
    ContentSensitivity.notSensitive: 0,
  };

  /// Increases the count of widgets with [sensitivityLevel] set.
  void addWidgetWithContentSensitivity(ContentSensitivity sensitivityLevel) {
    contentSensitivityCounts[sensitivityLevel] = contentSensitivityCounts[sensitivityLevel]! + 1;
  }

  /// Decreases the count of widgets with [sensitivityLevel] set.
  void removeWidgetWithContentSensitivity(ContentSensitivity sensitivityLevel) { 
    contentSensitivityCounts[sensitivityLevel] = contentSensitivityCounts[sensitivityLevel]! - 1;
  }

  /// Returns the number of widgets tracked by this state.
  int getTotalNumberOfWidgets() {
    return contentSensitivityCounts.values.reduce((int sum, int value) => sum + value);
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
    if (!_contentSensitivityStates.containsKey(viewId)) {
      _contentSensitivityStates[viewId] = ViewContentSensitivityState();
    }

    // Update widget count for those with desiredSensitivityLevel.
    final ViewContentSensitivityState contentSensitivityStateForView = _contentSensitivityStates[viewId]!;
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
    _sensitiveContentService.setContentSensitivity(viewId, desiredSensitivityLevel);
    contentSensitivityStateForView.currentContentSensitivitySetting = desiredSensitivityLevel;
  }

  /// Unregisters [SensitiveContent] widget who calls it from the overarching
  /// [ContentSensitivity] setting.
  static void unregister(int viewId, ContentSensitivity widgetSensitivityLevel) {
     _instance._unregister(viewId, widgetSensitivityLevel);
  }

  void _unregister(int viewId, ContentSensitivity widgetSensitivityLevel) {
    // Update widget count for those with desiredSensitivityLevel.
    final ViewContentSensitivityState contentSensitivityStateForView = _contentSensitivityStates[viewId]!;
    contentSensitivityStateForView.removeWidgetWithContentSensitivity(widgetSensitivityLevel);

    if (contentSensitivityStateForView.getTotalNumberOfWidgets() == 0) {
      // There is no more content to mark sensitive. Reset to the default mode (autoSensitive).
      _sensitiveContentService.setContentSensitivity(viewId, ContentSensitivity.autoSensitive);
      return;
    }

    final ContentSensitivity currentSensitivityLevelForView = contentSensitivityStateForView.currentContentSensitivitySetting;
    final Map<ContentSensitivity, int> contentSensitivityCountsForView = contentSensitivityStateForView.contentSensitivityCounts;
    final int numWidgetsWithWidgetSensitivityLevel = contentSensitivityCountsForView[widgetSensitivityLevel]!;

    if (widgetSensitivityLevel != currentSensitivityLevelForView
      || numWidgetsWithWidgetSensitivityLevel > 0) {
      // Either another SensitiveContent widget has set a more severe ContentSensitivity
      // level for the View or there are other widgets that have requested the same level
      // in the View.
      return;
    }

    ContentSensitivity? sensitivityLevelToSet;
    switch (widgetSensitivityLevel) {
      case ContentSensitivity.sensitive:
        if (contentSensitivityCountsForView[ContentSensitivity.autoSensitive]! > 0) {
          sensitivityLevelToSet = ContentSensitivity.autoSensitive;
          break;
        }
        continue auto;
      auto:
      case ContentSensitivity.autoSensitive:
        if (contentSensitivityCountsForView[ContentSensitivity.notSensitive]! > 0) {
          sensitivityLevelToSet = ContentSensitivity.notSensitive;
          break;
        }
        continue not;
      not:
      case ContentSensitivity.notSensitive:
        throw StateError('The SensitiveContentSetting has gotten out of sync with the SensitiveContent widgets in the tree.');
    }

    _sensitiveContentService.setContentSensitivity(viewId, sensitivityLevelToSet);
  }

  /// Return whether or not ...
  ///
  /// A desired [ContentSensitivity] level should be set only if it is less
  /// severe than any of the other registered [SensitiveContent] widgets.
  // TODO(camsim99): File issue on not caring if a widget is visible or not.
  bool shouldSetContentSensitivity({required ContentSensitivity currentSensitivityLevel, required ContentSensitivity desiredSensitivityLevel}) {
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
