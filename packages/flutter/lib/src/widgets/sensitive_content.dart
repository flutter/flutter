// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart' show ContentSensitivity, SensitiveContentService;

import 'async.dart' show AsyncSnapshot, FutureBuilder;
import 'framework.dart';

/// Data structure used to track the [SensitiveContent] widgets in the
/// widget tree.
class ContentSensitivitySetting {
  /// Creates a [ContentSensitivitySetting].
  ContentSensitivitySetting();

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

/// Host of the current content sensitivity level for the widget tree that contains
/// some number [SensitiveContent] widgets.
class SensitiveContentHost {
  SensitiveContentHost._();

  bool? _contentSenstivityIsSupported;
  ContentSensitivitySetting? _contentSensitivitySetting;
  ContentSensitivity? _defaultContentSensitivitySetting;

  final SensitiveContentService _sensitiveContentService = SensitiveContentService();

  /// The current [ContentSensitivity] level set for the entire widget tree.
  @visibleForTesting
  ContentSensitivity? currentContentSensitivityLevel;

  @visibleForTesting
  /// [SensitiveContentHost] instance for the widget tree.
  static final SensitiveContentHost instance = SensitiveContentHost._();

  @visibleForTesting
  /// The state of content sensitivity in the widget tree.
  ///
  /// Contains the number of widgets with each [ContentSensitivity] level and
  /// the current [ContentSensitivity] setting.
  ContentSensitivitySetting? getContentSenstivityState() {
    return _contentSensitivitySetting;
  }

  /// Registers a [SensitiveContent] widget that will help determine the
  /// [ContentSensitivity] level for the widget tree.
  static Future<void> register(ContentSensitivity desiredSensitivityLevel) async {
    await instance._register(desiredSensitivityLevel);
  }

  Future<void> _register(ContentSensitivity desiredSensitivityLevel) async {
    _contentSenstivityIsSupported ??= await _sensitiveContentService.isSupported();
    if (!_contentSenstivityIsSupported!) {
      // Setting content sensitivity is not supported on this device.
      return;
    }

    // If needed, set default content sensitivity level as set in native Android. This will be
    // auto sensitive if it is otherwise unset by the developer. Also, initialize the current
    // content sensitivity level if needed.
    _defaultContentSensitivitySetting ??= await _sensitiveContentService.getContentSensitivity();
    currentContentSensitivityLevel ??= _defaultContentSensitivitySetting;

    // If needed, then set the initial content sensitivity state.
    _contentSensitivitySetting ??= ContentSensitivitySetting();

    // Update SensitiveContent widget count for those with desiredSensitivityLevel.
    _contentSensitivitySetting!.addWidgetWithContentSensitivity(desiredSensitivityLevel);

    // Verify that desiredSensitivityLevel should be set in order for sensitive
    // content to remain obscured.
    if (!shouldSetContentSensitivity(desiredSensitivityLevel)) {
      return;
    }

    // Set content sensitivity level as desiredSensitivityLevel and update stored data.
    _sensitiveContentService.setContentSensitivity(desiredSensitivityLevel);
    currentContentSensitivityLevel = desiredSensitivityLevel;
  }

  /// Unregisters a [SensitiveContent] widget from the [ContentSensitivitySetting] tracking
  /// the content sensitivity level of the widget tree.
  static void unregister(ContentSensitivity widgetSensitivityLevel) {
    instance._unregister(widgetSensitivityLevel);
  }

  void _unregister(ContentSensitivity widgetSensitivityLevel) {
    if (!_contentSenstivityIsSupported!) {
      // Setting content sensitivity is not supported on this device.
      return;
    }

    // Update SensitiveContent widget count for those with
    // desiredSensitivityLevel.
    _contentSensitivitySetting!.removeWidgetWithContentSensitivity(widgetSensitivityLevel);

    if (_contentSensitivitySetting!.getTotalNumberOfWidgets() == 0) {
      // Restore default content sensitivity setting if there are no more SensitiveContent
      // widgets in the tree.
      _sensitiveContentService.setContentSensitivity(_defaultContentSensitivitySetting!);
      currentContentSensitivityLevel = _defaultContentSensitivitySetting!;
      return;
    }

    // Determine if another sensitivity level needs to be restored.
    ContentSensitivity? contentSensitivityToRestore;
    switch (widgetSensitivityLevel) {
      case ContentSensitivity.sensitive:
        if (shouldSetContentSensitivity(ContentSensitivity.notSensitive)) {
          contentSensitivityToRestore = ContentSensitivity.notSensitive;
        } else if (shouldSetContentSensitivity(ContentSensitivity.autoSensitive)) {
          contentSensitivityToRestore = ContentSensitivity.autoSensitive;
        }
      case ContentSensitivity.autoSensitive:
        if (shouldSetContentSensitivity(ContentSensitivity.notSensitive)) {
          contentSensitivityToRestore = ContentSensitivity.notSensitive;
        }
      case ContentSensitivity.notSensitive:
      // Removing a not sensitive SensitiveContent widgets when there are other SensitiveContent widgets
      // in the tree will have no impact on the content sensitivity setting for the widget tree since
      // they have the least severe content sensitivity level.
    }

    if (contentSensitivityToRestore != null) {
      // Set content sensitivity level as contentSensitivityToRestore and update stored data.
      currentContentSensitivityLevel = contentSensitivityToRestore;
      _sensitiveContentService.setContentSensitivity(contentSensitivityToRestore);
    }
  }

  /// Return whether or not [desiredSensitivityLevel] should be set as the new
  /// [ContentSensitivity] level for the widget tree.
  ///
  /// [desiredSensitivityLevel] should only be set if it is strictly more
  /// severe than any of the other [SensitiveContent] widgets in the widget tree.
  bool shouldSetContentSensitivity(ContentSensitivity desiredSensitivityLevel) {
    if (currentContentSensitivityLevel == desiredSensitivityLevel) {
      return false;
    }

    switch (desiredSensitivityLevel) {
      case ContentSensitivity.sensitive:
        return true;
      case ContentSensitivity.autoSensitive:
        return _contentSensitivitySetting!.sensitiveWidgetCount == 0;
      case ContentSensitivity.notSensitive:
        return _contentSensitivitySetting!.sensitiveWidgetCount +
                _contentSensitivitySetting!.autoSensitiveWidgetCount ==
            0;
    }
  }
}

/// Widget to set the [ContentSensitivity] level of content in the widget
/// tree.
///
/// {@macro flutter.services.ContentSensitivity}
///
/// See also:
///
///  * [ContentSensitivity], which are the different content sensitivity levels that a
///    [SensitiveContent] widget can set.
class SensitiveContent extends StatefulWidget {
  /// Creates a [SensitiveContent] widget.
  const SensitiveContent({super.key, required this.sensitivityLevel, required this.child});

  /// The sensitivity level that the [SensitiveContent] widget should sets for the
  /// Android native `View` hosting the widget tree.
  final ContentSensitivity sensitivityLevel;

  /// The child widget of this [SensitiveContent].
  ///
  /// If the [sensitivityLevel] is set to [ContentSensitivity.sensitive], then
  /// the entire screen will be obscured when the screen is projected irrespective
  /// to the parent/child widgets.
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
    _sensitiveContentRegistrationFuture = SensitiveContentHost.register(widget.sensitivityLevel);
  }

  @override
  void dispose() {
    SensitiveContentHost.unregister(widget.sensitivityLevel);
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
