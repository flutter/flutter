// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

final Expando<BackendMaskFilter> _backendMaskFilters = Expando<BackendMaskFilter>();

final Finalizer _maskFilterFinalizer = NativeMemoryFinalizer((Object filter) {
  (filter as BackendMaskFilter).dispose();
});

/// A filter that modifies the alpha channel of a shape as it is drawn.
class EngineMaskFilter implements ui.MaskFilter {
  const EngineMaskFilter.blur(this._style, this._sigma);

  final ui.BlurStyle _style;
  final double _sigma;

  @override
  double get webOnlySigma => _sigma;
  @override
  ui.BlurStyle get webOnlyBlurStyle => _style;

  /// The backend implementation of this mask filter.
  BackendMaskFilter get backendFilter {
    BackendMaskFilter? filter = _backendMaskFilters[this];
    if (filter == null) {
      filter = renderer.createMaskFilter(this);
      _backendMaskFilters[this] = filter;
      _maskFilterFinalizer.attach(this, filter, detach: filter);
    }
    return filter;
  }

  @override
  bool operator ==(Object other) {
    return other is EngineMaskFilter && other._style == _style && other._sigma == _sigma;
  }

  @override
  int get hashCode => Object.hash(_style, _sigma);

  @override
  String toString() => 'MaskFilter.blur($_style, ${_sigma.toStringAsFixed(1)})';
}
