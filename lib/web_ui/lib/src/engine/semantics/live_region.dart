// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../embedder.dart' show flutterViewEmbedder;
import 'accessibility.dart';
import 'semantics.dart';

/// Manages semantics configurations that represent live regions.
///
/// Assistive technologies treat "aria-live" attribute differently. To keep
/// the behavior consistent, [accessibilityAnnouncements.announce] is used.
///
/// When there is an update to [LiveRegion], assistive technologies read the
/// label of the element. See [LabelAndValue]. If there is no label provided
/// no content will be read.
class LiveRegion extends RoleManager {
  LiveRegion(SemanticsObject semanticsObject)
      : super(Role.liveRegion, semanticsObject);

  String? _lastAnnouncement;

  @override
  void update() {
    if (!semanticsObject.isLiveRegion) {
      return;
    }

    // Avoid announcing the same message over and over.
    if (_lastAnnouncement != semanticsObject.label) {
      _lastAnnouncement = semanticsObject.label;
      if (semanticsObject.hasLabel) {
        flutterViewEmbedder.accessibilityAnnouncements.announce(
          _lastAnnouncement! , Assertiveness.polite
        );
      }
    }
  }
}
