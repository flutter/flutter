// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'widget_preview.dart';

Iterable<WidgetPreview> buildMultiWidgetPreview({
  required String packageName,
  required String scriptUri,
  required int line,
  required int column,
  required MultiPreview preview,
  required Object? Function() previewFunction,
}) {
  return preview.transform().map(
    (p) => buildWidgetPreview(
      packageName: packageName,
      scriptUri: scriptUri,
      line: line,
      column: column,
      transformedPreview: p,
      previewFunction: previewFunction,
    ),
  );
}

WidgetPreview buildWidgetPreview({
  required String packageName,
  required String scriptUri,
  required int line,
  required int column,
  required Preview transformedPreview,
  required Object? Function() previewFunction,
}) {
  Widget Function() previewBuilder;
  if (previewFunction is WidgetBuilder Function()) {
    previewBuilder = () {
      return Builder(builder: previewFunction());
    };
  } else {
    previewBuilder = previewFunction as Widget Function();
  }
  return WidgetPreview(
    builder: previewBuilder,
    scriptUri: scriptUri,
    line: line,
    column: column,
    previewData: transformedPreview,
    packageName: packageName,
  );
}

WidgetPreview buildWidgetPreviewError({
  required String packageName,
  required String scriptUri,
  required int line,
  required int column,
  required String packageUri,
  required String functionName,
  required bool dependencyHasErrors,
}) {
  var errorMessage = '$packageUri has errors!';
  if (dependencyHasErrors) {
    errorMessage = 'Dependency of $errorMessage';
  }
  return WidgetPreview(
    builder: () => Text('$functionName: $errorMessage'),
    scriptUri: scriptUri,
    line: line,
    column: column,
    previewData: const Preview(group: 'Invalid Previews'),
    packageName: packageName,
  );
}

/// A basic vertical spacer.
class VerticalSpacer extends StatelessWidget {
  /// Creates a basic vertical spacer.
  const VerticalSpacer({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 10);
  }
}

/// A basic horizontal spacer.
class HorizontalSpacer extends StatelessWidget {
  /// Creates a basic vertical spacer.
  const HorizontalSpacer({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: 10);
  }
}

/// A widget that explicitly responds to hot reload events.
///
/// Hot reload will always result in [reassemble] being called.
class HotReloadListener extends StatefulWidget {
  const HotReloadListener({
    super.key,
    required this.onHotReload,
    required this.child,
  });

  final VoidCallback onHotReload;
  final Widget child;

  @override
  HotReloadListenerState createState() => HotReloadListenerState();
}

class HotReloadListenerState extends State<HotReloadListener> {
  @override
  void reassemble() {
    super.reassemble();
    widget.onHotReload();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Wraps [child] in a border with default styling.
///
/// This border can optionally be made non-uniform by setting any of
/// [showTop], [showBottom], [showLeft] or [showRight] to false.
///
/// Originally from DevTools.
final class OutlineDecoration extends StatelessWidget {
  const OutlineDecoration({
    super.key,
    this.child,
    this.showTop = true,
    this.showBottom = true,
    this.showLeft = true,
    this.showRight = true,
  });

  factory OutlineDecoration.onlyBottom({required Widget? child}) =>
      OutlineDecoration(
        showTop: false,
        showLeft: false,
        showRight: false,
        child: child,
      );

  factory OutlineDecoration.onlyTop({required Widget? child}) =>
      OutlineDecoration(
        showBottom: false,
        showLeft: false,
        showRight: false,
        child: child,
      );

  factory OutlineDecoration.onlyLeft({required Widget? child}) =>
      OutlineDecoration(
        showBottom: false,
        showTop: false,
        showRight: false,
        child: child,
      );

  factory OutlineDecoration.onlyRight({required Widget? child}) =>
      OutlineDecoration(
        showBottom: false,
        showTop: false,
        showLeft: false,
        child: child,
      );

  final bool showTop;
  final bool showBottom;
  final bool showLeft;
  final bool showRight;

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).focusColor;
    final border = BorderSide(color: color);
    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: showLeft ? border : BorderSide.none,
          right: showRight ? border : BorderSide.none,
          top: showTop ? border : BorderSide.none,
          bottom: showBottom ? border : BorderSide.none,
        ),
      ),
      child: child,
    );
  }
}
