// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12
part of engine;

/// A surface that applies an [ColorFilter] to its children.
class PersistedColorFilter extends PersistedContainerSurface
    implements ui.ColorFilterEngineLayer {
  PersistedColorFilter(PersistedColorFilter? oldLayer, this.filter)
      : super(oldLayer);

  @override
  html.Element? get childContainer => _childContainer;

  /// The dedicated child container element that's separate from the
  /// [rootElement] is used to compensate for the coordinate system shift
  /// introduced by the [rootElement] translation.
  html.Element? _childContainer;

  final ui.ColorFilter filter;
  html.Element? _filterElement;
  bool containerVisible = true;

  @override
  void adoptElements(PersistedColorFilter oldSurface) {
    super.adoptElements(oldSurface);
    _childContainer = oldSurface._childContainer;
    oldSurface._childContainer = null;
  }

  @override
  void discard() {
    super.discard();
    // Do not detach the child container from the root. It is permanently
    // attached. The elements are reused together and are detached from the DOM
    // together.
    _childContainer = null;
  }

  @override
  html.Element createElement() {
    html.Element element = defaultCreateElement('flt-color-filter');
    html.Element container = html.Element.tag('flt-filter-interior');
    container.style.position = 'absolute';
    _childContainer = container;
    element.append(_childContainer!);
    return element;
  }

  @override
  void apply() {
    if (_filterElement != null) {
      _filterElement?.remove();
    }
    final EngineColorFilter? engineValue = filter as EngineColorFilter?;
    if (engineValue == null) {
      rootElement!.style.backgroundColor = '';
      childContainer?.style.visibility = 'visible';
      return;
    }

    if (engineValue is! _CkBlendModeColorFilter) {
      childContainer?.style.visibility = 'visible';
      return;
    }

    ui.Color filterColor = engineValue.color;
    ui.BlendMode colorFilterBlendMode = engineValue.blendMode;
    html.CssStyleDeclaration style = rootElement!.style;
    switch (colorFilterBlendMode) {
      case ui.BlendMode.clear:
      case ui.BlendMode.dstOut:
      case ui.BlendMode.srcOut:
        childContainer?.style.visibility = 'hidden';
        return;
      case ui.BlendMode.dst:
      case ui.BlendMode.dstIn:
        // Noop.
        return;
      case ui.BlendMode.src:
      case ui.BlendMode.srcOver:
        // Uses source filter color.
        // Since we don't have a size, we can't use background color.
        // Use svg filter srcIn instead.
        colorFilterBlendMode = ui.BlendMode.srcIn;
        break;
      case ui.BlendMode.dstOver:
      case ui.BlendMode.srcIn:
      case ui.BlendMode.srcATop:
      case ui.BlendMode.dstATop:
      case ui.BlendMode.xor:
      case ui.BlendMode.plus:
      case ui.BlendMode.modulate:
      case ui.BlendMode.screen:
      case ui.BlendMode.overlay:
      case ui.BlendMode.darken:
      case ui.BlendMode.lighten:
      case ui.BlendMode.colorDodge:
      case ui.BlendMode.colorBurn:
      case ui.BlendMode.hardLight:
      case ui.BlendMode.softLight:
      case ui.BlendMode.difference:
      case ui.BlendMode.exclusion:
      case ui.BlendMode.multiply:
      case ui.BlendMode.hue:
      case ui.BlendMode.saturation:
      case ui.BlendMode.color:
      case ui.BlendMode.luminosity:
        break;
    }

    // Use SVG filter for blend mode.
    String? svgFilter =
        svgFilterFromBlendMode(filterColor, colorFilterBlendMode);
    if (svgFilter != null) {
      _filterElement =
          html.Element.html(svgFilter, treeSanitizer: _NullTreeSanitizer());
      rootElement!.append(_filterElement!);
      rootElement!.style.filter = 'url(#_fcf${_filterIdCounter})';
      if (colorFilterBlendMode == ui.BlendMode.saturation ||
          colorFilterBlendMode == ui.BlendMode.multiply ||
          colorFilterBlendMode == ui.BlendMode.modulate) {
        style.backgroundColor = colorToCssString(filterColor);
      }
      return;
    }
  }

  @override
  void update(PersistedColorFilter oldSurface) {
    super.update(oldSurface);

    if (oldSurface.filter != filter) {
      apply();
    }
  }
}

String? svgFilterFromBlendMode(
    ui.Color? filterColor, ui.BlendMode colorFilterBlendMode) {
  String? svgFilter;
  switch (colorFilterBlendMode) {
    case ui.BlendMode.srcIn:
    case ui.BlendMode.srcATop:
      svgFilter = _srcInColorFilterToSvg(filterColor);
      break;
    case ui.BlendMode.srcOut:
      svgFilter = _srcOutColorFilterToSvg(filterColor);
      break;
    case ui.BlendMode.xor:
      svgFilter = _xorColorFilterToSvg(filterColor);
      break;
    case ui.BlendMode.plus:
      // Porter duff source + destination.
      svgFilter = _compositeColorFilterToSvg(filterColor, 0, 1, 1, 0);
      break;
    case ui.BlendMode.modulate:
      // Porter duff source * destination but preserves alpha.
      svgFilter = _modulateColorFilterToSvg(filterColor!);
      break;
    case ui.BlendMode.overlay:
      // Since overlay is the same as hard-light by swapping layers,
      // pass hard-light blend function.
      svgFilter =
          _blendColorFilterToSvg(filterColor, 'hard-light', swapLayers: true);
      break;
    // Several of the filters below (although supported) do not render the
    // same (close but not exact) as native flutter when used as blend mode
    // for a background-image with a background color. They only look
    // identical when feBlend is used within an svg filter definition.
    //
    // Saturation filter uses destination when source is transparent.
    // cMax = math.max(r, math.max(b, g));
    // cMin = math.min(r, math.min(b, g));
    // delta = cMax - cMin;
    // lightness = (cMax + cMin) / 2.0;
    // saturation = delta / (1.0 - (2 * lightness - 1.0).abs());
    case ui.BlendMode.saturation:
    case ui.BlendMode.colorDodge:
    case ui.BlendMode.colorBurn:
    case ui.BlendMode.hue:
    case ui.BlendMode.color:
    case ui.BlendMode.luminosity:
    case ui.BlendMode.multiply:
    case ui.BlendMode.screen:
    case ui.BlendMode.overlay:
    case ui.BlendMode.darken:
    case ui.BlendMode.lighten:
    case ui.BlendMode.colorDodge:
    case ui.BlendMode.colorBurn:
    case ui.BlendMode.hardLight:
    case ui.BlendMode.softLight:
    case ui.BlendMode.difference:
    case ui.BlendMode.exclusion:
      svgFilter = _blendColorFilterToSvg(
          filterColor, _stringForBlendMode(colorFilterBlendMode));
      break;
    case ui.BlendMode.src:
    case ui.BlendMode.dst:
    case ui.BlendMode.dstATop:
    case ui.BlendMode.dstIn:
    case ui.BlendMode.dstOut:
    case ui.BlendMode.dstOver:
    case ui.BlendMode.clear:
    case ui.BlendMode.srcOver:
      assert(
          false,
          'Invalid svg filter request for blend-mode '
          '$colorFilterBlendMode');
      break;
  }
  return svgFilter;
}

int _filterIdCounter = 0;

// The color matrix for feColorMatrix element changes colors based on
// the following:
//
// | R' |     | r1 r2 r3 r4 r5 |   | R |
// | G' |     | g1 g2 g3 g4 g5 |   | G |
// | B' |  =  | b1 b2 b3 b4 b5 | * | B |
// | A' |     | a1 a2 a3 a4 a5 |   | A |
// | 1  |     | 0  0  0  0  1  |   | 1 |
//
// R' = r1*R + r2*G + r3*B + r4*A + r5
// G' = g1*R + g2*G + g3*B + g4*A + g5
// B' = b1*R + b2*G + b3*B + b4*A + b5
// A' = a1*R + a2*G + a3*B + a4*A + a5
String _srcInColorFilterToSvg(ui.Color? color) {
  _filterIdCounter += 1;
  return '$kSvgResourceHeader'
      '<filter id="_fcf$_filterIdCounter" '
      'filterUnits="objectBoundingBox" x="0%" y="0%" width="100%" height="100%">'
      '<feColorMatrix values="0 0 0 0 1 ' // Ignore input, set it to absolute.
      '0 0 0 0 1 '
      '0 0 0 0 1 '
      '0 0 0 1 0" result="destalpha"/>' // Just take alpha channel of destination
      '<feFlood flood-color="${colorToCssString(color)}" flood-opacity="1" result="flood">'
      '</feFlood>'
      '<feComposite in="flood" in2="destalpha" '
      'operator="arithmetic" k1="1" k2="0" k3="0" k4="0" result="comp">'
      '</feComposite>'
      '</filter></svg>';
}

String _srcOutColorFilterToSvg(ui.Color? color) {
  _filterIdCounter += 1;
  return '$kSvgResourceHeader'
      '<filter id="_fcf$_filterIdCounter" '
      'filterUnits="objectBoundingBox" x="0%" y="0%" width="100%" height="100%">'
      '<feFlood flood-color="${colorToCssString(color)}" flood-opacity="1" result="flood">'
      '</feFlood>'
      '<feComposite in="flood" in2="SourceGraphic" operator="out" result="comp">'
      '</feComposite>'
      '</filter></svg>';
}

String _xorColorFilterToSvg(ui.Color? color) {
  _filterIdCounter += 1;
  return '$kSvgResourceHeader'
      '<filter id="_fcf$_filterIdCounter" '
      'filterUnits="objectBoundingBox" x="0%" y="0%" width="100%" height="100%">'
      '<feFlood flood-color="${colorToCssString(color)}" flood-opacity="1" result="flood">'
      '</feFlood>'
      '<feComposite in="flood" in2="SourceGraphic" operator="xor" result="comp">'
      '</feComposite>'
      '</filter></svg>';
}

// The source image and color are composited using :
// result = k1 *in*in2 + k2*in + k3*in2 + k4.
String _compositeColorFilterToSvg(
    ui.Color? color, double k1, double k2, double k3, double k4) {
  _filterIdCounter += 1;
  return '$kSvgResourceHeader'
      '<filter id="_fcf$_filterIdCounter" '
      'filterUnits="objectBoundingBox" x="0%" y="0%" width="100%" height="100%">'
      '<feFlood flood-color="${colorToCssString(color)}" flood-opacity="1" result="flood">'
      '</feFlood>'
      '<feComposite in="flood" in2="SourceGraphic" '
      'operator="arithmetic" k1="$k1" k2="$k2" k3="$k3" k4="$k4" result="comp">'
      '</feComposite>'
      '</filter></svg>';
}

// Porter duff source * destination , keep source alpha.
// First apply color filter to source to change it to [color], then
// composite using multiplication.
String _modulateColorFilterToSvg(ui.Color color) {
  _filterIdCounter += 1;
  final double r = color.red / 255.0;
  final double b = color.blue / 255.0;
  final double g = color.green / 255.0;
  return '$kSvgResourceHeader'
      '<filter id="_fcf$_filterIdCounter" '
      'filterUnits="objectBoundingBox" x="0%" y="0%" width="100%" height="100%">'
      '<feColorMatrix values="0 0 0 0 $r ' // Ignore input, set it to absolute.
      '0 0 0 0 $g '
      '0 0 0 0 $b '
      '0 0 0 1 0" result="recolor"/>'
      '<feComposite in="recolor" in2="SourceGraphic" '
      'operator="arithmetic" k1="1" k2="0" k3="0" k4="0" result="comp">'
      '</feComposite>'
      '</filter></svg>';
}

// Uses feBlend element to blend source image with a color.
String _blendColorFilterToSvg(ui.Color? color, String? feBlend,
    {bool swapLayers = false}) {
  _filterIdCounter += 1;
  return '$kSvgResourceHeader'
          '<filter id="_fcf$_filterIdCounter" filterUnits="objectBoundingBox" '
          'x="0%" y="0%" width="100%" height="100%">'
          '<feFlood flood-color="${colorToCssString(color)}" flood-opacity="1" result="flood">'
          '</feFlood>' +
      (swapLayers
          ? '<feBlend in="SourceGraphic" in2="flood" mode="$feBlend"/>'
          : '<feBlend in="flood" in2="SourceGraphic" mode="$feBlend"/>') +
      '</filter></svg>';
}
