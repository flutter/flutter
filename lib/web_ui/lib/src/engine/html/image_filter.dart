// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/ui.dart' as ui;

import '../dom.dart';
import 'shaders/shader.dart';
import 'surface.dart';

/// A surface that applies an [imageFilter] to its children.
class PersistedImageFilter extends PersistedContainerSurface
    implements ui.ImageFilterEngineLayer {
  PersistedImageFilter(PersistedImageFilter? oldLayer, this.filter) : super(oldLayer);

  final ui.ImageFilter filter;

  @override
  DomElement createElement() {
    return defaultCreateElement('flt-image-filter');
  }

  @override
  void apply() {
    rootElement!.style.filter = (filter as EngineImageFilter).filterAttribute;
    rootElement!.style.transform = (filter as EngineImageFilter).transformAttribute;
  }

  @override
  void update(PersistedImageFilter oldSurface) {
    super.update(oldSurface);

    if (oldSurface.filter != filter) {
      apply();
    }
  }
}
