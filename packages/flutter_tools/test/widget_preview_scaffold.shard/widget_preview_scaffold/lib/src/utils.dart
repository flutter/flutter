// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:widget_preview_scaffold/src/widget_preview.dart';

Iterable<WidgetPreview> buildMultiWidgetPreview({
  required String packageName,
  required String scriptUri,
  required MultiPreview preview,
  required Object? Function() previewFunction,
}) {
  return preview.transform().map(
    (p) => buildWidgetPreview(
      packageName: packageName,
      scriptUri: scriptUri,
      transformedPreview: p,
      previewFunction: previewFunction,
    ),
  );
}

WidgetPreview buildWidgetPreview({
  required String packageName,
  required String scriptUri,
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
    previewData: transformedPreview,
    packageName: packageName,
  );
}

WidgetPreview buildWidgetPreviewError({
  required String packageName,
  required String scriptUri,
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
    previewData: const Preview(group: 'Invalid Previews'),
    packageName: packageName,
  );
}

/// Returns a [TextStyle] with [FontFeature.proportionalFigures] applied to
/// fix blurry text.
TextStyle fixBlurryText(TextStyle style) {
  return style.copyWith(
    fontFeatures: [const FontFeature.proportionalFigures()],
  );
}

final TextStyle linkTextStyle = fixBlurryText(
  TextStyle(
    decoration: TextDecoration.underline,
    // TODO(bkonyi): this color scheme is from DevTools and should be responsive
    // to changes in the previewer theme.
    color: const Color(0xFF1976D2),
  ),
);

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
