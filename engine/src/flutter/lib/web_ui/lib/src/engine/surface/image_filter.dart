// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
part of engine;

/// A surface that applies an [imageFilter] to its children.
class PersistedImageFilter extends PersistedContainerSurface
    implements ui.ImageFilterEngineLayer {
  PersistedImageFilter(PersistedImageFilter oldLayer, this.filter) : super(oldLayer);

  final ui.ImageFilter filter;

  @override
  html.Element createElement() {
    return defaultCreateElement('flt-image-filter');
  }

  @override
  void apply() {
    rootElement.style.filter = _imageFilterToCss(filter);
  }

  @override
  void update(PersistedImageFilter oldSurface) {
    super.update(oldSurface);

    if (oldSurface.filter != filter) {
      apply();
    }
  }
}
