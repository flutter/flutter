// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../engine.dart';

const double _kDefaultRootFontSize = 16.0;

/// This class provides observable, real-time text scale changes of the
/// browser's root element.
class TextScaleFactorProvider {
  /// Creates a [TextScaleFactorProvider] and attaches DOM observers to detect
  /// font size changes.
  TextScaleFactorProvider() {
    _textScaleFactor = _computeTextScaleFactor();

    _fontSizeProbeResizeObserver = createDomResizeObserver((_, _) {
      _maybeUpdateTextScaleFactor();
    });

    if (_fontSizeProbeResizeObserver != null) {
      // To detect changes in the root element's font size, we create a probe
      // element with height '1rem'. A ResizeObserver monitors this probe. When
      // the root element's font size changes, the pixel height of '1rem'
      // changes, triggering the observer.
      final DomElement probe = createDomElement('flt-font-size-probe');
      probe.style
        ..position = 'fixed'
        ..visibility = 'hidden'
        ..overflow = 'hidden'
        ..transform = 'translate(-99999px, -99999px)'
        ..height = '1rem';
      domDocument.body!.append(probe);
      _fontSizeProbeResizeObserver!.observe(probe);
      _fontSizeProbe = probe;
    } else {
      // Fallback for environments where ResizeObserver is not available.
      // This only detects explicit changes to the 'style' attribute of the
      // root element, which is less robust than the ResizeObserver approach.
      _fontSizeMutationObserver = createDomMutationObserver((
        List<DomMutationRecord> mutations,
        DomMutationObserver _,
      ) {
        for (final DomMutationRecord mutation in mutations) {
          if (mutation.type == 'attributes' && mutation.attributeName == 'style') {
            _maybeUpdateTextScaleFactor();
          }
        }
      });
      _fontSizeMutationObserver!.observe(
        domDocument.documentElement!,
        attributes: true,
        attributeFilter: <String>['style'],
      );
    }
  }

  late double _textScaleFactor;

  /// The current text scale factor derived from the root element's font size.
  double get textScaleFactor => _textScaleFactor;

  /// The fallback observer used when `ResizeObserver` is not supported.
  ///
  /// This observes the `style` attribute of the `<html>` element to detect
  /// explicit font size changes.
  DomMutationObserver? _fontSizeMutationObserver;

  /// The primary observer that watches for changes in the size of [_fontSizeProbe].
  DomResizeObserver? _fontSizeProbeResizeObserver;

  /// A hidden DOM element with a height of `1rem` inserted into the body.
  ///
  /// This element acts as a proxy to detect root elements' font size changes
  /// via [_fontSizeProbeResizeObserver].
  DomElement? _fontSizeProbe;

  final StreamController<double> _onTextScaleFactorChangedStreamController =
      StreamController<double>.broadcast();

  /// A stream that emits the new text scale factor whenever it changes.
  Stream<double> get onTextScaleFactorChanged => _onTextScaleFactorChangedStreamController.stream;

  /// Clears any resources held by this [TextScaleFactorProvider] instance.
  ///
  /// All internal event handlers will be disconnected, and the
  /// [onTextScaleFactorChanged] stream will be closed.
  void dispose() {
    _fontSizeMutationObserver?.disconnect();
    _fontSizeMutationObserver = null;
    _fontSizeProbeResizeObserver?.disconnect();
    _fontSizeProbeResizeObserver = null;
    _fontSizeProbe?.remove();
    _fontSizeProbe = null;
    _onTextScaleFactorChangedStreamController.close();
  }

  void _maybeUpdateTextScaleFactor() {
    final double textScaleFactor = _computeTextScaleFactor();

    if (_textScaleFactor == textScaleFactor) {
      return;
    }

    _textScaleFactor = textScaleFactor;
    _onTextScaleFactorChangedStreamController.add(textScaleFactor);
  }

  /// Finds the text scale factor of the browser by looking at the computed style
  /// of the browser's <html> element.
  double _computeTextScaleFactor() {
    final num fontSize = parseFontSize(domDocument.documentElement!) ?? _kDefaultRootFontSize;
    return fontSize / _kDefaultRootFontSize;
  }
}
