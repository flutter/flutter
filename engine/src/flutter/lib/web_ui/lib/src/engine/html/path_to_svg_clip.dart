// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:svg' as svg;

import 'package:ui/ui.dart' as ui;

import '../browser_detection.dart';
import 'path/path.dart';
import 'path/path_to_svg.dart';

/// Counter used for generating clip path id inside an svg <defs> tag.
int _clipIdCounter = 0;

/// Used for clipping and filter svg resources.
///
/// Position needs to be absolute since these svgs are sandwiched between
/// canvas elements and can cause layout shifts otherwise.
final svg.SvgSvgElement kSvgResourceHeader = svg.SvgSvgElement()
  ..setAttribute('width', 0)
  ..setAttribute('height', 0)
  ..style.position = 'absolute';

/// Converts Path to svg element that contains a clip-path definition.
///
/// Calling this method updates [_clipIdCounter]. The HTML id of the generated
/// clip is set to "svgClip${_clipIdCounter}", e.g. "svgClip123".
svg.SvgSvgElement pathToSvgClipPath(ui.Path path,
    {double offsetX = 0,
    double offsetY = 0,
    double scaleX = 1.0,
    double scaleY = 1.0}) {
  _clipIdCounter += 1;
  final svg.SvgSvgElement root = kSvgResourceHeader.clone(false) as svg.SvgSvgElement;
  final svg.DefsElement defs = svg.DefsElement();
  root.append(defs);

  final String clipId = 'svgClip$_clipIdCounter';
  final svg.ClipPathElement clipPath = svg.ClipPathElement();
  defs.append(clipPath);
  clipPath.id = clipId;

  final svg.PathElement svgPath = svg.PathElement();
  clipPath.append(svgPath);
  svgPath.setAttribute('fill', '#FFFFFF');

  // Firefox objectBoundingBox fails to scale to 1x1 units, instead use
  // no clipPathUnits but write the path in target units.
  if (browserEngine != BrowserEngine.firefox) {
    clipPath.setAttribute('clipPathUnits', 'objectBoundingBox');
    svgPath.setAttribute('transform', 'scale($scaleX, $scaleY)');
  }

  svgPath.setAttribute('d', pathToSvg((path as SurfacePath).pathRef, offsetX: offsetX, offsetY: offsetY));
  return root;
}

String createSvgClipUrl() => 'url(#svgClip$_clipIdCounter)';

/// Resets clip ids. Used for testing by [debugForgetFrameScene] API.
void resetSvgClipIds() {
  _clipIdCounter = 0;
}
