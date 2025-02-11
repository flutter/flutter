// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart' show ContentSensitivity, SensitiveContentService;
import 'package:flutter/widgets.dart' show AsyncSnapshot, FutureBuilder;

import 'framework.dart';

/// Data structure used to track the [SensitiveContent] widgets in the
/// widget tree.
class ContentSensitivityState {
  /// Creates a [ContentSensitivityState].
  ContentSensitivityState(this.currentContentSensitivitySetting);

  /// The current [ContentSensitivity] level set for the entire widget tree.
  ContentSensitivity currentContentSensitivitySetting;

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
class SensitiveContentSetting {
  SensitiveContentSetting._();

  ContentSensitivityState? _contentSensitivityState;
  final SensitiveContentService _sensitiveContentService = SensitiveContentService();
  ContentSensitivity? _defaultContentSensitivitySetting;

  static final SensitiveContentSetting _instance = SensitiveContentSetting._();

  /// Registers a [SensitiveContent] widget that will help determine the
  /// [ContentSensitivity] level for the widget tree.
  static Future<void> register(ContentSensitivity desiredSensitivityLevel) async {
    await _instance._register(desiredSensitivityLevel);
  }

  Future<void> _register(ContentSensitivity desiredSensitivityLevel) async {
    // Set default content sensitivity level as set in native Android. This will be
    // auto sensitive if it is otherwise unset by the developer.
    _defaultContentSensitivitySetting ??= ContentSensitivity.getContentSensitivityById(
        await _sensitiveContentService.getContentSensitivity());
    _contentSensitivityState ??= ContentSensitivityState(_defaultContentSensitivitySetting!);

    // Update SensitiveContent widget count for those with desiredSensitivityLevel.
    _contentSensitivityState!.addWidgetWithContentSensitivity(desiredSensitivityLevel);

    // Verify that desiredSensitivityLevel should be set in order for sensitive
    // content to remain obscured.
    if (!shouldSetContentSensitivity(_contentSensitivityState!, desiredSensitivityLevel)) {
      return;
    }

    // Set content sensitivity level as desiredSensitivityLevel and update stored data.
    _sensitiveContentService.setContentSensitivity(desiredSensitivityLevel);
    _contentSensitivityState!.currentContentSensitivitySetting = desiredSensitivityLevel;
  }

  /// Unregisters a [SensitiveContent] widget from the [ContentSensitivityState] tracking
  /// the content sensitivity level of the widget tree.
  static void unregister(ContentSensitivity widgetSensitivityLevel) {
    _instance._unregister(widgetSensitivityLevel);
  }

  void _unregister(ContentSensitivity widgetSensitivityLevel) {
    // Update SensitiveContent widget count for those with
    // desiredSensitivityLevel.
    _contentSensitivityState!.removeWidgetWithContentSensitivity(widgetSensitivityLevel);

    // Determine if another sensitivity level needs to be restored.
    ContentSensitivity? contentSensitivityToRestore;
    if (_contentSensitivityState!.getTotalNumberOfWidgets() == 0) {
      contentSensitivityToRestore = _defaultContentSensitivitySetting!;
    } else if (widgetSensitivityLevel == ContentSensitivity.notSensitive) {
      return;
    } else {
      if (shouldSetContentSensitivity(_contentSensitivityState!, ContentSensitivity.notSensitive)) {
        contentSensitivityToRestore = ContentSensitivity.notSensitive;
      } else if (should) // TODO(camsim99): here
    }

    switch(widgetSensitivityLevel) {
      case ContentSensitivity.sensitive:
        if (shouldSetContentSensitivity(_contentSensitivityState!, ContentSensitivity.notSensitive)) {

        }
      case ContentSensitivity.

    }

    if (no more widgets) {
      set default
    } else {
      sensitive -->if no more left, check auto if theres auto, otherwise set not
      auto --> if no more left and sensitive not current mode, set not
      not --> we do not care
    }

// rewrite:
else {
      sensitive --> if (should set not) set not, if (should set auto) set auto otherwise we are done
      auto --> if (should set not) set not
      not --> we are done
    }




    if (widgetSensitivityLevel == ContentSensitivity.sensitive) {
      if (_contentSensitivityState!.sensitiveWidgetCount == 0) {
        if (should set auto sensitive) {
          // what does should set mean? it means: no other sensitive widgets in the tree. but if there are no widgets, we should not set unless it's default
          set auto sensitive
        } else {
          set not sensitive // technically we do need to check sensitive too because it may be default
        }
      }
    } else if (wsl = autoSensitive) {
      if (current setting == sensitive) {
        return;
      } else if (current setting == auto sensitive) {
        if (auto sentive count == 0) {
          if (should set not sensitive) {
            set not sensitive
          }
        }
      }
    } else {
      if (current setting == senstive) {
        return;
      } else if (current setting == auto sensitive) {
        return;
      } else if (current setting == not sensitive) {
        if (not sensitive count == 0) {
          set default setting
        }
      }
    }




    ContentSensitivity sensitivityLevelToSet = _defaultContentSensitivitySetting!;
    if (shouldSetContentSensitivity(_contentSensitivityState!, ContentSensitivity.sensitive)) {
      sensitivityLevelToSet = ContentSensitivity.sensitive;
    } else if (shouldSetContentSensitivity(_contentSensitivityState!, ContentSensitivity.autoSensitive)) {
        sensitivityLevelToSet = ContentSensitivity.autoSensitive;
    } else if (shouldSetContentSensitivity(_contentSensitivityState!, ContentSensitivity.notSensitive)) {
        sensitivityLevelToSet = ContentSensitivity.notSensitive;
    }

    _sensitiveContentService.setContentSensitivity(sensitivityLevelToSet);
  }

  /// Return whether or not [desiredSensitivityLevel] should be set as the new
  /// [ContentSensitivity] level for the widget tree.
  ///
  /// [desiredSensitivityLevel] should only be set if it is strictly more
  /// severe than any of the other [SensitiveContent] widgets in the widget tree.
  bool shouldSetContentSensitivity(ContentSensitivityState contentSensitivityState,
      ContentSensitivity desiredSensitivityLevel) {
    if (contentSensitivityState.currentContentSensitivitySetting ==
        desiredSensitivityLevel) {
      return false;
    }

    switch (desiredSensitivityLevel) {
      case ContentSensitivity.sensitive:
        return true;
      case ContentSensitivity.autoSensitive:
        return contentSensitivityState.sensitiveWidgetCount == 0;
      case ContentSensitivity.notSensitive:
        return contentSensitivityState.sensitiveWidgetCount +
                contentSensitivityState.autoSensitiveWidgetCount ==
            0;
    }
  }
}

/// Widget to set the [ContentSensitivity] level of content in the widget
/// tree.
///
/// See also:
///
///  * [ContentSensitivity] to understand each of the content sensitivity levels
///     and how [SensitiveContent] widgets with each level may interact with each other,
///     e.g. two `SensitiveContent` widgets in the same tree where one has [sensitivityLevel]
///     [ContentSensitivity.notSensitive] and the other [ContentSensitivity.sensitive] will cause
///     the widget tree to remain marked sensitive in accordance with [ContentSensitivity.sensitive]
///     as this is the more severe setting.
class SensitiveContent extends StatefulWidget {
  /// Creates a [SensitiveContent].
  const SensitiveContent({
    super.key,
    required this.sensitivityLevel,
    required this.child,
  });

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
        SensitiveContentSetting.register(widget.sensitivityLevel);
  }

  @override
  void dispose() {
    SensitiveContentSetting.unregister(widget.sensitivityLevel);
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
