// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'package:stack_trace/stack_trace.dart';

import 'controls.dart';
import 'generated_preview.dart';
import 'utils.dart';
import 'widget_preview.dart';

/// Displayed when an unhandled exception is thrown when initializing the widget
/// tree for a preview (i.e., before the build phase).
///
/// Provides users with details about the thrown exception, including the exception
/// contents and a scrollable stack trace.
class _WidgetPreviewErrorWidget extends StatelessWidget {
  _WidgetPreviewErrorWidget({
    required this.error,
    required StackTrace stackTrace,
    required this.size,
  }) : trace = Trace.from(stackTrace).terse;

  /// The [Object] that was thrown, resulting in an unhandled exception.
  final Object error;

  /// The stack trace identifying where [error] was thrown from.
  final Trace trace;

  /// The size of the error widget.
  final Size size;

  @override
  Widget build(BuildContext context) {
    final TextStyle boldStyle = fixBlurryText(
      TextStyle(fontWeight: FontWeight.bold),
    );

    return SizedBox(
      height: size.height,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text.rich(
              TextSpan(
                children: <TextSpan>[
                  TextSpan(
                    text: 'Failed to initialize widget tree: ',
                    style: boldStyle,
                  ),
                  // TODO(bkonyi): use monospace font
                  TextSpan(text: error.toString()),
                ],
              ),
            ),
            Text('Stacktrace:', style: boldStyle),
            // TODO(bkonyi): use monospace font
            SelectableText.rich(
              TextSpan(children: _formatFrames(trace.frames)),
            ),
          ],
        ),
      ),
    );
  }

  List<TextSpan> _formatFrames(List<Frame> frames) {
    // Figure out the longest path so we know how much to pad.
    final int longest = frames
        .map((frame) => frame.location.length)
        .fold(0, math.max);

    final TextStyle linkTextStyle = fixBlurryText(
      TextStyle(
        decoration: TextDecoration.underline,
        // TODO(bkonyi): this color scheme is from DevTools and should be responsive
        // to changes in the previewer theme.
        color: const Color(0xFF1976D2),
      ),
    );

    // Print out the stack trace nicely formatted.
    return frames.map<TextSpan>((frame) {
      if (frame is UnparsedFrame) return TextSpan(text: '$frame\n');
      return TextSpan(
        children: <TextSpan>[
          TextSpan(
            text: frame.location,
            style: linkTextStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                // TODO(bkonyi): notify IDEs to navigate to the source location via DTD.
              },
          ),
          TextSpan(text: ' ' * (longest - frame.location.length)),
          const TextSpan(text: '  '),
          TextSpan(text: '${frame.member}\n'),
        ],
      );
    }).toList();
  }
}

class WidgetPreviewWidget extends StatefulWidget {
  const WidgetPreviewWidget({super.key, required this.preview});

  final WidgetPreview preview;

  @override
  State<WidgetPreviewWidget> createState() => _WidgetPreviewWidgetState();
}

class _WidgetPreviewWidgetState extends State<WidgetPreviewWidget> {
  final transformationController = TransformationController();
  final deviceOrientation = ValueNotifier<Orientation>(Orientation.portrait);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final previewerConstraints =
        WidgetPreviewerWindowConstraints.getRootConstraints(context);

    final maxSizeConstraints = previewerConstraints.copyWith(
      minHeight: previewerConstraints.maxHeight / 2.0,
      maxHeight: previewerConstraints.maxHeight / 2.0,
    );

    bool errorThrownDuringTreeConstruction = false;
    Widget preview;
    // Catch any unhandled exceptions and display an error widget instead of taking
    // down the entire preview environment.
    try {
      preview = widget.preview.builder();
    } on Object catch (error, stackTrace) {
      errorThrownDuringTreeConstruction = true;
      preview = _WidgetPreviewErrorWidget(
        error: error,
        stackTrace: stackTrace,
        size: maxSizeConstraints.biggest,
      );
    }

    preview = _WidgetPreviewWrapper(
      previewerConstraints: maxSizeConstraints,
      child: SizedBox(
        width: widget.preview.width,
        height: widget.preview.height,
        child: preview,
      ),
    );

    preview = MediaQuery(data: _buildMediaQueryOverride(), child: preview);

    preview = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.preview.name != null) ...[
          Text(
            widget.preview.name!,
            style: fixBlurryText(
              TextStyle(fontSize: 16, fontWeight: FontWeight.w300),
            ),
          ),
          const VerticalSpacer(),
        ],
        InteractiveViewerWrapper(
          transformationController: transformationController,
          child: preview,
        ),
        const VerticalSpacer(),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ZoomControls(
              transformationController: transformationController,
              // If an unhandled exception was caught and we're displaying an error
              // widget, these controls should be disabled.
              enabled: !errorThrownDuringTreeConstruction,
            ),
          ],
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          child: preview,
        ),
      ),
    );
  }

  MediaQueryData _buildMediaQueryOverride() {
    var mediaQueryData = MediaQuery.of(context);

    if (widget.preview.textScaleFactor != null) {
      mediaQueryData = mediaQueryData.copyWith(
        textScaler: TextScaler.linear(widget.preview.textScaleFactor!),
      );
    }

    var size = Size(
      widget.preview.width ?? mediaQueryData.size.width,
      widget.preview.height ?? mediaQueryData.size.height,
    );

    if (widget.preview.width != null || widget.preview.height != null) {
      mediaQueryData = mediaQueryData.copyWith(size: size);
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
  const WidgetPreviewerWindowConstraints({
    super.key,
    required super.child,
    required this.constraints,
  });

  final BoxConstraints constraints;

  static BoxConstraints getRootConstraints(BuildContext context) {
    final result = context
        .dependOnInheritedWidgetOfExactType<WidgetPreviewerWindowConstraints>();
    assert(
      result != null,
      'No WidgetPreviewerWindowConstraints founds in context',
    );
    return result!.constraints;
  }

  @override
  bool updateShouldNotify(WidgetPreviewerWindowConstraints oldWidget) {
    return oldWidget.constraints != constraints;
  }
}

class InteractiveViewerWrapper extends StatelessWidget {
  const InteractiveViewerWrapper({
    super.key,
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

// TODO(bkonyi): according to goderbauer@, this probably isn't the best approach to ensure we
// handle unconstrained widgets. This should be reworked.
/// Wrapper applying a custom render object to force constraints on
/// unconstrained widgets.
class _WidgetPreviewWrapper extends SingleChildRenderObjectWidget {
  const _WidgetPreviewWrapper({
    super.child,
    required this.previewerConstraints,
  });

  /// The size of the previewer render surface.
  final BoxConstraints previewerConstraints;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _WidgetPreviewWrapperBox(
      previewerConstraints: previewerConstraints,
      child: null,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _WidgetPreviewWrapperBox renderObject,
  ) {
    renderObject.setPreviewerConstraints(previewerConstraints);
  }
}

/// Custom render box that forces constraints onto unconstrained widgets.
class _WidgetPreviewWrapperBox extends RenderShiftedBox {
  _WidgetPreviewWrapperBox({
    required RenderBox? child,
    required BoxConstraints previewerConstraints,
  }) : _previewerConstraints = previewerConstraints,
       super(child);

  BoxConstraints _constraintOverride = const BoxConstraints();
  BoxConstraints _previewerConstraints;

  void setPreviewerConstraints(BoxConstraints previewerConstraints) {
    if (_previewerConstraints == previewerConstraints) {
      return;
    }
    _previewerConstraints = previewerConstraints;
    markNeedsLayout();
  }

  @override
  void layout(Constraints constraints, {bool parentUsesSize = false}) {
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
    super.layout(constraints, parentUsesSize: parentUsesSize);
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = Size.zero;
      return;
    }
    final updatedConstraints = _constraintOverride.enforce(constraints);
    child.layout(updatedConstraints, parentUsesSize: true);
    size = constraints.constrain(child.size);
  }
}

/// Custom [AssetBundle] used to map original asset paths from the parent
/// project to those in the preview project.
class PreviewAssetBundle extends PlatformAssetBundle {
  // Assets shipped via package dependencies have paths that start with
  // 'packages'.
  static const String _kPackagesPrefix = 'packages';

  @override
  Future<ByteData> load(String key) {
    // These assets are always present or are shipped via a package and aren't
    // actually located in the parent project, meaning their paths did not need
    // to be modified.
    if (key == 'AssetManifest.bin' ||
        key == 'AssetManifest.json' ||
        key == 'FontManifest.json' ||
        key.startsWith(_kPackagesPrefix)) {
      return super.load(key);
    }
    // Other assets are from the parent project. Map their keys to those found
    // in the pubspec.yaml of the preview envirnment.
    return super.load('../../$key');
  }

  @override
  Future<ImmutableBuffer> loadBuffer(String key) async {
    if (kIsWeb) {
      final ByteData bytes = await load(key);
      return ImmutableBuffer.fromUint8List(Uint8List.sublistView(bytes));
    }
    return await ImmutableBuffer.fromAsset(
      key.startsWith(_kPackagesPrefix) ? key : '../../$key',
    );
  }
}

/// Main entrypoint for the widget previewer.
///
/// We don't actually define this as `main` to avoid copying this file into
/// the preview scaffold project which prevents us from being able to use hot
/// restart to iterate on this file.
Future<void> mainImpl() async {
  runApp(_WidgetPreviewScaffold());
}

/// Define the Enum for Layout Types
enum LayoutType { gridView, listView }

class _WidgetPreviewScaffold extends StatelessWidget {
  // Positioning values for positioning the previewer
  final double _previewLeftPadding = 60.0;
  final double _previewRightPadding = 20.0;

  // Positioning values for the toggle layout buttons
  final double _toggleButtonsTopPadding = 20.0;
  final double _toggleButtonsLeftPadding = 20.0;

  // Spacing values for the grid layout
  final double _gridSpacing = 8.0;
  final double _gridRunSpacing = 8.0;

  // Notifier to manage layout state, default to GridView
  final ValueNotifier<LayoutType> _selectedLayout = ValueNotifier<LayoutType>(
    LayoutType.gridView,
  );

  // Function to toggle layouts based on enum value
  void _toggleLayout(LayoutType layout) {
    _selectedLayout.value = layout;
  }

  Widget _buildGridViewFlex(List<WidgetPreview> previewList) {
    return SingleChildScrollView(
      child: Wrap(
        spacing: _gridSpacing,
        runSpacing: _gridRunSpacing,
        alignment: WrapAlignment.start,
        children: <Widget>[
          for (final WidgetPreview preview in previewList)
            WidgetPreviewWidget(preview: preview),
        ],
      ),
    );
  }

  Widget _buildVerticalListView(List<WidgetPreview> previewList) {
    return ListView.builder(
      itemCount: previewList.length,
      itemBuilder: (context, index) {
        final preview = previewList[index];
        return Center(child: WidgetPreviewWidget(preview: preview));
      },
    );
  }

  Widget _displayToggleLayoutButtons() {
    return Positioned(
      top: _toggleButtonsTopPadding,
      left: _toggleButtonsLeftPadding,
      child: Container(
        padding: EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          children: [
            ValueListenableBuilder<LayoutType>(
              valueListenable: _selectedLayout,
              builder: (context, selectedLayout, _) {
                return Column(
                  children: [
                    IconButton(
                      onPressed: () => _toggleLayout(LayoutType.gridView),
                      icon: Icon(Icons.grid_on),
                      color: selectedLayout == LayoutType.gridView
                          ? Colors.blue
                          : Colors.black,
                    ),
                    IconButton(
                      onPressed: () => _toggleLayout(LayoutType.listView),
                      icon: Icon(Icons.view_list),
                      color: selectedLayout == LayoutType.listView
                          ? Colors.blue
                          : Colors.black,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _displayPreviewer(Widget previewView) {
    return Positioned.fill(
      left: _previewLeftPadding,
      right: _previewRightPadding,
      child: Container(padding: EdgeInsets.all(8.0), child: previewView),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<WidgetPreview> previewList = previews();
    Widget previewView;
    if (previewList.isEmpty) {
      previewView = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Center(
            // TODO: consider including details on how to get started
            // with Widget Previews.
            child: Text(
              'No previews available',
              style: fixBlurryText(TextStyle(color: Colors.white)),
            ),
          ),
        ],
      );
    } else {
      previewView = LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return WidgetPreviewerWindowConstraints(
            constraints: constraints,
            child: ValueListenableBuilder<LayoutType>(
              valueListenable: _selectedLayout,
              builder: (context, selectedLayout, _) {
                return switch (selectedLayout) {
                  LayoutType.gridView => _buildGridViewFlex(previewList),
                  LayoutType.listView => _buildVerticalListView(previewList),
                };
              },
            ),
          );
        },
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Material(
        color: Colors.transparent,
        child: DefaultAssetBundle(
          bundle: PreviewAssetBundle(),
          child: Stack(
            children: [
              // Display the previewer
              _displayPreviewer(previewView),
              // Display the layout toggle buttons
              _displayToggleLayoutButtons(),
            ],
          ),
        ),
      ),
    );
  }
}
