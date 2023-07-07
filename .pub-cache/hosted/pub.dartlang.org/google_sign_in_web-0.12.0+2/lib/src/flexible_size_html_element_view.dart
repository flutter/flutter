// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dom.dart';

/// An HTMLElementView widget that resizes with its contents.
class FlexHtmlElementView extends StatefulWidget {
  /// Constructor
  const FlexHtmlElementView({
    super.key,
    required this.viewType,
    this.onPlatformViewCreated,
    this.initialSize,
  });

  /// See [HtmlElementView.viewType].
  final String viewType;

  /// See [HtmlElementView.onPlatformViewCreated].
  final PlatformViewCreatedCallback? onPlatformViewCreated;

  /// The initial Size for the widget, before it starts tracking its contents.
  final Size? initialSize;

  @override
  State<StatefulWidget> createState() => _FlexHtmlElementView();
}

class _FlexHtmlElementView extends State<FlexHtmlElementView> {
  /// The last measured size of the watched element.
  Size? _lastReportedSize;

  /// Watches for changes being made to the DOM tree.
  ///
  /// See: https://developer.mozilla.org/en-US/docs/Web/API/MutationObserver
  DomMutationObserver? _mutationObserver;

  /// Reports changes to the dimensions of an Element's content box.
  ///
  /// See: https://developer.mozilla.org/en-US/docs/Web/API/Resize_Observer_API
  DomResizeObserver? _resizeObserver;

  @override
  void dispose() {
    // Disconnect the observers
    _mutationObserver?.disconnect();
    _resizeObserver?.disconnect();
    super.dispose();
  }

  /// Update the state with the new `size`, if needed.
  void _doResize(Size size) {
    if (size != _lastReportedSize) {
      domConsole.debug(
          'Resizing', <Object>[widget.viewType, size.width, size.height]);
      setState(() {
        _lastReportedSize = size;
      });
    }
  }

  /// The function called whenever an observed resize occurs.
  void _onResizeEntries(
    List<DomResizeObserverEntry> resizes,
    DomResizeObserver observer,
  ) {
    final DomRectReadOnly rect = resizes.last.contentRect;
    if (rect.width > 0 && rect.height > 0) {
      _doResize(Size(rect.width, rect.height));
    }
  }

  /// A function which will be called on each DOM change that qualifies given the observed node and options.
  ///
  /// When mutations are received, this function attaches a Resize Observer to
  /// the first child of the mutation, which will drive
  void _onMutationRecords(
    List<DomMutationRecord> mutations,
    DomMutationObserver observer,
  ) {
    for (final DomMutationRecord mutation in mutations) {
      if (mutation.addedNodes != null) {
        final DomElement? element = _locateSizeProvider(mutation.addedNodes!);
        if (element != null) {
          _resizeObserver = createDomResizeObserver(_onResizeEntries);
          _resizeObserver?.observe(element);
          // Stop looking at other mutations
          observer.disconnect();
          return;
        }
      }
    }
  }

  /// Registers a MutationObserver on the root element of the HtmlElementView.
  void _registerListeners(DomElement? root) {
    assert(root != null, 'DOM is not ready for the FlexHtmlElementView');
    _mutationObserver = createDomMutationObserver(_onMutationRecords);
    // Monitor the size of the child element, whenever it's created...
    _mutationObserver!.observe(
      root!,
      childList: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: _lastReportedSize ?? widget.initialSize ?? const Size(1, 1),
      child: HtmlElementView(
          viewType: widget.viewType,
          onPlatformViewCreated: (int viewId) async {
            _registerListeners(_locatePlatformViewRoot(viewId));
            if (widget.onPlatformViewCreated != null) {
              widget.onPlatformViewCreated!(viewId);
            }
          }),
    );
  }
}

/// Locates which of the elements will act as the size provider.
///
/// The `elements` list should contain a single element: the only child of the
/// element returned by `_locatePlatformViewRoot`.
DomElement? _locateSizeProvider(List<DomElement> elements) {
  return elements.first;
}

/// Finds the root element of a platform view by its `viewId`.
///
/// This element matches the one returned by the registered platform view factory.
DomElement? _locatePlatformViewRoot(int viewId) {
  return domDocument
      .querySelector('flt-platform-view[slot\$="-$viewId"] :first-child');
}
