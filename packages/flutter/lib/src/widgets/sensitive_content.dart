// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart' show ContentSensitivity, SensitiveContentService;

import '../../widgets.dart' show ConnectionState;
import 'async.dart' show AsyncSnapshot, FutureBuilder;
import 'container.dart';
import 'framework.dart';

/// Data structure used to track the [SensitiveContent] widgets in the
/// widget tree.
class ContentSensitivitySetting {
  /// Creates a [ContentSensitivitySetting].
  ContentSensitivitySetting();

  /// The number of [SensitiveContent] widgets that have sensitivity level [ContentSensitivity.sensitive].
  int _sensitiveWidgetCount = 0;

  /// The number of [SensitiveContent] widgets that have sensitivity level [ContentSensitivity.autoSensitive].
  int _autoSensitiveWidgetCount = 0;

  /// The number of [SensitiveContent] widgets that have sensitivity level [ContentSensitivity.notSensitive].
  int _notSensitiveWigetCount = 0;

  /// Increases the count of [SensitiveContent] widgets with [sensitivityLevel] set.
  void addWidgetWithContentSensitivity(ContentSensitivity sensitivityLevel) {
    switch (sensitivityLevel) {
      case ContentSensitivity.sensitive:
        _sensitiveWidgetCount++;
      case ContentSensitivity.autoSensitive:
        _autoSensitiveWidgetCount++;
      case ContentSensitivity.notSensitive:
        _notSensitiveWigetCount++;
    }
  }

  /// Decreases the count of [SensitiveContent] widgets with [sensitivityLevel] set.
  void removeWidgetWithContentSensitivity(ContentSensitivity sensitivityLevel) {
    switch (sensitivityLevel) {
      case ContentSensitivity.sensitive:
        _sensitiveWidgetCount--;
      case ContentSensitivity.autoSensitive:
        _autoSensitiveWidgetCount--;
      case ContentSensitivity.notSensitive:
        _notSensitiveWigetCount--;
    }
  }

  /// Returns true if this class is currently tracking at least one [SensitiveContent] widget.
  bool get hasWidgets =>
      _sensitiveWidgetCount + _autoSensitiveWidgetCount + _notSensitiveWigetCount > 0;

  /// Returns the highest prioritized [ContentSensitivity] level of the [SensitiveContent] widgets
  /// that this setting tracks.
  ContentSensitivity? get contentSensitivityBasedOnWidgetCounts {
    if (_sensitiveWidgetCount > 0) {
      return ContentSensitivity.sensitive;
    }
    if (_autoSensitiveWidgetCount > 0) {
      return ContentSensitivity.autoSensitive;
    }
    if (_notSensitiveWigetCount > 0) {
      return ContentSensitivity.notSensitive;
    }
    return null;
  }
}

/// Host of the current content sensitivity level for the widget tree that contains
/// some number [SensitiveContent] widgets.
class SensitiveContentHost {
  SensitiveContentHost._();

  bool? _contentSenstivityIsSupported;
  late final ContentSensitivitySetting _contentSensitivitySetting = ContentSensitivitySetting();
  ContentSensitivity? _defaultContentSensitivitySetting;

  final SensitiveContentService _sensitiveContentService = SensitiveContentService();

  /// The current [ContentSensitivity] level set for the entire widget tree.
  @visibleForTesting
  ContentSensitivity? currentContentSensitivityLevel;

  /// [SensitiveContentHost] instance for the widget tree.
  @visibleForTesting
  static final SensitiveContentHost instance = SensitiveContentHost._();

  /// The state of content sensitivity in the widget tree.
  ///
  /// Contains the number of widgets with each [ContentSensitivity] level and
  /// the current [ContentSensitivity] setting.
  @visibleForTesting
  ContentSensitivitySetting? getContentSenstivityState() {
    return _contentSensitivitySetting;
  }

  /// Registers a [SensitiveContent] widget that will help determine the
  /// [ContentSensitivity] level for the widget tree.
  static Future<void> register(ContentSensitivity desiredSensitivityLevel) {
    return instance._register(desiredSensitivityLevel);
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

    // Update SensitiveContent widget count for those with desiredSensitivityLevel.
    _contentSensitivitySetting.addWidgetWithContentSensitivity(desiredSensitivityLevel);

    // Verify that desiredSensitivityLevel should be set in order for sensitive
    // content to remain obscured.
    if (currentContentSensitivityLevel ==
        _contentSensitivitySetting.contentSensitivityBasedOnWidgetCounts) {
      return;
    }

    // Set content sensitivity level as desiredSensitivityLevel. If the call to set content
    // sensitivity on the platform side fails, then we do not update the current content
    // sensitivity level.
    _sensitiveContentService.setContentSensitivity(desiredSensitivityLevel);

    // Update current content sensitivity level.
    currentContentSensitivityLevel = desiredSensitivityLevel;
  }

  /// Unregisters a [SensitiveContent] widget from the [ContentSensitivitySetting] tracking
  /// the content sensitivity level of the widget tree.
  static void unregister(ContentSensitivity widgetSensitivityLevel) {
    instance._unregister(widgetSensitivityLevel);
  }

  void _unregister(ContentSensitivity widgetSensitivityLevel) {
    assert(
      _contentSenstivityIsSupported != null,
      'SensitiveContentHost.register must be called before SensitiveContentHost.unregister',
    );
    if (!_contentSenstivityIsSupported!) {
      // Setting content sensitivity is not supported on this device.
      return;
    }

    // Update SensitiveContent widget count for those with
    // desiredSensitivityLevel.
    _contentSensitivitySetting.removeWidgetWithContentSensitivity(widgetSensitivityLevel);

    if (!_contentSensitivitySetting.hasWidgets) {
      // Restore default content sensitivity setting if there are no more SensitiveContent
      // widgets in the tree. If the call to set content sensitivity on the platform side fails,
      // then we do not update the current content sensitivity level.
      _sensitiveContentService.setContentSensitivity(_defaultContentSensitivitySetting!);

      // Update current content sensitivity level.
      currentContentSensitivityLevel = _defaultContentSensitivitySetting;
      return;
    }

    // Determine if another sensitivity level needs to be restored.
    late final ContentSensitivity? contentSensitivityToRestore =
        _contentSensitivitySetting.contentSensitivityBasedOnWidgetCounts;
    if (contentSensitivityToRestore != null &&
        contentSensitivityToRestore != currentContentSensitivityLevel) {
      // Set content sensitivity level as contentSensitivityToRestore. If the call to set content
      // sensitivity on the platform side fails, then we do not update the current content
      // sensitivity level.
      _sensitiveContentService.setContentSensitivity(contentSensitivityToRestore);

      // Update current content sensitivity level.
      currentContentSensitivityLevel = contentSensitivityToRestore;
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
  void didUpdateWidget(SensitiveContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.sensitivityLevel == oldWidget.sensitivityLevel) {
      return;
    }

    // Re-register SensitiveContent widget if the sensitivity level changes.
    _sensitiveContentRegistrationFuture = SensitiveContentHost.register(widget.sensitivityLevel);
    SensitiveContentHost.unregister(oldWidget.sensitivityLevel);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _sensitiveContentRegistrationFuture,
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return widget.child;
        }
        return Container();
      },
    );
  }
}
