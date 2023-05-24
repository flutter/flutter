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
AccessibilityAnnouncements get accessibilityAnnouncements {
  assert(
    _accessibilityAnnouncements != null,
    'AccessibilityAnnouncements not initialized. Call initializeAccessibilityAnnouncements() to initialize it.',
  );
  return _accessibilityAnnouncements!;
}
AccessibilityAnnouncements? _accessibilityAnnouncements;

void debugOverrideAccessibilityAnnouncements(AccessibilityAnnouncements override) {
  _accessibilityAnnouncements = override;
}

/// Initializes the [accessibilityAnnouncements] singleton.
///
/// It is an error to attempt to initialize the singleton more than once. Call
/// [AccessibilityAnnouncements.dispose] prior to calling this function again.
void initializeAccessibilityAnnouncements() {
  assert(
    _accessibilityAnnouncements == null,
    'AccessibilityAnnouncements is already initialized. This is likely a bug in '
    'Flutter Web engine initialization. Please file an issue at '
    'https://github.com/flutter/flutter/issues/new/choose',
  );
  _accessibilityAnnouncements = AccessibilityAnnouncements();
  registerHotRestartListener(() {
    accessibilityAnnouncements.dispose();
  });
}

/// Duration for which a live message will be present in the DOM for the screen
/// reader to announce it.
///
/// This was determined by trial and error with some extra buffer added.
Duration liveMessageDuration = const Duration(milliseconds: 300);

/// Sets [liveMessageDuration] to reduce the delay in tests.
void setLiveMessageDurationForTest(Duration duration) {
  liveMessageDuration = duration;
}

/// Makes accessibility announcements using `aria-live` DOM elements.
class AccessibilityAnnouncements {
  /// Creates a new instance with its own DOM elements used for announcements.
  factory AccessibilityAnnouncements() {
    final DomHTMLElement politeElement = _createElement(Assertiveness.polite);
    final DomHTMLElement assertiveElement = _createElement(Assertiveness.assertive);
    domDocument.body!.append(politeElement);
    domDocument.body!.append(assertiveElement);
    return AccessibilityAnnouncements._(politeElement, assertiveElement);
  }

  AccessibilityAnnouncements._(this._politeElement, this._assertiveElement);

  /// A live region element with `aria-live` set to "polite", used to announce
  /// accouncements politely.
  final DomHTMLElement _politeElement;

  /// A live region element with `aria-live` set to "assertive", used to announce
  /// accouncements assertively.
  final DomHTMLElement _assertiveElement;

  /// Looks up the element used to announce messages of the given [assertiveness].
  DomHTMLElement ariaLiveElementFor(Assertiveness assertiveness) {
    assert(!_isDisposed);
    switch (assertiveness) {
      case Assertiveness.polite: return _politeElement;
      case Assertiveness.assertive: return _assertiveElement;
    }
  }

  bool _isDisposed = false;

  /// Disposes of the resources used by this object.
  ///
  /// This object's methods must not be called after calling this method.
  void dispose() {
    assert(!_isDisposed);
    _isDisposed = true;
    _politeElement.remove();
    _assertiveElement.remove();
    _accessibilityAnnouncements = null;
  }

  /// Makes an accessibity announcement from a message sent by the framework
  /// over the 'flutter/accessibility' channel.
  ///
  /// The encoded message is passed as [data], and will be decoded using [codec].
  void handleMessage(StandardMessageCodec codec, ByteData? data) {
    assert(!_isDisposed);
    final Map<dynamic, dynamic> inputMap = codec.decodeMessage(data) as Map<dynamic, dynamic>;
    final Map<dynamic, dynamic> dataMap = inputMap.readDynamicJson('data');
    final String? message = dataMap.tryString('message');
    if (message != null && message.isNotEmpty) {
      /// The default value for assertiveness is `polite`.
      final int assertivenessIndex = dataMap.tryInt('assertiveness') ?? 0;
      final Assertiveness assertiveness = Assertiveness.values[assertivenessIndex];
      announce(message, assertiveness);
    }
  }

  /// Makes an accessibility announcement using an `aria-live` element.
  ///
  /// [message] is the text of the announcement.
  ///
  /// [assertiveness] controls how interruptive the announcement is.
  void announce(String message, Assertiveness assertiveness) {
    assert(!_isDisposed);
    final DomHTMLElement ariaLiveElement = ariaLiveElementFor(assertiveness);

    final DomElement messageElement = createDomElement('div');
    messageElement.text = message;
    ariaLiveElement.append(messageElement);
    Timer(liveMessageDuration, () => messageElement.remove());
  }

  static DomHTMLLabelElement _createElement(Assertiveness assertiveness) {
    final String ariaLiveValue = (assertiveness == Assertiveness.assertive) ? 'assertive' : 'polite';
    final DomHTMLLabelElement liveRegion = createDomHTMLLabelElement();
    liveRegion.setAttribute('id', 'ftl-announcement-$ariaLiveValue');
    liveRegion.style
      ..position = 'fixed'
      ..overflow = 'hidden'
      ..transform = 'translate(-99999px, -99999px)'
      ..width = '1px'
      ..height = '1px';
    liveRegion.setAttribute('aria-live', ariaLiveValue);
    return liveRegion;
  }
}
