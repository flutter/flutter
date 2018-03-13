// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show timeDilation;

import 'home.dart';
import 'item.dart';
import 'theme.dart';
import 'updates.dart';

class GalleryApp extends StatefulWidget {
  const GalleryApp({
    this.updateUrlFetcher,
    this.enablePerformanceOverlay: true,
    this.checkerboardRasterCacheImages: true,
    this.checkerboardOffscreenLayers: true,
    this.onSendFeedback,
    Key key}
  ) : super(key: key);

  final UpdateUrlFetcher updateUrlFetcher;

  final bool enablePerformanceOverlay;

  final bool checkerboardRasterCacheImages;

  final bool checkerboardOffscreenLayers;

  final VoidCallback onSendFeedback;

  @override
  GalleryAppState createState() => new GalleryAppState();
}

class GalleryAppState extends State<GalleryApp> {
  GalleryTheme _galleryTheme = kAllGalleryThemes[0];
  bool _showPerformanceOverlay = false;
  bool _checkerboardRasterCacheImages = false;
  bool _checkerboardOffscreenLayers = false;
  TextDirection _overrideDirection = TextDirection.ltr;
  double _timeDilation = 1.0;
  TargetPlatform _platform;

  // A null value indicates "use system default".
  double _textScaleFactor;

  Timer _timeDilationTimer;

  @override
  void initState() {
    _timeDilation = timeDilation;
    super.initState();
  }

  @override
  void dispose() {
    _timeDilationTimer?.cancel();
    _timeDilationTimer = null;
    super.dispose();
  }

  Widget _applyScaleFactor(Widget child) {
    return new Builder(
      builder: (BuildContext context) => new MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaleFactor: _textScaleFactor,
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget home = new GalleryHome(
      galleryTheme: _galleryTheme,
      onThemeChanged: (GalleryTheme value) {
        setState(() {
          _galleryTheme = value;
        });
      },
      showPerformanceOverlay: _showPerformanceOverlay,
      onShowPerformanceOverlayChanged: widget.enablePerformanceOverlay ? (bool value) {
        setState(() {
          _showPerformanceOverlay = value;
        });
      } : null,
      checkerboardRasterCacheImages: _checkerboardRasterCacheImages,
      onCheckerboardRasterCacheImagesChanged: widget.checkerboardRasterCacheImages ? (bool value) {
        setState(() {
          _checkerboardRasterCacheImages = value;
        });
      } : null,
      checkerboardOffscreenLayers: _checkerboardOffscreenLayers,
      onCheckerboardOffscreenLayersChanged: widget.checkerboardOffscreenLayers ? (bool value) {
        setState(() {
          _checkerboardOffscreenLayers = value;
        });
      } : null,
      onPlatformChanged: (TargetPlatform value) {
        setState(() {
          _platform = value == defaultTargetPlatform ? null : value;
        });
      },
      timeDilation: _timeDilation,
      onTimeDilationChanged: (double value) {
        setState(() {
          _timeDilationTimer?.cancel();
          _timeDilationTimer = null;
          _timeDilation = value;
          if (_timeDilation > 1.0) {
            // We delay the time dilation change long enough that the user can see
            // that the checkbox in the drawer has started reacting, then we slam
            // on the brakes so that they see that the time is in fact now dilated.
            _timeDilationTimer = new Timer(const Duration(milliseconds: 150), () {
              timeDilation = _timeDilation;
            });
          } else {
            timeDilation = _timeDilation;
          }
        });
      },
      textScaleFactor: _textScaleFactor,
      onTextScaleFactorChanged: (double value) {
        setState(() {
          _textScaleFactor = value;
         });
      },
      overrideDirection: _overrideDirection,
      onOverrideDirectionChanged: (TextDirection value) {
        setState(() {
          _overrideDirection = value;
        });
      },
      onSendFeedback: widget.onSendFeedback,
    );

    if (widget.updateUrlFetcher != null) {
      home = new Updater(
        updateUrlFetcher: widget.updateUrlFetcher,
        child: home,
      );
    }

    final Map<String, WidgetBuilder> _kRoutes = <String, WidgetBuilder>{};
    for (GalleryItem item in kAllGalleryItems) {
      // For a different example of how to set up an application routing table
      // using named routes, consider the example in the Navigator class documentation:
      // https://docs.flutter.io/flutter/widgets/Navigator-class.html
      _kRoutes[item.routeName] = (BuildContext context) {
        return item.buildRoute(context);
      };
    }

    return new MaterialApp(
      title: 'Flutter Gallery',
      color: Colors.grey,
      theme: _galleryTheme.theme.copyWith(platform: _platform ?? defaultTargetPlatform),
      showPerformanceOverlay: _showPerformanceOverlay,
      checkerboardRasterCacheImages: _checkerboardRasterCacheImages,
      checkerboardOffscreenLayers: _checkerboardOffscreenLayers,
      routes: _kRoutes,
      home: _applyScaleFactor(home),
      builder: (BuildContext context, Widget child) {
        return new Directionality(
          textDirection: _overrideDirection,
          child: _applyScaleFactor(child),
        );
      },
    );
  }
}
