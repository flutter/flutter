// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of html_common;

/**
 * Utils for device detection.
 */
class Device {
  /**
   * Gets the browser's user agent. Using this function allows tests to inject
   * the user agent.
 * Returns the user agent.
   */
  static String get userAgent => window.navigator.userAgent;

  /**
   * Determines if the current device is running Opera.
   */
  static final bool isOpera = userAgent.contains("Opera", 0);

  /**
   * Determines if the current device is running Internet Explorer.
   */
  static final bool isIE = !isOpera && userAgent.contains("Trident/", 0);

  /**
   * Determines if the current device is running Firefox.
   */
  static final bool isFirefox = userAgent.contains("Firefox", 0);

  /**
   * Determines if the current device is running WebKit.
   */
  static final bool isWebKit = !isOpera && userAgent.contains("WebKit", 0);

  /**
   * Gets the CSS property prefix for the current platform.
   */
  static final String cssPrefix = '-${propertyPrefix}-';

  /**
   * Prefix as used for JS property names.
   */
  static final String propertyPrefix =
      isFirefox ? 'moz' : (isIE ? 'ms' : (isOpera ? 'o' : 'webkit'));

  /**
   * Checks to see if the event class is supported by the current platform.
   */
  static bool isEventTypeSupported(String eventType) {
    // Browsers throw for unsupported event names.
    try {
      var e = new Event.eventType(eventType, '');
      return e is Event;
    } catch (_) {}
    return false;
  }
}
