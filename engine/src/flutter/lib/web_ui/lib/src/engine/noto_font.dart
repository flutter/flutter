// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class NotoFont {
  NotoFont(
    this.name,
    this.url, {
    required this.index,
    this.monolithicParent,
    this.slices = const <String>{},
  });

  final String name;
  final String url;
  final int index;

  /// If this is a monolithic parent font, the names of all its split slices.
  final Set<String> slices;

  /// If this is a split slice, the name of its monolithic parent font.
  final String? monolithicParent;
}

/// A component is a set of code points common to some fonts. Each code point is
/// in a single component. Each font can be represented as a disjoint union of
/// components. We store the inverse of this relationship, the fonts that use
/// this component. The font fallback selection algorithm does not need the code
/// points in a component or a font, so this is not stored, but can be recovered
/// via the map from code-point to component.
class FallbackFontComponent {
  FallbackFontComponent(this.fonts);
  final List<NotoFont> fonts;
}
