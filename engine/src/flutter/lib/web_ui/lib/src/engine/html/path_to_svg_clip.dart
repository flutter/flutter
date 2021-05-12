// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

/// Counter used for generating clip path id inside an svg <defs> tag.
int _clipIdCounter = 0;

/// Used for clipping and filter svg resources.
///
/// Position needs to be absolute since these svgs are sandwiched between
/// canvas elements and can cause layout shifts otherwise.
const String kSvgResourceHeader = '<svg width="0" height="0" '
    'style="position:absolute">';

/// Converts Path to svg element that contains a clip-path definition.
///
/// Calling this method updates [_clipIdCounter]. The HTML id of the generated
/// clip is set to "svgClip${_clipIdCounter}", e.g. "svgClip123".
String pathToSvgClipPath(ui.Path path,
    {double offsetX = 0,
    double offsetY = 0,
    double scaleX = 1.0,
    double scaleY = 1.0}) {
  _clipIdCounter += 1;
  final StringBuffer sb = StringBuffer();
  sb.write(kSvgResourceHeader);
  sb.write('<defs>');

  final String clipId = 'svgClip$_clipIdCounter';

  if (browserEngine == BrowserEngine.firefox) {
    // Firefox objectBoundingBox fails to scale to 1x1 units, instead use
    // no clipPathUnits but write the path in target units.
    sb.write('<clipPath id=$clipId>');
    sb.write('<path fill="#FFFFFF" d="');
  } else {
    sb.write('<clipPath id=$clipId clipPathUnits="objectBoundingBox">');
    sb.write('<path transform="scale($scaleX, $scaleY)" fill="#FFFFFF" d="');
  }

  pathToSvg((path as SurfacePath).pathRef, sb, offsetX: offsetX, offsetY: offsetY);
  sb.write('"></path></clipPath></defs></svg');
  return sb.toString();
}

String createSvgClipUrl() => 'url(#svgClip$_clipIdCounter)';

/// Resets clip ids. Used for testing by [debugForgetFrameScene] API.
void resetSvgClipIds() {
  _clipIdCounter = 0;
}
