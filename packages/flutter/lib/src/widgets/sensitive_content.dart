// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' show max;

import 'package:flutter/services.dart' show ContentSensitivity, SensitiveContentService;

import '../foundation/assertions.dart' show FlutterErrorDetails;
import 'async.dart' show AsyncSnapshot, ConnectionState, FutureBuilder;
import 'basic.dart' show SizedBox;
import 'framework.dart';

/// Data structure used to track the [SensitiveContent] widgets in the
/// widget tree.
class _ContentSensitivitySetting {
  /// Creates a [_ContentSensitivitySetting].
  _ContentSensitivitySetting();

  /// The number of [SensitiveContent] widgets that have sensitivity [ContentSensitivity.sensitive].
  int _sensitiveWidgetCount = 0;

  /// The number of [SensitiveContent] widgets that have sensitivity [ContentSensitivity.autoSensitive].
  int _autoSensitiveWidgetCount = 0;

  /// The number of [SensitiveContent] widgets that have sensitivity [ContentSensitivity.notSensitive].
  int _notSensitiveWigetCount = 0;

  /// Increases the count of [SensitiveContent] widgets with [sensitivity] set.
  void addWidgetWithContentSensitivity(ContentSensitivity sensitivity) {
    switch (sensitivity) {
      case ContentSensitivity.sensitive:
        _sensitiveWidgetCount++;
      case ContentSensitivity.autoSensitive:
        _autoSensitiveWidgetCount++;
      case ContentSensitivity.notSensitive:
        _notSensitiveWigetCount++;
      // ignore is safe because it protects this setting from tracking SensitiveContent
      // widgets with an _unknown ContentSensitivity. _unknown is private to avoid
      // developers using it as a SensitiveContent sensitivity.
      // ignore: no_default_cases
      default:
        throw FlutterError(
          'Adding a SensitiveContent widget with ContentSensitivity $sensitivity is unsupported by _ContentSensitivitySetting',
        );
    }
  }

  String _getNegativeWidgetCountErrorMessage(ContentSensitivity sensitivity, int count) {
    return 'A negative amount ($count) of $sensitivity SensitiveContent widgets have been detected, which is not expected. Please file an issue.';
  }

  /// Decreases the count of [SensitiveContent] widgets with [sensitivity] set.
  void removeWidgetWithContentSensitivity(ContentSensitivity sensitivity) {
    switch (sensitivity) {
      case ContentSensitivity.sensitive:
        _sensitiveWidgetCount--;
        assert(
          _sensitiveWidgetCount >= 0,
          _getNegativeWidgetCountErrorMessage(sensitivity, _sensitiveWidgetCount),
        );
      case ContentSensitivity.autoSensitive:
        _autoSensitiveWidgetCount--;
        assert(
          _autoSensitiveWidgetCount >= 0,
          _getNegativeWidgetCountErrorMessage(sensitivity, _autoSensitiveWidgetCount),
        );
      case ContentSensitivity.notSensitive:
        _notSensitiveWigetCount--;
        assert(
          _notSensitiveWigetCount >= 0,
          _getNegativeWidgetCountErrorMessage(sensitivity, _notSensitiveWigetCount),
        );
      // ignore is safe because it protects this setting from tracking SensitiveContent
      // widgets with an _unknown ContentSensitivity. _unknown is private to avoid
      // developers using it as a SensitiveContent sensitivity.
      // ignore: no_default_cases
      default:
        throw FlutterError(
          'Removing a SensitiveContent widget with ContentSensitivity $sensitivity is unsupported by _ContentSensitivitySetting',
        );
    }
  }

  /// Returns true if this class is currently tracking at least one [SensitiveContent] widget.
  bool get hasWidgets =>
      max(0, _sensitiveWidgetCount) +
          max(0, _autoSensitiveWidgetCount) +
          max(0, _notSensitiveWigetCount) >
      0;

  /// Returns the highest prioritized [ContentSensitivity] of the [SensitiveContent] widgets
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

/// Host of the current content sensitivity for the widget tree that contains
/// some number [SensitiveContent] widgets.
@visibleForTesting
class SensitiveContentHost {
  SensitiveContentHost._();

  bool? _contentSenstivityIsSupported;
  late final _ContentSensitivitySetting _contentSensitivitySetting = _ContentSensitivitySetting();
  ContentSensitivity? _fallbackContentSensitivitySetting;

  final SensitiveContentService _sensitiveContentService = SensitiveContentService();

  /// [SensitiveContentHost] instance for the widget tree.
  @visibleForTesting
  static final SensitiveContentHost instance = SensitiveContentHost._();

  /// Returns the current content sensitivity as tracked by [_contentSensitivitySetting].
  @visibleForTesting
  ContentSensitivity? get calculatedContentSensitivity =>
      _contentSensitivitySetting.contentSensitivityBasedOnWidgetCounts;

  /// Registers a [SensitiveContent] widget that will help determine the
  /// [ContentSensitivity] for the widget tree.
  static Future<void> register(ContentSensitivity desiredSensitivity) {
    return instance._register(desiredSensitivity);
  }

  Future<void> _register(ContentSensitivity desiredSensitivity) async {
    _contentSenstivityIsSupported ??= await _sensitiveContentService.isSupported();
    if (!_contentSenstivityIsSupported!) {
      // Setting content sensitivity is not supported on this device.
      return;
    }
    // When the first `SensitiveContent` widget is registered, determine the content sensitivity
    // we should fallback to if/when no `SensitiveContent` widgets remain in the tree.
    // For Android API 35, this will be auto sensitive if it is otherwise unset by the developer.
    if (_fallbackContentSensitivitySetting == null) {
      try {
        _fallbackContentSensitivitySetting = await _sensitiveContentService.getContentSensitivity();
      } on UnsupportedError catch (e) {
        // Unknown ContentSensitivity detected; fallback to not sensitive mode since we
        // cannot determine the desired behavior of the current mode and log error to user.
        _fallbackContentSensitivitySetting = ContentSensitivity.notSensitive;
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: FlutterError(
              'Unknown content sensitivity set in the Android embedding or by default: $e}',
            ),
            library: 'widget library',
            stack: StackTrace.current,
          ),
        );
      }
    }

    final ContentSensitivity? contentSensitivityBasedOnWidgetCountsBeforeRegister =
        _contentSensitivitySetting.contentSensitivityBasedOnWidgetCounts ??
        _fallbackContentSensitivitySetting;

    // Update SensitiveContent widget count for those with desiredSensitivity.
    _contentSensitivitySetting.addWidgetWithContentSensitivity(desiredSensitivity);

    // Verify that desiredSensitivity should be set in order for sensitive
    // content to remain obscured.
    if (contentSensitivityBasedOnWidgetCountsBeforeRegister ==
        _contentSensitivitySetting.contentSensitivityBasedOnWidgetCounts) {
      return;
    }

    // Set content sensitivity as desiredSensitivity. If the call to set content
    // sensitivity on the platform side fails, then we do not update the current content
    // sensitivity.
    try {
      await _sensitiveContentService.setContentSensitivity(
        _contentSensitivitySetting.contentSensitivityBasedOnWidgetCounts!,
      );
    } catch (e) {
      // If setting content sensitivity fails, log error to user.
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: FlutterError('Attempted to set $desiredSensitivity sensitivity failed: $e}'),
          library: 'widget library',
          stack: StackTrace.current,
        ),
      );
      return;
    }
  }

  /// Unregisters a [SensitiveContent] widget from the [_ContentSensitivitySetting] tracking
  /// the content sensitivity of the widget tree.
  static Future<void> unregister(ContentSensitivity widgetSensitivity) async {
    return instance._unregister(widgetSensitivity);
  }

  Future<void> _unregister(ContentSensitivity widgetSensitivity) async {
    assert(
      _contentSenstivityIsSupported != null,
      'SensitiveContentHost.register must be called before SensitiveContentHost.unregister',
    );

    if (!_contentSenstivityIsSupported!) {
      // Setting content sensitivity is not supported on this device.
      return;
    }

    final ContentSensitivity contentSensitivityBasedOnWidgetCountsBeforeUnregister =
        _contentSensitivitySetting.contentSensitivityBasedOnWidgetCounts!;

    // Update SensitiveContent widget count for those with desiredSensitivity.
    _contentSensitivitySetting.removeWidgetWithContentSensitivity(widgetSensitivity);

    if (!_contentSensitivitySetting.hasWidgets) {
      // Restore default content sensitivity setting if there are no more SensitiveContent
      // widgets in the tree. If the call to set content sensitivity on the platform side fails,
      // then we do not update the current content sensitivity. The null check is safe
      // because _fallbackContentSensitivitySetting cannot be null if `register` has been
      // called at least once, and it must be called before `unregister` is called.
      if (contentSensitivityBasedOnWidgetCountsBeforeUnregister ==
          _fallbackContentSensitivitySetting) {
        return;
      }

      try {
        await _sensitiveContentService.setContentSensitivity(_fallbackContentSensitivitySetting!);
      } catch (e) {
        // If setting content sensitivity fails, log error to user.
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: FlutterError(
              'Attempted to set $_fallbackContentSensitivitySetting sensitivity failed: $e}',
            ),
            library: 'widget library',
            stack: StackTrace.current,
          ),
        );
        return;
      }
      return;
    }

    // Determine if another sensitivity needs to be restored. The null check should be
    // safe because contentSensitivityBasedOnWidgetCounts should always be non-null as long
    // as there are still SensitiveContent widgets in the tree.
    final ContentSensitivity contentSensitivityToRestore =
        _contentSensitivitySetting.contentSensitivityBasedOnWidgetCounts!;
    if (contentSensitivityToRestore != contentSensitivityBasedOnWidgetCountsBeforeUnregister) {
      // Set content sensitivity as contentSensitivityToRestore.
      try {
        await _sensitiveContentService.setContentSensitivity(contentSensitivityToRestore);
      } catch (e) {
        // If setting content sensitivity fails, log error to user.
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: FlutterError(
              'Attempted to set $_fallbackContentSensitivitySetting sensitivity failed: $e}',
            ),
            library: 'widget library',
            stack: StackTrace.current,
          ),
        );
        return;
      }
    }
  }
}

/// Widget to set the [ContentSensitivity] of content in the widget
/// tree.
///
/// The [sensitivity] of the widget in conjunction with the other
/// [SensitiveContent] widgets in the tree will determine whether or not the
/// screen will be obscured during media projection, e.g. screen sharing.
///
/// {@macro flutter.services.ContentSensitivity}
///
/// Currently, this widget is only supported on Android API 35+. On all lower Android
/// versions and non-Android platforms, this does nothing; the screen will never be
/// obscured regardless of the [sensitivity] set. To programmatically check if
/// a device supports this widget, call [SensitiveContentService.isSupported].
///
/// See also:
///
///  * [ContentSensitivity], which are the different content sensitivity that a
///    [SensitiveContent] widget can set.
///
/// This widget is marked visible for testing because it is not ready for use. It
/// will be ready for use when it is implemented such that we can guarantee that no
/// frames will be dropped when content is marked sensitive, ensuring that no sensitive
/// content will be revealed during media projection.
// TODO(camsim99): Fix `SensitiveContent` implementation to prevent revealing sensitive
// content during media projection. Then, export this file to make the widget available
// for use. See https://github.com/flutter/flutter/issues/160050 and
// https://github.com/flutter/flutter/issues/164820.
@visibleForTesting
class SensitiveContent extends StatefulWidget {
  /// Creates a [SensitiveContent] widget.
  const SensitiveContent({super.key, required this.sensitivity, required this.child});

  /// The sensitivity that the [SensitiveContent] widget should sets for the
  /// Android native `View` hosting the widget tree.
  final ContentSensitivity sensitivity;

  /// The child widget of this [SensitiveContent].
  ///
  /// If the [sensitivity] is set to [ContentSensitivity.sensitive], then
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
    _sensitiveContentRegistrationFuture = SensitiveContentHost.register(widget.sensitivity);
  }

  @override
  void dispose() {
    SensitiveContentHost.unregister(widget.sensitivity);
    super.dispose();
  }

  Future<void> _reregisterWidget({
    required ContentSensitivity newContentSensitivity,
    required ContentSensitivity oldContentSensitivity,
  }) async {
    await SensitiveContentHost.register(newContentSensitivity);
    await SensitiveContentHost.unregister(oldContentSensitivity);
  }

  @override
  void didUpdateWidget(SensitiveContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.sensitivity == oldWidget.sensitivity) {
      return;
    }

    // Re-register SensitiveContent widget if the sensitivity changes.
    _sensitiveContentRegistrationFuture = _reregisterWidget(
      newContentSensitivity: widget.sensitivity,
      oldContentSensitivity: oldWidget.sensitivity,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _sensitiveContentRegistrationFuture,
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return widget.child;
        }
        return const SizedBox.shrink();
      },
    );
  }
}
