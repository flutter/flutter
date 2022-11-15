// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/ui.dart' as ui;

import '../color_filter.dart';
import '../dom.dart';
import '../embedder.dart';
import 'shaders/shader.dart';
import 'surface.dart';

/// A surface that applies an [imageFilter] to its children.
class PersistedImageFilter extends PersistedContainerSurface
    implements ui.ImageFilterEngineLayer {
  PersistedImageFilter(PersistedImageFilter? super.oldLayer, this.filter);

  final ui.ImageFilter filter;

  DomElement? _svgFilter;

  @override
  void adoptElements(PersistedImageFilter oldSurface) {
    super.adoptElements(oldSurface);
    _svgFilter = oldSurface._svgFilter;
  }

  @override
  void discard() {
    super.discard();
    flutterViewEmbedder.removeResource(_svgFilter);
    _svgFilter = null;
  }

  @override
  DomElement createElement() {
    return defaultCreateElement('flt-image-filter');
  }

  @override
  void apply() {
    EngineImageFilter backendFilter;
    if (filter is ui.ColorFilter) {
      backendFilter = createHtmlColorFilter(filter as EngineColorFilter)!;
    } else {
      backendFilter = filter as EngineImageFilter;
    }
    flutterViewEmbedder.removeResource(_svgFilter);
    _svgFilter = null;
    if (backendFilter is ModeHtmlColorFilter) {
      _svgFilter = backendFilter.makeSvgFilter(rootElement);
      /// Some blendModes do not make an svgFilter. See [EngineHtmlColorFilter.makeSvgFilter()]
      if (_svgFilter == null) {
          return;
      }
    } else if (backendFilter is MatrixHtmlColorFilter) {
      _svgFilter = backendFilter.makeSvgFilter(rootElement);
    }

    rootElement!.style.filter = backendFilter.filterAttribute;
    rootElement!.style.transform = backendFilter.transformAttribute;
  }

  @override
  void update(PersistedImageFilter oldSurface) {
    super.update(oldSurface);

    if (oldSurface.filter != filter) {
      apply();
    }
  }
}
