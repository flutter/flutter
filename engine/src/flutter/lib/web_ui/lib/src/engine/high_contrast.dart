// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:js_interop';

import 'package:ui/ui.dart' as ui;

import 'dom.dart';

/// Signature of functions added as a listener to high contrast changes
typedef HighContrastListener = void Function(bool enabled);

/// Determines if high contrast is enabled using media query 'forced-colors: active' for Windows
class HighContrastSupport {
  static HighContrastSupport instance = HighContrastSupport();
  static const String _highContrastMediaQueryString = '(forced-colors: active)';

  final List<HighContrastListener> _listeners = <HighContrastListener>[];

  /// Reference to css media query that indicates whether high contrast is on.
  final DomMediaQueryList _highContrastMediaQuery = domWindow.matchMedia(
    _highContrastMediaQueryString,
  );
  late final DomEventListener _onHighContrastChangeListener = _onHighContrastChange.toJS;

  bool get isHighContrastEnabled => _highContrastMediaQuery.matches;

  /// Adds function to the list of listeners on high contrast changes
  void addListener(HighContrastListener listener) {
    if (_listeners.isEmpty) {
      _highContrastMediaQuery.addListener(_onHighContrastChangeListener);
    }
    _listeners.add(listener);
  }

  /// Removes function from the list of listeners on high contrast changes
  void removeListener(HighContrastListener listener) {
    _listeners.remove(listener);
    if (_listeners.isEmpty) {
      _highContrastMediaQuery.removeListener(_onHighContrastChangeListener);
    }
  }

  void _onHighContrastChange(DomEvent event) {
    final mqEvent = event as DomMediaQueryListEvent;
    final bool isHighContrastEnabled = mqEvent.matches!;
    for (final HighContrastListener listener in _listeners) {
      listener(isHighContrastEnabled);
    }
  }
}

const List<String> systemColorNames = <String>[
  'AccentColor',
  'AccentColorText',
  'ActiveText',
  'ButtonBorder',
  'ButtonFace',
  'ButtonText',
  'Canvas',
  'CanvasText',
  'Field',
  'FieldText',
  'GrayText',
  'Highlight',
  'HighlightText',
  'LinkText',
  'Mark',
  'MarkText',
  'SelectedItem',
  'SelectedItemText',
  'VisitedText',
];

class SystemColorPaletteDetector {
  SystemColorPaletteDetector(this.brightness) : systemColors = _detectSystemColors(brightness);

  static SystemColorPaletteDetector light = SystemColorPaletteDetector(ui.Brightness.light);
  static SystemColorPaletteDetector dark = SystemColorPaletteDetector(ui.Brightness.dark);

  final ui.Brightness brightness;

  final Map<String, ui.SystemColor> systemColors;
}

Map<String, ui.SystemColor> _detectSystemColors(ui.Brightness brightness) {
  final DomHTMLDivElement hostDetector = createDomHTMLDivElement();
  hostDetector.style
    ..position = 'absolute'
    ..transform = 'translate(-10000, -10000)'
    // Force the browser to use light mode colors or dark mode colors.
    ..setProperty('color-scheme', brightness == ui.Brightness.light ? 'light' : 'dark');
  domDocument.body!.appendChild(hostDetector);

  final colorDetectors = <String, DomHTMLElement>{};

  for (final String systemColorName in systemColorNames) {
    final DomHTMLDivElement detector = createDomHTMLDivElement();
    detector.style.backgroundColor = systemColorName;
    detector.innerText = '$systemColorName detector';
    hostDetector.appendChild(detector);
    colorDetectors[systemColorName] = detector;
  }

  final results = <String, ui.SystemColor>{};

  colorDetectors.forEach((systemColorName, detector) {
    final DomCSSStyleDeclaration computedDetector = domWindow.getComputedStyle(detector);
    final String computedColor = computedDetector.backgroundColor;

    final bool isSupported = domCSS.supports('color', systemColorName);
    ui.Color? value;
    if (isSupported) {
      value = parseCssRgb(computedColor);
    }

    results[systemColorName] = ui.SystemColor(name: systemColorName, value: value);
  });

  // Once colors have been detected, this element is no longer needed.
  hostDetector.remove();

  return results;
}

/// Parses CSS RGB color written as `rgb(r, g, b)` or `rgba(r, g, b, a)`.
ui.Color? parseCssRgb(String rgbString) {
  // Remove leading and trailing whitespace.
  rgbString = rgbString.trim();

  final bool isRgb = rgbString.startsWith('rgb(');
  final bool isRgba = rgbString.startsWith('rgba(');

  if ((!isRgb && !isRgba) || !rgbString.endsWith(')')) {
    assert(() {
      print('Bad CSS color "$rgbString": not an rgb or rgba color.');
      return true;
    }());
    return null;
  }

  assert(isRgb || isRgba);

  // Extract the comma-separated values.
  final String valuesString = rgbString.substring(isRgb ? 4 : 5, rgbString.length - 1);
  final List<String> values = valuesString.split(',');

  // Check if there are exactly three values for RGB, and four values for RGBA.
  if ((isRgb && values.length != 3) || (isRgba && values.length != 4)) {
    assert(() {
      print(
        'Bad CSS color "$rgbString": wrong number of color componets. For ${isRgb ? 'rgb' : 'rgba'} color, expected ${isRgb ? 3 : 4} components, but found ${values.length}.',
      );
      return true;
    }());
    return null;
  }

  // Parse the values as integers.
  final int? r = int.tryParse(values[0].trim());
  final int? g = int.tryParse(values[1].trim());
  final int? b = int.tryParse(values[2].trim());

  // Check if the values are valid integers between 0 and 255.
  if (r == null ||
      g == null ||
      b == null ||
      r < 0 ||
      r > 255 ||
      g < 0 ||
      g > 255 ||
      b < 0 ||
      b > 255) {
    assert(() {
      print(
        'Bad CSS color "$rgbString": one of RGB components failed to parse or outside the 0-255 range: r = $r, g = $g, b = $b.',
      );
      return true;
    }());
    return null;
  }

  if (isRgb) {
    return ui.Color.fromRGBO(r, g, b, 1.0);
  } else {
    assert(isRgba);
    final double? a = double.tryParse(values[3].trim());
    if (a == null || a < 0.0 || a > 1.0) {
      assert(() {
        print('Bad CSS color "$rgbString": alpha component outside the 0.0-1.0 range: $a');
        return true;
      }());
      return null;
    } else {
      return ui.Color.fromRGBO(r, g, b, a);
    }
  }
}
