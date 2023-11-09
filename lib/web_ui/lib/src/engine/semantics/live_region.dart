// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../platform_dispatcher.dart';
import 'accessibility.dart';
import 'label_and_value.dart';
import 'semantics.dart';

/// Manages semantics configurations that represent live regions.
///
/// Assistive technologies treat "aria-live" attribute differently. To keep
/// the behavior consistent, [AccessibilityAnnouncements.announce] is used.
///
/// When there is an update to [LiveRegion], assistive technologies read the
/// label of the element. See [LabelAndValue]. If there is no label provided
/// no content will be read.
class LiveRegion extends RoleManager {
  LiveRegion(SemanticsObject semanticsObject, PrimaryRoleManager owner)
      : super(Role.liveRegion, semanticsObject, owner);

  String? _lastAnnouncement;

  static AccessibilityAnnouncements? _accessibilityAnnouncementsOverride;

  @visibleForTesting
  static void debugOverrideAccessibilityAnnouncements(AccessibilityAnnouncements? value) {
    _accessibilityAnnouncementsOverride = value;
  }

  AccessibilityAnnouncements get _accessibilityAnnouncements =>
      _accessibilityAnnouncementsOverride ??
      EnginePlatformDispatcher.instance.implicitView!.accessibilityAnnouncements;

  @override
  void update() {
    if (!semanticsObject.isLiveRegion) {
      return;
    }

    // Avoid announcing the same message over and over.
    if (_lastAnnouncement != semanticsObject.label) {
      _lastAnnouncement = semanticsObject.label;
      if (semanticsObject.hasLabel) {
        _accessibilityAnnouncements.announce(
          _lastAnnouncement!,
          Assertiveness.polite,
        );
      }
    }
  }
}
