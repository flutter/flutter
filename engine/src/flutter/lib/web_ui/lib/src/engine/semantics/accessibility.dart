// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import '../../engine.dart' show registerHotRestartListener;
import '../dom.dart';
import '../services.dart';
import '../util.dart';

/// Determines the assertiveness level of the accessibility announcement.
///
/// It is used to set the priority with which assistive technology should treat announcements.
///
/// The order of this enum must match the order of the values in semantics_event.dart in framework.
enum Assertiveness {
  polite,
  assertive,
}

/// Singleton for accessing accessibility announcements from the platform.
final AccessibilityAnnouncements accessibilityAnnouncements =
    AccessibilityAnnouncements.instance;

/// Attaches accessibility announcements coming from the 'flutter/accessibility'
/// channel as temporary elements to the DOM.
class AccessibilityAnnouncements {
  AccessibilityAnnouncements._() {
    registerHotRestartListener(() {
      _removeElementTimer?.cancel();
    });
  }

  /// Initializes the [AccessibilityAnnouncements] singleton if it is not
  /// already initialized.
  static AccessibilityAnnouncements get instance {
    return _instance ??= AccessibilityAnnouncements._();
  }

  static AccessibilityAnnouncements? _instance;

  /// Timer that times when the accessibility element should be removed from the
  /// DOM.
  ///
  /// The element is added to the DOM temporarily for announcing the
  /// message to the assistive technology.
  Timer? _removeElementTimer;

  /// The duration the accessibility announcements stay on the DOM.
  ///
  /// It is removed after this time expired.
  Duration durationA11yMessageIsOnDom = const Duration(seconds: 5);

  /// Element which is used to communicate the message from the
  /// 'flutter/accessibility' to the assistive technologies.
  ///
  /// This element gets attached to the DOM temporarily. It gets removed
  /// after a duration. See [durationA11yMessageIsOnDom].
  ///
  /// This element has aria-live attribute.
  ///
  /// It also has id 'accessibility-element' for testing purposes.
  DomHTMLElement? _element;

  DomHTMLElement get _domElement => _element ??= _createElement();

  /// Decodes the message coming from the 'flutter/accessibility' channel.
  void handleMessage(StandardMessageCodec codec, ByteData? data) {
    final Map<dynamic, dynamic> inputMap =
        codec.decodeMessage(data) as Map<dynamic, dynamic>;
    final Map<dynamic, dynamic> dataMap = inputMap.readDynamicJson('data');
    final String? message = dataMap.tryString('message');
    if (message != null && message.isNotEmpty) {
      /// The default value for politeness is `polite`.
      final int ariaLivePolitenessIndex = dataMap.tryInt('assertiveness') ?? 0;
      final Assertiveness ariaLivePoliteness = Assertiveness.values[ariaLivePolitenessIndex];
      _initLiveRegion(message, ariaLivePoliteness);
      _removeElementTimer = Timer(durationA11yMessageIsOnDom, () {
        _element!.remove();
      });
    }
  }

  void _initLiveRegion(String message, Assertiveness ariaLivePoliteness) {
    final String assertiveLevel = (ariaLivePoliteness == Assertiveness.assertive) ? 'assertive' : 'polite';
    _domElement.setAttribute('aria-live', assertiveLevel);
    _domElement.text = message;
    domDocument.body!.append(_domElement);
  }

  DomHTMLLabelElement _createElement() {
    final DomHTMLLabelElement liveRegion = createDomHTMLLabelElement();
    liveRegion.setAttribute('id', 'accessibility-element');
    liveRegion.style
      ..position = 'fixed'
      ..overflow = 'hidden'
      ..transform = 'translate(-99999px, -99999px)'
      ..width = '1px'
      ..height = '1px';
    return liveRegion;
  }
}
