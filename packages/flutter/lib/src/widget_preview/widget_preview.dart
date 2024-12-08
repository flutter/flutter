// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'controls.dart';
import 'utils.dart';

/// Wraps a [Widget], initializing various state and properties to allow for
/// previewing of the [Widget] in the widget previewer.
///
/// WARNING: This interface is not stable and **will change**.
class WidgetPreview extends StatefulWidget {
  /// Wraps [child] in a [WidgetPreview] instance that applies some set of
  /// properties.
  const WidgetPreview({
    super.key,
    required this.child,
    this.name,
    this.width,
    this.height,
    this.textScaleFactor,
  });

  /// A description to be displayed alongside the preview.
  final String? name;

  /// The [Widget] to be rendered in the preview.
  final Widget child;

  /// Artificial width constraint to be applied to the [child].
  final double? width;

  /// Artificial height constraint to be applied to the [child].
  final double? height;

  /// Applies font scaling to text within the [child].
  final double? textScaleFactor;

  @override
  State<WidgetPreview> createState() => _WidgetPreviewState();
}

class _WidgetPreviewState extends State<WidgetPreview> {
  final TransformationController transformationController =
      TransformationController();

  @override
  void dispose() {
    transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BoxConstraints previewerConstraints =
        WidgetPreviewerWindowConstraints.getRootConstraints(context);

    final BoxConstraints maxSizeConstraints = previewerConstraints.copyWith(
      minHeight: widget.height ??
          previewerConstraints.maxHeight *
              WidgetPreviewWrapper.unconstrainedChildScalingRatio,
      maxHeight: widget.height ??
          previewerConstraints.maxHeight *
              WidgetPreviewWrapper.unconstrainedChildScalingRatio,
      minWidth: widget.width,
      maxWidth: widget.width,
    );

    Widget preview = WidgetPreviewWrapper(
      previewerConstraints: maxSizeConstraints,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: widget.child,
      ),
    );

    preview = MediaQuery(
      data: _buildMediaQueryOverride(),
      child: preview,
    );

    preview = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (widget.name != null) ...<Widget>[
          Text(
            widget.name!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w300,
            ),
          ),
          const VerticalSpacer(),
        ],
        _InteractiveViewerWrapper(
          transformationController: transformationController,
          child: preview,
        ),
        const VerticalSpacer(),
        ZoomControls(
          transformationController: transformationController,
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 16.0,
            horizontal: 16.0,
          ),
          child: preview,
        ),
      ),
    );
  }

  MediaQueryData _buildMediaQueryOverride() {
    MediaQueryData mediaQueryData = MediaQuery.of(context);
    if (widget.textScaleFactor != null) {
      mediaQueryData = mediaQueryData.copyWith(
        textScaler: TextScaler.linear(widget.textScaleFactor!),
      );
    }

    final Size size = Size(widget.width ?? mediaQueryData.size.width,
        widget.height ?? mediaQueryData.size.height);

    if (widget.width != null || widget.height != null) {
      mediaQueryData = mediaQueryData.copyWith(
        size: size,
      );
    }
    return mediaQueryData;
  }
}

/// An [InheritedWidget] that propagates the current size of the
/// WidgetPreviewScaffold.
///
/// This is needed when determining how to put constraints on previewed widgets
/// that would otherwise have infinite constraints.
class WidgetPreviewerWindowConstraints extends InheritedWidget {
  /// Propagates the current size of the widget previewer.
  const WidgetPreviewerWindowConstraints({
    super.key,
    required super.child,
    required BoxConstraints constraints,
  }) : _constraints = constraints;

  final BoxConstraints _constraints;

  /// Returns the constraints representing the current size of the widget previewer.
  static BoxConstraints getRootConstraints(BuildContext context) {
    final WidgetPreviewerWindowConstraints? result = context
        .dependOnInheritedWidgetOfExactType<WidgetPreviewerWindowConstraints>();
    assert(
      result != null,
      'No WidgetPreviewerWindowConstraints founds in context',
    );
    return result!._constraints;
  }

  @override
  bool updateShouldNotify(WidgetPreviewerWindowConstraints oldWidget) {
    return oldWidget._constraints != _constraints;
  }
}

/// Provides support for zooming into the contents of a [WidgetPreview].
class _InteractiveViewerWrapper extends StatelessWidget {
  const _InteractiveViewerWrapper({
    required this.child,
    required this.transformationController,
  });

  final Widget child;
  final TransformationController transformationController;

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: transformationController,
      scaleEnabled: false,
      child: child,
    );
  }
}

/// Wrapper applying a custom render object to force constraints on
/// unconstrained widgets.
@visibleForTesting
class WidgetPreviewWrapper extends SingleChildRenderObjectWidget {
  @visibleForTesting
  // ignore: public_member_api_docs
  const WidgetPreviewWrapper({
    super.key,
    super.child,
    required this.previewerConstraints,
  });

  /// The ratio of the max height provided by a parent
  /// [WidgetPreviewerWindowConstraints] that an unconstrained child should
  /// be allowed to occupy.
  @visibleForTesting
  static const double unconstrainedChildScalingRatio = 0.5;

  /// The size of the previewer render surface.
  final BoxConstraints previewerConstraints;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return WidgetPreviewWrapperBox(
      previewerConstraints: previewerConstraints,
      child: null,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    WidgetPreviewWrapperBox renderObject,
  ) {
    renderObject.setPreviewerConstraints(previewerConstraints);
  }
}

/// Custom render box that forces constraints onto unconstrained widgets.
@visibleForTesting
class WidgetPreviewWrapperBox extends RenderShiftedBox {
  // ignore: public_member_api_docs
  WidgetPreviewWrapperBox({
    required RenderBox? child,
    required BoxConstraints previewerConstraints,
  })  : _previewerConstraints = previewerConstraints,
        super(child);

  BoxConstraints _constraintOverride = const BoxConstraints();
  BoxConstraints _previewerConstraints;

  /// Updates the constraints for the child based on changes to the constraints
  /// provided by the parent [WidgetPreviewerWindowConstraints].
  void setPreviewerConstraints(BoxConstraints previewerConstraints) {
    if (_previewerConstraints == previewerConstraints) {
      return;
    }
    _previewerConstraints = previewerConstraints;
    markNeedsLayout();
  }

  @override
  void layout(
    Constraints constraints, {
    bool parentUsesSize = false,
  }) {
    if (child != null && constraints is BoxConstraints) {
      double minInstrinsicHeight;
      try {
        minInstrinsicHeight = child!.getMinIntrinsicHeight(
          constraints.maxWidth,
        );
      } on Object {
        minInstrinsicHeight = 0.0;
      }
      // Determine if the previewed widget is vertically constrained. If the
      // widget has a minimum intrinsic height of zero given the widget's max
      // width, it has an unconstrained height and will cause an overflow in
      // the previewer. In this case, apply finite constraints (e.g., the
      // constraints for the root of the previewer). Otherwise, use the
      // widget's actual constraints.
      _constraintOverride = minInstrinsicHeight == 0
          ? _previewerConstraints
          : const BoxConstraints();
    }
    super.layout(
      constraints,
      parentUsesSize: parentUsesSize,
    );
  }

  @override
  void performLayout() {
    final RenderBox? child = this.child;
    if (child == null) {
      size = Size.zero;
      return;
    }
    final BoxConstraints updatedConstraints =
        _constraintOverride.enforce(constraints);
    child.layout(
      updatedConstraints,
      parentUsesSize: true,
    );
    size = constraints.constrain(child.size);
  }
}
