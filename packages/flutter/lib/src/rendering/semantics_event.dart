// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

/// An event that can be send by the application to notify interested listeners
/// that something happened to the user interface (e.g. a view scrolled).
///
/// These events are usually interpreted by assistive technologies to give the
/// user additional clues about the current state of the UI.
abstract class SemanticsEvent {

  SemanticsEvent(this._type);

  /// The type of this event.
  final String _type;

  /// Converts this event to a JSON-encodable Map.
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> result = getParameters() ?? <String, dynamic>{};
    assert(!result.containsKey('type'));
    result['type'] = _type;
    return result;
  }

  /// Returns a map of parameters for this event that will be send to the
  /// engine.
  ///
  /// The returned map must not include the key 'type'.
  @protected
  Map<String, dynamic> getParameters();
}

/// Notifies that a scroll action has been completed.
class ScrollSemanticsEvent extends SemanticsEvent {

  ScrollSemanticsEvent() : super('scroll');

  @override
  Map<String, dynamic> getParameters() => <String, dynamic>{};
}
