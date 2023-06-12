import 'dart:async';

import 'package:device_frame/device_frame.dart';
import 'package:device_preview/src/state/state.dart';
import 'package:device_preview/src/state/store.dart';
import 'package:device_preview/src/storage/storage.dart';
import 'package:device_preview/src/utilities/assert_inherited_media_query.dart';
import 'package:device_preview/src/utilities/media_query_observer.dart';
import 'package:device_preview/src/views/theme.dart';
import 'package:device_preview/src/views/tool_panel/sections/accessibility.dart';
import 'package:device_preview/src/views/tool_panel/sections/device.dart';
import 'package:device_preview/src/views/tool_panel/sections/settings.dart';
import 'package:device_preview/src/views/tool_panel/sections/system.dart';
import 'package:device_preview/src/views/tool_panel/tool_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;

import 'locales/default_locales.dart';
import 'utilities/screenshot.dart';
import 'views/large.dart';
import 'views/small.dart';

/// Simulates how the result of [builder] would render on different
/// devices.
///
/// {@tool snippet}
///
/// This sample shows how to define an app with a plugin.
///
/// ```dart
/// DevicePreview(
///   builder: (context) => MaterialApp(
///      useInheritedMediaQuery: true,
///      locale: DevicePreview.locale(context),
///      builder: DevicePreview.appBuilder,
///      theme: ThemeData.light(),
///      darkTheme: ThemeData.dark(),
///      home: const Home(),
///    ),
/// )
/// ```
/// {@end-tool}
///
/// See also :
/// * [Devices] has a set of predefined common devices.
class DevicePreview extends StatefulWidget {
  /// Create a new [DevicePreview].
  const DevicePreview({
    Key? key,
    required this.builder,
    this.devices,
    this.data,
    this.isToolbarVisible = true,
    this.availableLocales,
    this.defaultDevice,
    this.tools = defaultTools,
    this.storage,
    this.enabled = true,
    this.backgroundColor,
  }) : super(key: key);

  /// If not [enabled], the [child] is used directly.
  final bool enabled;

  /// Indicates whether the tool bar should be visible or not.
  final bool isToolbarVisible;

  /// The configuration. If not precised, it is loaded from preferences.
  final DevicePreviewData? data;

  /// The previewed widget.
  ///
  /// It is common to give the root application widget.
  final WidgetBuilder builder;

  /// The background color of the canvas
  ///
  /// Overrides `theme.canvasColor`
  final Color? backgroundColor;

  /// The default selected device when opening device preview for the first time.
  final DeviceInfo? defaultDevice;

  /// The available devices used for previewing.
  final List<DeviceInfo>? devices;

  /// The list of available tools.
  ///
  /// All the tools must be [Sliver]s and will be added to the menu.
  final List<Widget> tools;

  /// The available locales.
  final List<Locale>? availableLocales;

  /// The storage used to persist preferences.
  ///
  /// By default, it saves preferences to the local device preferences.
  ///
  /// To disable settings persistence use `DevicePreviewStorage.none()`.
  final DevicePreviewStorage? storage;

  /// All the default available devices.
  static final List<DeviceInfo> defaultDevices = Devices.all;

  /// All the default tools included in the menu : [DeviceSection], [SystemSection],
  /// [AccessibilitySection] and [SettingsSection].
  static const List<Widget> defaultTools = <Widget>[
    DeviceSection(),
    SystemSection(),
    AccessibilitySection(),
    SettingsSection(),
  ];

  @override
  _DevicePreviewState createState() => _DevicePreviewState();

  /// The currently selected device.
  static DeviceInfo selectedDevice(BuildContext context) {
    return context.select(
      (DevicePreviewStore store) => store.deviceInfo,
    );
  }

  /// The simulated target platform for the currently selected device.
  static TargetPlatform platform(BuildContext context) {
    final platform = context.select(
      (DevicePreviewStore store) => store.deviceInfo.identifier.platform,
    );
    return platform;
  }

  /// The simulated visual density for the currently selected device.
  static VisualDensity visualDensity(BuildContext context) {
    final deviceType = context.select(
      (DevicePreviewStore store) => store.deviceInfo.identifier.type,
    );
    if (deviceType == DeviceType.desktop || deviceType == DeviceType.laptop) {
      return VisualDensity.compact;
    }
    return VisualDensity.standard;
  }

  /// Create a new [ThemeData] from the given [data], but with updated properties from
  /// the currently simulated device.
  static Widget appBuilder(BuildContext context, Widget? child) {
    if (!_isEnabled(context)) {
      return child!;
    }

    final theme = Theme.of(context);
    final isInitializedAndEnabled = context.select(
      (DevicePreviewStore store) => store.state.maybeMap(
        initialized: (initialized) => initialized.data.isEnabled,
        orElse: () => false,
      ),
    );

    if (!isInitializedAndEnabled) {
      return child!;
    }

    return Theme(
      data: theme.copyWith(
        platform: platform(context),
        visualDensity: visualDensity(context),
      ),
      child: child!,
    );
  }

  /// Indicates whether the device preview is currently enabled.
  static bool isEnabled(BuildContext context) {
    if (_isEnabled(context)) {
      return context.select(
        (DevicePreviewStore store) => store.state.maybeMap(
          initialized: (initialized) => initialized.data.isEnabled,
          orElse: () => false,
        ),
      );
    }
    return false;
  }

  static bool _isEnabled(BuildContext context) {
    final state = context.findAncestorStateOfType<_DevicePreviewState>();
    return state != null && state.widget.enabled;
  }

  /// Currently defined locale.
  static Locale? locale(BuildContext context) {
    if (!_isEnabled(context)) {
      return null;
    }

    final store = Provider.of<DevicePreviewStore>(context);
    return store.state.maybeMap(
      initialized: (state) {
        final splits = state.data.locale.split('_');
        final languageCode = splits[0];
        String? scriptCode, countryCode;
        if (splits.length > 2) {
          scriptCode = splits[1];
          countryCode = splits[2];
        } else if (splits.length > 1) {
          countryCode = splits[1];
        }
        return Locale.fromSubtags(
          languageCode: languageCode,
          scriptCode: scriptCode,
          countryCode: countryCode,
        );
      },
      orElse: () => WidgetsBinding.instance.window.locale,
    );
  }

  /// Make the toolbar visible to the user.
  ///
  /// If [enablePreview] is set to `true`, then the device preview is also enabled
  /// when appearing.
  static void showToolbar(
    BuildContext context, {
    bool enablePreview = true,
  }) {
    final store = Provider.of<DevicePreviewStore>(context);
    store.data = store.data.copyWith(
      isToolbarVisible: true,
      isEnabled: enablePreview,
    );
  }

  /// Hide the toolbar.
  ///
  /// If [disablePreview] is set to `false`, then the device preview stays active even
  /// if the toolbar is not visible anymore.
  static void hideToolbar(
    BuildContext context, {
    bool disablePreview = true,
  }) {
    final store = Provider.of<DevicePreviewStore>(context);
    store.data = store.data.copyWith(
      isToolbarVisible: false,
      isEnabled: !disablePreview,
    );
  }

  /// Select a device from its unique [deviceIdentifier].
  ///
  /// All the identifiers are available from [Devices].
  static void selectDevice(
    BuildContext context,
    DeviceIdentifier deviceIdentifier,
  ) {
    final store = Provider.of<DevicePreviewStore>(context, listen: false);
    store.selectDevice(deviceIdentifier);
  }

  /// The list of all available device identifiers.
  static List<DeviceIdentifier> availableDeviceIdentifiers(
    BuildContext context,
  ) {
    final store = Provider.of<DevicePreviewStore>(context, listen: false);
    return store.devices.map((info) => info.identifier).toList();
  }

  /// All available locales in the tool.
  static List<Locale> allLocales(BuildContext context) {
    if (!_isEnabled(context)) {
      return defaultAvailableLocales.map((e) => Locale(e.code)).toList();
    }
    final store = Provider.of<DevicePreviewStore>(context);
    return store.state
        .maybeMap(
          initialized: (state) => state.locales,
          orElse: () => defaultAvailableLocales,
        )
        .map((e) => Locale(e.code))
        .toList();
  }

  /// Take a screenshot.
  static Future<DeviceScreenshot> screenshot(BuildContext context) {
    final state = context.findAncestorStateOfType<_DevicePreviewState>();
    final store = context.read<DevicePreviewStore>();
    return state!.screenshot(store);
  }

  static MediaQueryData _mediaQuery(BuildContext context) {
    final device = context.select(
      (DevicePreviewStore store) => store.deviceInfo,
    );

    final orientation = context.select(
      (DevicePreviewStore store) => store.data.orientation,
    );

    final isVirtualKeyboardVisible = context.select(
      (DevicePreviewStore store) => store.data.isVirtualKeyboardVisible,
    );

    final isDarkMode = context.select(
      (DevicePreviewStore store) => store.data.isDarkMode,
    );

    final textScaleFactor = context.select(
      (DevicePreviewStore store) => store.data.textScaleFactor,
    );

    final boldText = context.select(
      (DevicePreviewStore store) => store.data.boldText,
    );

    final disableAnimations = context.select(
      (DevicePreviewStore store) => store.data.disableAnimations,
    );

    final accessibleNavigation = context.select(
      (DevicePreviewStore store) => store.data.accessibleNavigation,
    );

    final invertColors = context.select(
      (DevicePreviewStore store) => store.data.invertColors,
    );

    var mediaQuery = DeviceFrame.mediaQuery(
      context: context,
      info: device,
      orientation: orientation,
    );

    if (isVirtualKeyboardVisible) {
      mediaQuery = VirtualKeyboard.mediaQuery(mediaQuery);
    }

    return mediaQuery.copyWith(
      platformBrightness: isDarkMode ? Brightness.dark : Brightness.light,
      textScaleFactor: textScaleFactor,
      boldText: boldText,
      disableAnimations: disableAnimations,
      accessibleNavigation: accessibleNavigation,
      invertColors: invertColors,
    );
  }
}

class _DevicePreviewState extends State<DevicePreview> {
  bool _isToolPanelPopOverOpen = false;

  late DevicePreviewStorage storage =
      widget.storage ?? DevicePreviewStorage.preferences();

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  /// Whenever the [screenshot] is called, a new value is pushed to
  /// this stream.
  Stream<DeviceScreenshot> get onScreenshot => _onScreenshot!.stream;

  /// Takes a screenshot with the current configuration.
  Future<DeviceScreenshot> screenshot(DevicePreviewStore store) async {
    final boundary =
        _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    const format = ui.ImageByteFormat.png;

    final image = await boundary.toImage(
      pixelRatio: store.deviceInfo.pixelRatio,
    );
    final byteData = await image.toByteData(
      format: format,
    );
    final bytes = byteData!.buffer.asUint8List();
    final screenshot = DeviceScreenshot(
      device: store.deviceInfo,
      bytes: bytes,
      format: format,
    );
    _onScreenshot?.add(screenshot);
    return screenshot;
  }

  @override
  void initState() {
    _onScreenshot = StreamController<DeviceScreenshot>.broadcast();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant DevicePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storage != widget.storage && widget.storage != null) {
      storage = widget.storage!;
    }
  }

  Widget _buildPreview(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = context.select(
      (DevicePreviewStore store) => store.state.maybeMap(
        initialized: (state) => state.data.isEnabled,
        orElse: () => false,
      ),
    );

    if (!isEnabled) return widget.builder(context);

    final mediaQuery = MediaQuery.of(context);
    final device = context.select(
      (DevicePreviewStore store) => store.deviceInfo,
    );
    final isFrameVisible = context.select(
      (DevicePreviewStore store) => store.data.isFrameVisible,
    );
    final orientation = context.select(
      (DevicePreviewStore store) => store.data.orientation,
    );
    final isVirtualKeyboardVisible = context.select(
      (DevicePreviewStore store) => store.data.isVirtualKeyboardVisible,
    );
    final isDarkMode = context.select(
      (DevicePreviewStore store) => store.data.isDarkMode,
    );

    return Container(
      color: widget.backgroundColor ?? theme.canvasColor,
      padding: EdgeInsets.only(
        top: 20 + mediaQuery.viewPadding.top,
        right: 20 + mediaQuery.viewPadding.right,
        left: 20 + mediaQuery.viewPadding.left,
        bottom: 20,
      ),
      child: FittedBox(
        fit: BoxFit.contain,
        child: RepaintBoundary(
          key: _repaintKey,
          child: DeviceFrame(
            device: device,
            isFrameVisible: isFrameVisible,
            orientation: orientation,
            screen: VirtualKeyboard(
              isEnabled: isVirtualKeyboardVisible,
              child: Theme(
                data: Theme.of(context).copyWith(
                  platform: device.identifier.platform,
                  brightness: isDarkMode ? Brightness.dark : Brightness.light,
                ),
                child: MediaQuery(
                  data: DevicePreview._mediaQuery(context),
                  child: Builder(
                    key: _appKey,
                    builder: (context) {
                      final app = widget.builder(context);
                      assert(
                        isWidgetsAppUsingInheritedMediaQuery(app),
                        'Your widgets app should have its `useInheritedMediaQuery` property set to `true` in order to use DevicePreview.',
                      );
                      return app;
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return Builder(
        key: _appKey,
        builder: widget.builder,
      );
    }

    return ChangeNotifierProvider(
      create: (context) => DevicePreviewStore(
        defaultDevice: widget.defaultDevice ?? Devices.ios.iPhone13,
        devices: widget.devices,
        locales: widget.availableLocales,
        storage: storage,
      ),
      builder: (context, child) {
        final isInitialized = context.select(
          (DevicePreviewStore store) => store.state.maybeMap(
            initialized: (_) => true,
            orElse: () => false,
          ),
        );

        if (!isInitialized) {
          return Builder(
            key: _appKey,
            builder: widget.builder,
          );
        }

        final isEnabled = context.select(
          (DevicePreviewStore store) => store.data.isEnabled,
        );

        final toolbarTheme = context.select(
          (DevicePreviewStore store) => store.settings.toolbarTheme,
        );

        final backgroundTheme = context.select(
          (DevicePreviewStore store) => store.settings.backgroundTheme,
        );

        final isToolbarVisible = widget.isToolbarVisible &&
            context.select(
              (DevicePreviewStore store) => store.data.isToolbarVisible,
            );

        final toolbar = toolbarTheme.asThemeData();
        final background = backgroundTheme.asThemeData();
        return Directionality(
          textDirection: TextDirection.ltr,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: MediaQueryObserver(
              //mediaQuery: DevicePreview._mediaQuery(context),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: toolbar.scaffoldBackgroundColor,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final mediaQuery = MediaQuery.of(context);
                    final isSmall = constraints.maxWidth < 700;

                    final borderRadius = isToolbarVisible
                        ? BorderRadius.only(
                            topRight: isSmall
                                ? Radius.zero
                                : const Radius.circular(16),
                            bottomRight: const Radius.circular(16),
                            bottomLeft: isSmall
                                ? const Radius.circular(16)
                                : Radius.zero,
                          )
                        : BorderRadius.zero;
                    final double rightPanelOffset = !isSmall
                        ? (isEnabled
                            ? ToolPanel.panelWidth - 10
                            : (64 + mediaQuery.padding.right))
                        : 0;
                    final double bottomPanelOffset =
                        isSmall ? mediaQuery.padding.bottom + 52 : 0;
                    return Stack(
                      children: <Widget>[
                        if (isToolbarVisible && isSmall)
                          Positioned(
                            key: const Key('Small'),
                            bottom: 0,
                            right: 0,
                            left: 0,
                            child: DevicePreviewSmallLayout(
                              slivers: widget.tools,
                              maxMenuHeight: constraints.maxHeight * 0.5,
                              scaffoldKey: scaffoldKey,
                              onMenuVisibleChanged: (isVisible) => setState(() {
                                _isToolPanelPopOverOpen = isVisible;
                              }),
                            ),
                          ),
                        if (isToolbarVisible && !isSmall)
                          Positioned.fill(
                            key: const Key('Large'),
                            child: DervicePreviewLargeLayout(
                              slivers: widget.tools,
                            ),
                          ),
                        AnimatedPositioned(
                          key: const Key('preview'),
                          duration: const Duration(milliseconds: 200),
                          left: 0,
                          right: isToolbarVisible ? rightPanelOffset : 0,
                          top: 0,
                          bottom: isToolbarVisible ? bottomPanelOffset : 0,
                          child: Theme(
                            data: background,
                            child: Container(
                              decoration: BoxDecoration(
                                boxShadow: const [
                                  BoxShadow(
                                    blurRadius: 20,
                                    color: Color(0xAA000000),
                                  ),
                                ],
                                borderRadius: borderRadius,
                                color: background.scaffoldBackgroundColor,
                              ),
                              child: ClipRRect(
                                borderRadius: borderRadius,
                                child: isEnabled
                                    ? Builder(
                                        builder: _buildPreview,
                                      )
                                    : Builder(
                                        key: _appKey,
                                        builder: widget.builder,
                                      ),
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: IgnorePointer(
                            ignoring: !_isToolPanelPopOverOpen,
                            child: Localizations(
                              locale: const Locale('en', 'US'),
                              delegates: const [
                                GlobalMaterialLocalizations.delegate,
                                GlobalCupertinoLocalizations.delegate,
                                GlobalWidgetsLocalizations.delegate,
                              ],
                              child: Navigator(
                                onGenerateInitialRoutes: (navigator, name) {
                                  return [
                                    MaterialPageRoute(
                                      builder: (context) => Scaffold(
                                        key: scaffoldKey,
                                        backgroundColor: Colors.transparent,
                                      ),
                                    ),
                                  ];
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// The repaint key used for rendering screenshots.
  final _repaintKey = GlobalKey();

  /// A stream that sends a new value each time the user takes
  /// a new screenshot.
  StreamController<DeviceScreenshot>? _onScreenshot;

  /// The current application key.
  final GlobalKey _appKey = GlobalKey();
}
