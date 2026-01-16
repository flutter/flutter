// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';

import 'package:stack_trace/stack_trace.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:widget_preview_scaffold/src/dtd/editor_service.dart';
import 'package:widget_preview_scaffold/src/split.dart';
import 'package:widget_preview_scaffold/src/theme/ide_theme.dart';
import 'package:widget_preview_scaffold/src/theme/theme.dart';

import 'package:widget_preview_scaffold/src/controls.dart';
import 'package:widget_preview_scaffold/src/generated_preview.dart';
import 'package:widget_preview_scaffold/src/utils.dart';
import 'package:widget_preview_scaffold/src/widget_preview.dart';
import 'package:widget_preview_scaffold/src/widget_preview_inspector_service.dart';
import 'package:widget_preview_scaffold/src/widget_preview_scaffold_controller.dart';

/// Displayed when an unhandled exception is thrown when initializing the widget
/// tree for a preview (i.e., before the build phase).
///
/// Provides users with details about the thrown exception, including the exception
/// contents and a scrollable stack trace.
class WidgetPreviewErrorWidget extends StatelessWidget {
  WidgetPreviewErrorWidget({
    super.key,
    required this.controller,
    required this.error,
    required StackTrace stackTrace,
    required this.size,
  }) : trace = Trace.from(stackTrace).terse;

  final WidgetPreviewScaffoldController controller;

  /// The [Object] that was thrown, resulting in an unhandled exception.
  final Object error;

  /// The stack trace identifying where [error] was thrown from.
  final Trace trace;

  /// The size of the error widget.
  final Size size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: size.height,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Failed to initialize widget tree: ',
                    style: theme.boldTextStyle,
                  ),
                  TextSpan(text: error.toString(), style: theme.fixedFontStyle),
                ],
              ),
            ),
            Text('Stacktrace:', style: theme.boldTextStyle),
            ValueListenableBuilder(
              valueListenable: controller.editorServiceAvailable,
              builder: (context, editorServiceAvailable, child) {
                return SelectableText.rich(
                  TextSpan(
                    children: _formatFrames(
                      theme,
                      trace.frames,
                      editorServiceAvailable,
                    ),
                    style: theme.fixedFontStyle,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<TextSpan> _formatFrames(
    ThemeData theme,
    List<Frame> frames,
    bool editorServiceAvailable,
  ) {
    // Figure out the longest path so we know how much to pad.
    final int longest = frames
        .map((frame) => frame.location.length)
        .fold(0, math.max);

    // Print out the stack trace nicely formatted.
    return frames.map<TextSpan>((frame) {
      if (frame is UnparsedFrame) return TextSpan(text: '$frame\n');
      // The Editor.navigateToCode service can't handle Dart core library paths,
      // so don't allow for navigation to them. Also disable navigation if the
      // Editor service isn't available.
      final isLinkable =
          (frame.uri.isScheme('file') || frame.uri.isScheme('package')) &&
          editorServiceAvailable;
      final style = isLinkable
          ? theme.fixedFontLinkStyle
          : theme.fixedFontStyle;
      return TextSpan(
        children: [
          TextSpan(
            text: frame.location,
            style: style,
            recognizer: isLinkable
                ? (TapGestureRecognizer()
                    ..onTap = () async {
                      final resolvedUri = await controller.dtdServices
                          .resolveUri(frame.uri);
                      controller.dtdServices.navigateToCode(
                        CodeLocation(
                          uri: resolvedUri.toString(),
                          line: frame.line,
                          column: frame.column,
                        ),
                      );
                    })
                : null,
          ),
          TextSpan(text: ' ' * (longest - frame.location.length)),
          const TextSpan(text: '  '),
          TextSpan(text: '${frame.member}\n', style: style),
        ],
      );
    }).toList();
  }
}

/// Displayed when no @Preview() annotations are detected in the project.
///
/// Links to documentation.
class NoPreviewsDetectedWidget extends StatelessWidget {
  const NoPreviewsDetectedWidget({super.key});

  static Uri documentationUrl = Uri.https('flutter.dev', 'to/widget-previews');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        children: [
          Text('No previews detected', style: theme.boldTextStyle),
          const VerticalSpacer(),
          Text('Read more about getting started with widget previews at:'),
          Text.rich(
            TextSpan(
              text: documentationUrl.toString(),
              style: theme.linkTextStyle,
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  launchUrl(documentationUrl);
                },
            ),
          ),
        ],
      ),
    );
  }
}

/// A wrapper that serves as the root entry for a single preview in the widget inspector.
class PreviewWidget extends StatelessWidget {
  const PreviewWidget({super.key, required this.preview, required this.child});

  final WidgetPreview preview;
  final Widget child;

  @override
  StatelessElement createElement() => PreviewWidgetElement(this);

  @override
  Widget build(BuildContext context) {
    return child;
  }

  @override
  String toStringShort() {
    final StringBuffer buffer = StringBuffer(
      '@${preview.previewData.runtimeType}',
    );
    if (preview.name != null) {
      buffer.write('(name: "${preview.name}")');
    }
    return buffer.toString();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    preview.debugFillProperties(properties);
  }
}

/// A custom [StatelessElement] with the sole purpose of simplifying identifying
/// selections of @Preview annotations in the widget inspector.
class PreviewWidgetElement extends StatelessElement {
  PreviewWidgetElement(super.widget);
}

class WidgetPreviewGroupWidget extends StatelessWidget {
  const WidgetPreviewGroupWidget({
    super.key,
    required this.controller,
    required this.group,
  });

  final WidgetPreviewScaffoldController controller;
  final WidgetPreviewGroup group;

  // Spacing values for the grid layout
  static const _gridSpacing = 8.0;
  static const _gridRunSpacing = 8.0;

  /// The default radius of a Material 3 `Card`, as per documentation for `Card.shape`.
  // TODO(bkonyi): inherit this from the theme.
  static const _kCardRadius = Radius.circular(12);

  Widget _buildGridViewFlex(List<WidgetPreview> previews) {
    return Wrap(
      spacing: WidgetPreviewGroupWidget._gridSpacing,
      runSpacing: WidgetPreviewGroupWidget._gridRunSpacing,
      alignment: WrapAlignment.start,
      children: [
        for (final WidgetPreview preview in previews)
          WidgetPreviewWidget(controller: controller, preview: preview),
      ],
    );
  }

  Widget _buildVerticalListView(List<WidgetPreview> previews) {
    return Column(
      children: [
        for (final preview in previews)
          Center(
            child: WidgetPreviewWidget(
              controller: controller,
              preview: preview,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTileTheme(
        data: ListTileTheme.of(context).copyWith(
          dense: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(_kCardRadius),
          ),
        ),
        child: Theme(
          // Prevents divider lines appearing at the top and bottom of the
          // expanded ExpansionTile.
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: PageStorageKey(group.name),
            title: Text(group.name),
            initiallyExpanded: true,
            children: [
              ValueListenableBuilder<LayoutType>(
                valueListenable: controller.layoutTypeListenable,
                builder: (context, selectedLayout, _) {
                  return switch (selectedLayout) {
                    LayoutType.gridView => _buildGridViewFlex(group.previews),
                    LayoutType.listView => _buildVerticalListView(
                      group.previews,
                    ),
                  };
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WidgetPreviewWidget extends StatefulWidget {
  const WidgetPreviewWidget({
    super.key,
    required this.preview,
    required this.controller,
  });

  final WidgetPreview preview;

  final WidgetPreviewScaffoldController controller;

  @override
  State<WidgetPreviewWidget> createState() => WidgetPreviewWidgetState();
}

class WidgetPreviewWidgetState extends State<WidgetPreviewWidget> {
  final transformationController = TransformationController();

  // Set the initial preview brightness based on the platform default or the
  // value explicitly specified for the preview.
  late final brightnessListenable = ValueNotifier<Brightness>(
    widget.preview.brightness ?? MediaQuery.platformBrightnessOf(context),
  );

  final softRestartListenable = ValueNotifier<bool>(false);
  final key = GlobalKey();

  /// Returns the last size of the previewed widget.
  Size get lastChildSize =>
      (key.currentContext!.findRenderObject() as RenderBox).size;

  @override
  void didUpdateWidget(WidgetPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final previousBrightness = oldWidget.preview.brightness;
    final newBrightness = widget.preview.brightness;
    final currentBrightness = brightnessListenable.value;
    final systemBrightness = MediaQuery.platformBrightnessOf(context);

    // No initial brightness was previously defined.
    if (previousBrightness == null && newBrightness != null) {
      if (currentBrightness == systemBrightness) {
        // If the current brightness is different than the system brightness, the user has manually
        // changed the brightness through the UI, so don't change it automatically.
        brightnessListenable.value = newBrightness;
      }
    }
    // Changing the initial brightness to either a new initial brightness or system brightness.
    else if (previousBrightness != null) {
      // If the current brightness is different than the initial brightness, the user has manually
      // changed the brightness through the UI, so don't change it automatically.
      if (currentBrightness == previousBrightness) {
        brightnessListenable.value = newBrightness ?? systemBrightness;
      }
    }
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

    // Wrap the previewed widget with a ValueListenableBuilder responsible for performing a "soft"
    // restart.
    //
    // A soft restart simply removes the previewed widget from the widget tree for a frame before
    // re-inserting it on the next frame. This has the effect of re-running local initializers in
    // State objects, which normally requires a hot restart to accomplish in a normal application.
    Widget preview = ValueListenableBuilder<bool>(
      valueListenable: softRestartListenable,
      builder: (context, performRestart, _) {
        try {
          final previewWidget = Container(
            key: key,
            child: WidgetPreviewTheming(
              theme: widget.preview.theme,
              child: EnableWidgetInspectorScope(
                child: PreviewWidget(
                  preview: widget.preview,
                  child: widget.preview.previewBuilder(),
                ),
              ),
            ),
          );
          if (performRestart) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Trigger a rebuild on the next frame to re-insert previewWidget.
              softRestartListenable.value = false;
            }, debugLabel: 'Soft Restart');
            return SizedBox.fromSize(size: lastChildSize);
          }
          return previewWidget;
        } on Object catch (error, stackTrace) {
          // Catch any unhandled exceptions and display an error widget instead of taking
          // down the entire preview environment.
          errorThrownDuringTreeConstruction = true;
          return WidgetPreviewErrorWidget(
            controller: widget.controller,
            error: error,
            stackTrace: stackTrace,
            size: maxSizeConstraints.biggest,
          );
        }
      },
    );

    final Size? size = widget.preview.size;

    // Add support for selecting only previewed widgets via the widget
    // inspector.
    preview = ValueListenableBuilder(
      valueListenable:
          WidgetsBinding.instance.debugShowWidgetInspectorOverrideNotifier,
      builder: (context, enableWidgetInspector, child) {
        // Don't allow inspecting the error widget.
        if (child is WidgetPreviewErrorWidget) {
          return child;
        }
        if (enableWidgetInspector) {
          return WidgetInspector(
            // TODO(bkonyi): wire up inspector controls for individual previews or
            // the entire preview environment. This currently requires users to
            // to enable widget selection via the Widget Inspector tool in DevTools.

            // These buttons would be rendered on top of the previewed widget, so
            // don't display them.
            exitWidgetSelectionButtonBuilder: null,
            moveExitWidgetSelectionButtonBuilder: null,
            tapBehaviorButtonBuilder: null,
            child: child!,
          );
        }
        return child!;
      },
      child: _WidgetPreviewWrapper(
        previewerConstraints: maxSizeConstraints,
        child: SizedBox(
          width: size?.width == double.infinity ? null : size?.width,
          height: size?.height == double.infinity ? null : size?.height,
          child: preview,
        ),
      ),
    );

    preview = WidgetPreviewMediaQueryOverride(
      preview: widget.preview,
      brightnessListenable: brightnessListenable,
      child: preview,
    );

    preview = WidgetPreviewLocalizations(
      localizationsData: widget.preview.localizations,
      child: preview,
    );

    // Override the asset resolution behavior to automatically insert
    // 'packages/$packageName/` in front of non-package paths as some previews
    // may reference assets that are within the current project and wouldn't
    // normally require a package specifier.
    // TODO(bkonyi): this doesn't modify the behavior of asset loading logic in
    // the engine implementation. This means that any asset loading done by
    // APIs provided in dart:ui won't work correctly for non-package asset
    // paths (e.g., shaders loaded by `FragmentProgram.fromAsset()`).
    //
    // See https://github.com/flutter/flutter/issues/171284
    preview = DefaultAssetBundle(
      bundle: PreviewAssetBundle(packageName: widget.preview.packageName),
      child: preview,
    );

    final hasName = widget.preview.name != null;
    preview = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (hasName)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              widget.preview.name!,
              style: fixBlurryText(
                TextStyle(fontSize: 16, fontWeight: FontWeight.w300),
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(
            // TODO(bkonyi): use theming or define global constants.
            horizontal: 16.0,
          ).add(hasName ? const EdgeInsets.only(top: 8.0) : EdgeInsets.zero),
          decoration: hasName
              ? BoxDecoration(
                  border: Border(top: Divider.createBorderSide(context)),
                )
              : null,
          child: Column(
            children: [
              InteractiveViewerWrapper(
                transformationController: transformationController,
                child: preview,
              ),
              const VerticalSpacer(),
              Builder(
                builder: (context) {
                  return _WidgetPreviewControlRow(
                    transformationController: transformationController,
                    errorThrownDuringTreeConstruction:
                        errorThrownDuringTreeConstruction,
                    brightnessListenable: brightnessListenable,
                    softRestartListenable: softRestartListenable,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card.outlined(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: preview,
        ),
      ),
    );
  }
}

class _WidgetPreviewControlRow extends StatelessWidget {
  const _WidgetPreviewControlRow({
    required this.transformationController,
    required this.errorThrownDuringTreeConstruction,
    required this.brightnessListenable,
    required this.softRestartListenable,
  });

  final TransformationController transformationController;
  final bool errorThrownDuringTreeConstruction;
  final ValueNotifier<Brightness> brightnessListenable;
  final ValueNotifier<bool> softRestartListenable;

  @override
  Widget build(BuildContext context) {
    // Don't show controls if an error occurred.
    if (errorThrownDuringTreeConstruction) {
      return Container();
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      // If an unhandled exception was caught and we're displaying an error
      // widget, these controls should be disabled.
      // TODO(bkonyi): improve layout of controls.
      children: [
        ZoomControls(transformationController: transformationController),
        const SizedBox(width: 30),
        BrightnessToggleButton(brightnessListenable: brightnessListenable),
        const SizedBox(width: 10),
        SoftRestartButton(softRestartListenable: softRestartListenable),
      ],
    );
  }
}

/// Applies theming defined in [theme] to [child].
class WidgetPreviewTheming extends StatelessWidget {
  const WidgetPreviewTheming({
    super.key,
    required this.theme,
    required this.child,
  });

  final Widget child;

  /// The set of themes to be applied to [child].
  final PreviewThemeData? theme;

  @override
  Widget build(BuildContext context) {
    final themeData = theme;
    if (themeData == null) {
      return child;
    }
    final (materialTheme, cupertinoTheme) = themeData.themeForBrightness(
      MediaQuery.platformBrightnessOf(context),
    );
    Widget result = child;
    if (materialTheme != null) {
      result = Theme(data: materialTheme, child: result);
    }
    if (cupertinoTheme != null) {
      result = CupertinoTheme(data: cupertinoTheme, child: result);
    }
    return result;
  }
}

/// Wraps the previewed [child] with the correct [MediaQueryData] overrides
/// based on [preview] and the current device [Brightness].
class WidgetPreviewMediaQueryOverride extends StatelessWidget {
  const WidgetPreviewMediaQueryOverride({
    super.key,
    required this.preview,
    required this.brightnessListenable,
    required this.child,
  });

  /// The preview specification used to render the preview.
  final WidgetPreview preview;

  /// The currently set brightness for this preview instance.
  final ValueListenable<Brightness> brightnessListenable;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Brightness>(
      valueListenable: brightnessListenable,
      builder: (context, brightness, _) {
        return MediaQuery(
          data: _buildMediaQueryOverride(
            context: context,
            brightness: brightness,
          ),
          // Use mediaQueryPreview instead of preview to avoid capturing preview
          // and creating an infinite loop.
          child: child,
        );
      },
    );
  }

  MediaQueryData _buildMediaQueryOverride({
    required BuildContext context,
    required Brightness brightness,
  }) {
    var mediaQueryData = MediaQuery.of(
      context,
    ).copyWith(platformBrightness: brightness);

    if (preview.textScaleFactor != null) {
      mediaQueryData = mediaQueryData.copyWith(
        textScaler: TextScaler.linear(preview.textScaleFactor!),
      );
    }

    var size = Size(
      preview.size?.width ?? mediaQueryData.size.width,
      preview.size?.height ?? mediaQueryData.size.height,
    );

    if (preview.size != null) {
      mediaQueryData = mediaQueryData.copyWith(size: size);
    }

    return mediaQueryData;
  }
}

/// Wraps [child] with a [Localizations] with localization data from
/// [localizationsData].
class WidgetPreviewLocalizations extends StatefulWidget {
  const WidgetPreviewLocalizations({
    super.key,
    required this.localizationsData,
    required this.child,
  });

  final PreviewLocalizationsData? localizationsData;
  final Widget child;

  @override
  State<WidgetPreviewLocalizations> createState() =>
      _WidgetPreviewLocalizationsState();
}

class _WidgetPreviewLocalizationsState
    extends State<WidgetPreviewLocalizations> {
  PreviewLocalizationsData get _localizationsData => widget.localizationsData!;
  late final LocalizationsResolver _localizationsResolver =
      LocalizationsResolver(
        supportedLocales: _localizationsData.supportedLocales,
        locale: _localizationsData.locale,
        localeListResolutionCallback:
            _localizationsData.localeListResolutionCallback,
        localeResolutionCallback: _localizationsData.localeResolutionCallback,
        localizationsDelegates: _localizationsData.localizationsDelegates,
      );

  @override
  void didUpdateWidget(WidgetPreviewLocalizations oldWidget) {
    super.didUpdateWidget(oldWidget);
    final PreviewLocalizationsData? localizationsData =
        widget.localizationsData;
    if (localizationsData == null) {
      return;
    }
    _localizationsResolver.update(
      supportedLocales: localizationsData.supportedLocales,
      locale: localizationsData.locale,
      localeListResolutionCallback:
          localizationsData.localeListResolutionCallback,
      localeResolutionCallback: localizationsData.localeResolutionCallback,
      localizationsDelegates: localizationsData.localizationsDelegates,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.localizationsData == null) {
      return widget.child;
    }
    return ListenableBuilder(
      listenable: _localizationsResolver,
      builder: (context, _) {
        return Localizations(
          locale: _localizationsResolver.locale,
          delegates: _localizationsResolver.localizationsDelegates.toList(),
          child: widget.child,
        );
      },
    );
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
/// projects to those in the preview project.
class PreviewAssetBundle extends PlatformAssetBundle {
  PreviewAssetBundle({required this.packageName});

  /// The name of the package in which a preview was defined.
  ///
  /// For example, if a preview is defined in 'package:foo/src/bar.dart', this
  /// will have the value 'foo'.
  ///
  /// This should only be null if the preview is defined in a file that's not
  /// part of a Flutter library (e.g., is defined in a test).
  // TODO(bkonyi): verify what the behavior should be in this scenario.
  final String? packageName;

  // Assets shipped via package dependencies have paths that start with
  // 'packages'.
  static const String _kPackagesPrefix = 'packages';

  // TODO(bkonyi): when loading an invalid asset path that doesn't start with
  // 'packages', this throws a FlutterError referencing the modified key
  // instead of the original. We should catch the error and rethrow one with
  // the original key in the error message.
  @override
  Future<ByteData> load(String key) {
    // These assets are always present or are shipped via a package and aren't
    // actually located in the parent project, meaning their paths did not need
    // to be modified.
    if (key == 'AssetManifest.bin' ||
        key == 'AssetManifest.bin.json' ||
        key == 'FontManifest.json' ||
        key.startsWith(_kPackagesPrefix) ||
        packageName == null) {
      return super.load(key);
    }
    // Other assets are from the parent project. Map their keys to package
    // paths corresponding to the package containing the preview.
    return super.load(_toPackagePath(key));
  }

  @override
  Future<ImmutableBuffer> loadBuffer(String key) async {
    if (kIsWeb) {
      final ByteData bytes = await load(key);
      return ImmutableBuffer.fromUint8List(Uint8List.sublistView(bytes));
    }
    return await ImmutableBuffer.fromAsset(
      key.startsWith(_kPackagesPrefix) ? key : _toPackagePath(key),
    );
  }

  String _toPackagePath(String key) => '$_kPackagesPrefix/$packageName/$key';
}

/// Main entrypoint for the widget previewer.
///
/// We don't actually define this as `main` to avoid copying this file into
/// the preview scaffold project which prevents us from being able to use hot
/// restart to iterate on this file.
Future<void> mainImpl() async {
  final controller = WidgetPreviewScaffoldController(previews: previews);
  await controller.initialize();
  // WARNING: do not move this line. This constructor sets
  // [WidgetInspectorService.instance] to the custom service for the widget
  // previewer. If [WidgetsFlutterBinding.ensureInitialized()] is invoked before
  // the custom service is set, inspector service extensions will be registered
  // against the wrong service.
  WidgetPreviewScaffoldInspectorService(dtdServices: controller.dtdServices);
  final WidgetsBinding binding = WidgetsFlutterBinding.ensureInitialized();
  // Disable the injection of [WidgetInspector] into the widget tree built by
  // [WidgetsApp]. [WidgetInspector] instances will be created for each
  // individual preview so the widget inspector won't allow for users to select
  // widgets that make up the widget preview scaffolding.
  binding.debugExcludeRootWidgetInspector = true;
  runWidget(
    DisableWidgetInspectorScope(
      child: binding.wrapWithDefaultView(
        // Forces the set of previews to be recalculated after a hot reload.
        HotReloadListener(
          onHotReload: controller.onHotReload,
          child: WidgetPreviewScaffold(
            controller: controller,
            ideTheme: getIdeTheme(),
          ),
        ),
      ),
    ),
  );
}

class WidgetPreviewScaffold extends StatefulWidget {
  const WidgetPreviewScaffold({
    super.key,
    required this.controller,
    this.ideTheme = const IdeTheme(),
    this.enableWebView = true,
  });

  final WidgetPreviewScaffoldController controller;
  final IdeTheme ideTheme;
  final bool enableWebView;

  @override
  State<WidgetPreviewScaffold> createState() => _WidgetPreviewScaffoldState();
}

class _WidgetPreviewScaffoldState extends State<WidgetPreviewScaffold> {
  WebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    if (widget.enableWebView) {
      _webViewController = WebViewController()
        ..loadRequest(widget.controller.devToolsUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: themeFor(
        isDarkTheme: false,
        ideTheme: widget.ideTheme,
        theme: ThemeData(),
      ),
      darkTheme: themeFor(
        isDarkTheme: true,
        ideTheme: widget.ideTheme,
        theme: ThemeData.dark(),
      ),
      themeMode: widget.ideTheme.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: Material(
        child: OutlineDecoration.onlyTop(
          child: ValueListenableBuilder(
            valueListenable: widget.controller.widgetInspectorVisible,
            builder: (context, widgetInspectorVisible, previewView) {
              if (!widgetInspectorVisible) {
                return previewView!;
              }
              return SplitPane(
                axis: Axis.horizontal,
                initialFractions: const [0.7, 0.3],
                children: [
                  OutlineDecoration.onlyRight(child: previewView!),
                  OutlineDecoration.onlyLeft(
                    child: widget.enableWebView
                        ? WebViewWidget(controller: _webViewController!)
                        : Container(),
                  ),
                ],
              );
            },
            // Display the previewer
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    child: WidgetPreviews(controller: widget.controller),
                  ),
                ),
                WidgetPreviewControls(controller: widget.controller),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The set of controls used to control the preview environment.
class WidgetPreviewControls extends StatelessWidget {
  const WidgetPreviewControls({super.key, required this.controller});

  static const _controlsPadding = 20.0;
  final WidgetPreviewScaffoldController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: _controlsPadding,
        left: _controlsPadding,
        right: _controlsPadding,
      ),
      child: Row(
        children: [
          LayoutTypeSelector(controller: controller),
          ValueListenableBuilder(
            valueListenable: controller.editorServiceAvailable,
            builder: (context, editorServiceAvailable, _) {
              if (!editorServiceAvailable) {
                return Container();
              }
              return Row(
                children: [
                  HorizontalSpacer(),
                  FilterBySelectedFileToggle(controller: controller),
                ],
              );
            },
          ),
          HorizontalSpacer(),
          WidgetInspectorToggle(controller: controller),
          Spacer(),
          WidgetPreviewerRestartButton(controller: controller),
        ],
      ),
    );
  }
}

/// Renders the set of currently selected widget previews.
class WidgetPreviews extends StatelessWidget {
  const WidgetPreviews({super.key, required this.controller});

  final WidgetPreviewScaffoldController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<WidgetPreviewGroups>(
      valueListenable: controller.filteredPreviewSetListenable,
      builder: (context, previewGroups, _) {
        if (previewGroups.isEmpty) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [NoPreviewsDetectedWidget()],
          );
        }
        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final previewGroupsList = previewGroups.toList();
            return WidgetPreviewerWindowConstraints(
              constraints: constraints,
              child: ListView.builder(
                itemCount: previewGroups.length,
                itemBuilder: (context, index) {
                  return WidgetPreviewGroupWidget(
                    controller: controller,
                    group: previewGroupsList[index],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
