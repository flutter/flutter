// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart' show ContentSensitivity, SensitiveContentService;
import 'package:flutter/widgets.dart' show AsyncSnapshot, FutureBuilder;

import 'framework.dart';

/// Data structure used to track the number of [SensitiveContent] widgets with
/// each of the different [ContentSensitivity] levels set in a particular
/// Flutter view.
class ViewContentSensitivityState {
  /// Creates a [ViewContentSensitivityState].
  ViewContentSensitivityState();

  /// The current [ContentSensitivity] level set for the Flutter view that this
  /// state represents.
  ///
  /// By default, this level is [ContentSensitivity.autoSensitive] because this
  /// is the default level on Android and this feature is currently only
  /// supported for Android.
  ContentSensitivity currentContentSensitivitySetting = ContentSensitivity.autoSensitive;

  /// The number of [SensitiveContent] widgets that have sensitivity level [ContentSensitivity.sensitive].
  int sensitiveWidgetCount = 0;

  /// The number of [SensitiveContent] widgets that have sensitivity level [ContentSensitivity.autoSensitive].
  int autoSensitiveWidgetCount = 0;

  /// The number of [SensitiveContent] widgets that have sensitivity level [ContentSensitivity.notSensitive].
  int notSensitiveWigetCount = 0;

  /// Increases the count of [SensitiveContent] widgets with [sensitivityLevel] set.
  void addWidgetWithContentSensitivity(ContentSensitivity sensitivityLevel) {
    switch (sensitivityLevel) {
      case ContentSensitivity.sensitive:
        sensitiveWidgetCount++;
      case ContentSensitivity.autoSensitive:
        autoSensitiveWidgetCount++;
      case ContentSensitivity.notSensitive:
        notSensitiveWigetCount++;
    }
  }

  /// Decreases the count of [SensitiveContent] widgets with [sensitivityLevel] set.
  void removeWidgetWithContentSensitivity(ContentSensitivity sensitivityLevel) {
    switch (sensitivityLevel) {
      case ContentSensitivity.sensitive:
        sensitiveWidgetCount--;
      case ContentSensitivity.autoSensitive:
        autoSensitiveWidgetCount--;
      case ContentSensitivity.notSensitive:
        notSensitiveWigetCount--;
    }
  }

  /// Returns the number of [SensitiveContent] widgets represented by this state.
  int getTotalNumberOfWidgets() {
    return sensitiveWidgetCount + autoSensitiveWidgetCount + notSensitiveWigetCount;
  }
}

/// Host of the current content sensitivity level for each Flutter view that
/// contains any [SensitiveContent] widgets.
class SensitiveContentSetting {
  SensitiveContentSetting._();

  final Map<int, ViewContentSensitivityState> _contentSensitivityStates =
      <int, ViewContentSensitivityState>{};
  final SensitiveContentService _sensitiveContentService = SensitiveContentService();
  ContentSensitivity? _defaultContentSensitivitySetting;

  static final SensitiveContentSetting _instance = SensitiveContentSetting._();

  /// Registers a [SensitiveContent] widget that will help determine the
  /// [ContentSensitivity] level for the Flutter view with ID [viewId].
  static Future<void> register(int viewId, ContentSensitivity desiredSensitivityLevel) async {
    await _instance._register(viewId, desiredSensitivityLevel);
  }

  Future<void> _register(int viewId, ContentSensitivity desiredSensitivityLevel) async {
    // Set default content sensitivity level as set in native Android or the default
    // if unset by the developer (auto sensitive).
    _defaultContentSensitivitySetting ??= ContentSensitivity.getContentSensitivityById(
        await _sensitiveContentService.getContentSensitivity(viewId));
    if (!_contentSensitivityStates.containsKey(viewId)) {
      _contentSensitivityStates[viewId] = ViewContentSensitivityState();
    }

    // Update SensitiveContent widget count for those with desiredSensitivityLevel.
    final ViewContentSensitivityState contentSensitivityStateForView =
        _contentSensitivityStates[viewId]!;
    contentSensitivityStateForView.addWidgetWithContentSensitivity(desiredSensitivityLevel);

    // Verify that desiredSensitivityLevel should be set in order for sensitive
    // content in the view to remain obscured.
    if (!shouldSetContentSensitivity(contentSensitivityStateForView, desiredSensitivityLevel)) {
      return;
    }

    // Set content sensitivity level for the view as desiredSensitivityLevel and update stored data.
    _sensitiveContentService.setContentSensitivity(viewId, desiredSensitivityLevel);
    contentSensitivityStateForView.currentContentSensitivitySetting = desiredSensitivityLevel;
  }

  /// Unregisters a [SensitiveContent] widget from the Flutter view with ID
  /// [viewId].
  static void unregister(int viewId, ContentSensitivity widgetSensitivityLevel) {
    _instance._unregister(viewId, widgetSensitivityLevel);
  }

  void _unregister(int viewId, ContentSensitivity widgetSensitivityLevel) {
    // Update SensitiveContent widget count for those with
    // desiredSensitivityLevel.
    final ViewContentSensitivityState contentSensitivityStateForView =
        _contentSensitivityStates[viewId]!;
    contentSensitivityStateForView.removeWidgetWithContentSensitivity(widgetSensitivityLevel);

    // Determine if another sensitivity level needs to be restored.
    ContentSensitivity sensitivityLevelToSet =
        _defaultContentSensitivitySetting!; // TODO(camsim99): check if this is necessary.
    switch (widgetSensitivityLevel) {
      case ContentSensitivity.sensitive:
        if (shouldSetContentSensitivity(
            contentSensitivityStateForView, ContentSensitivity.sensitive)) {
          sensitivityLevelToSet = ContentSensitivity.sensitive;
        }
        continue auto;
      auto:
      case ContentSensitivity.autoSensitive:
        if (shouldSetContentSensitivity(
            contentSensitivityStateForView, ContentSensitivity.autoSensitive)) {
          sensitivityLevelToSet = ContentSensitivity.autoSensitive;
        }
        continue not;
      not:
      case ContentSensitivity.notSensitive:
        if (shouldSetContentSensitivity(
            contentSensitivityStateForView, ContentSensitivity.notSensitive)) {
          sensitivityLevelToSet = ContentSensitivity.autoSensitive;
        }
    }

    _sensitiveContentService.setContentSensitivity(viewId, sensitivityLevelToSet);
  }

  /// Return whether or not [desiredSensitivityLevel] should be set as the new
  /// [ContentSensitivity] level for a Flutter view.
  ///
  /// [desiredSensitivityLevel] should be set only if it is striclty less
  /// severe than any of the other registered [SensitiveContent] widgets in the view.
  bool shouldSetContentSensitivity(ViewContentSensitivityState contentSensitivityStateForView,
      ContentSensitivity desiredSensitivityLevel) {
    if (contentSensitivityStateForView.currentContentSensitivitySetting ==
        desiredSensitivityLevel) {
      return false;
    }

    switch (desiredSensitivityLevel) {
      case ContentSensitivity.sensitive:
        return true;
      case ContentSensitivity.autoSensitive:
        return contentSensitivityStateForView.sensitiveWidgetCount == 0;
      case ContentSensitivity.notSensitive:
        return contentSensitivityStateForView.sensitiveWidgetCount +
                contentSensitivityStateForView.autoSensitiveWidgetCount ==
            0;
    }
  }
}

/// Widget to set the [ContentSensitivity] level of content in a particular
/// Flutter view.
///
/// See also:
///
///  * [ContentSensitivity] to understand each of the content sensitivity levels
///     and how [SensitiveContent] widgets with each level may interact with each other,
///     e.g. two `SensitiveContent` widgets in the same tree where one has [sensitivityLevel]
///     [ContentSensitivity.notSensitive] and the other [ContentSensitivity.sensitive] will cause
///     the Flutter view to remain marked sensitive in accordance with [ContentSensitivity.sensitive]
///     as this is the more severe setting.
class SensitiveContent extends StatefulWidget {
  /// Creates a [SensitiveContent].
  const SensitiveContent({
    super.key,
    this.viewId = 0,
    required this.sensitivityLevel,
    required this.child,
  });

  /// The ID of the Flutter view that [sensitivityLevel] should be set for.
  ///
  /// By default, this is 0. On Android, this is the the ID of the native
  /// `View` that is created by the default `FlutterActivity`, which is used by
  /// default in Flutter Android apps.
  final int viewId;

  /// The sensitivity level that the [SensitiveContent] widget should set.
  final ContentSensitivity sensitivityLevel;

  /// The child widget of this [SensitiveContent].
  ///
  /// If the [sensitivityLevel] is set to [ContentSensitivity.sensitive], then
  /// the entire screen will be obscured when the screen is projected regardless
  /// of the parent/child widgets.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  @override
  State<SensitiveContent> createState() => _SensitiveContentState();
}

class _SensitiveContentState extends State<SensitiveContent> {
  Future<void>? _sensitiveContentRegistrationFuture;
  @override
  void initState() {
    super.initState();
    _sensitiveContentRegistrationFuture =
        SensitiveContentSetting.register(widget.viewId, widget.sensitivityLevel);
  }

  @override
  void dispose() {
    SensitiveContentSetting.unregister(widget.viewId, widget.sensitivityLevel);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _sensitiveContentRegistrationFuture,
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) => widget.child,
    );
  }
}
