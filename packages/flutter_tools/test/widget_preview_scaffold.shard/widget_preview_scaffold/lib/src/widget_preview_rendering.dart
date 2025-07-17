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
import 'package:google_fonts/google_fonts.dart';

import 'package:stack_trace/stack_trace.dart';
import 'package:url_launcher/url_launcher.dart';

import 'controls.dart';
import 'dtd/dtd_services.dart';
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
    final TextStyle monospaceStyle = GoogleFonts.robotoMono();

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
                  TextSpan(text: error.toString(), style: monospaceStyle),
                ],
              ),
            ),
            Text('Stacktrace:', style: boldStyle),
            SelectableText.rich(
              TextSpan(
                children: _formatFrames(trace.frames),
                style: monospaceStyle,
              ),
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

/// Displayed when no @Preview() annotations are detected in the project.
///
/// Links to documentation.
class NoPreviewsDetectedWidget extends StatelessWidget {
  const NoPreviewsDetectedWidget({super.key});

  // TODO(bkonyi): update with actual documentation on flutter.dev.
  static Uri documentationUrl = Uri.https(
    'github.com',
    'flutter/flutter/blob/master/packages/flutter/'
        'lib/src/widget_previews/widget_previews.dart',
  );

  @override
  Widget build(BuildContext context) {
    // TODO(bkonyi): base this on the current color theme (dark vs light)
    final style = fixBlurryText(TextStyle(color: Colors.black));
    return Center(
      child: Column(
        children: <Widget>[
          Text(
            'No previews detected',
            style: style.copyWith(fontWeight: FontWeight.bold),
          ),
          const VerticalSpacer(),
          Text('Read more about getting started with widget previews at:'),
          Text.rich(
            TextSpan(
              text: documentationUrl.toString(),
              style: linkTextStyle,
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  launchUrl(documentationUrl);
                },
            ),
            style: style,
          ),
        ],
      ),
    );
  }
}

class Preview extends StatelessWidget {
  const Preview({super.key, required this.preview, required this.child});

  final WidgetPreview preview;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }

  @override
  String toStringShort() {
    final StringBuffer buffer = StringBuffer('@Preview');
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

class WidgetPreviewWidget extends StatefulWidget {
  const WidgetPreviewWidget({super.key, required this.preview});

  final WidgetPreview preview;

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
                child: Preview(
                  preview: widget.preview,
                  child: widget.preview.builder(),
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
          return _WidgetPreviewErrorWidget(
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
          // If an unhandled exception was caught and we're displaying an error
          // widget, these controls should be disabled.
          // TODO(bkonyi): improve layout of controls.
          children: [
            ZoomControls(
              transformationController: transformationController,
              enabled: !errorThrownDuringTreeConstruction,
            ),
            const SizedBox(width: 30),
            BrightnessToggleButton(
              enabled: !errorThrownDuringTreeConstruction,
              brightnessListenable: brightnessListenable,
            ),
            const SizedBox(width: 10),
            SoftRestartButton(
              enabled: !errorThrownDuringTreeConstruction,
              softRestartListenable: softRestartListenable,
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
        key == 'AssetManifest.json' ||
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
  final WidgetsBinding binding = WidgetsFlutterBinding.ensureInitialized();
  // Disable the injection of [WidgetInspector] into the widget tree built by
  // [WidgetsApp]. [WidgetInspector] instances will be created for each
  // individual preview so the widget inspector won't allow for users to select
  // widgets that make up the widget preview scaffolding.
  binding.debugExcludeRootWidgetInspector = true;
  final WidgetPreviewScaffoldDtdServices dtdServices =
      WidgetPreviewScaffoldDtdServices();
  await dtdServices.connect();
  runWidget(
    DisableWidgetInspectorScope(
      child: binding.wrapWithDefaultView(
        WidgetPreviewScaffold(previews: previews, dtdServices: dtdServices),
      ),
    ),
  );
}

/// Define the Enum for Layout Types
enum LayoutType { gridView, listView }

class WidgetPreviewScaffold extends StatelessWidget {
  WidgetPreviewScaffold({
    super.key,
    required this.previews,
    required this.dtdServices,
  });

  final List<WidgetPreview> Function() previews;
  final WidgetPreviewScaffoldDtdServices dtdServices;

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
        child: ValueListenableBuilder<LayoutType>(
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
      ),
    );
  }

  Widget _hotRestartPreviewerButton() {
    return Container(
      alignment: Alignment.topRight,
      padding: EdgeInsets.only(
        top: _toggleButtonsTopPadding,
        right: _toggleButtonsLeftPadding,
      ),
      child: WidgetPreviewerRestartButton(dtdServices: dtdServices),
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
        children: <Widget>[NoPreviewsDetectedWidget()],
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
        child: Stack(
          children: [
            // Display the previewer
            _displayPreviewer(previewView),
            // Display the layout toggle buttons
            _displayToggleLayoutButtons(),
            // Display the global hot restart button
            _hotRestartPreviewerButton(),
          ],
        ),
      ),
    );
  }
}
