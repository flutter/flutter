// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:io' as io;
import 'dart:convert';
import 'dart:math';

import 'package:image/image.dart';
import 'package:path/path.dart' as path;
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart'
    as wip;
import 'package:yaml/yaml.dart';

import 'common.dart';
import 'environment.dart';
import 'safari_installation.dart';
import 'utils.dart';

/// [ScreenshotManager] implementation for Chrome.
///
/// This manager can be used for both macOS and Linux.
// TODO: https://github.com/flutter/flutter/issues/65673
class ChromeScreenshotManager extends ScreenshotManager {
  String get filenameSuffix => '';

  /// Capture a screenshot of the web content.
  ///
  /// Uses Webkit Inspection Protocol server's `captureScreenshot` API.
  ///
  /// [region] is used to decide which part of the web content will be used in
  /// test image. It includes starting coordinate x,y as well as height and
  /// width of the area to capture.
  Future<Image> capture(Rectangle region) async {
    final wip.ChromeConnection chromeConnection =
        wip.ChromeConnection('localhost', kDevtoolsPort);
    final wip.ChromeTab chromeTab = await chromeConnection.getTab(
        (wip.ChromeTab chromeTab) => chromeTab.url.contains('localhost'));
    final wip.WipConnection wipConnection = await chromeTab.connect();

    Map<String, dynamic> captureScreenshotParameters = null;
    if (region != null) {
      captureScreenshotParameters = <String, dynamic>{
        'format': 'png',
        'clip': <String, dynamic>{
          'x': region.left,
          'y': region.top,
          'width': region.width,
          'height': region.height,
          'scale':
              // This is NOT the DPI of the page, instead it's the "zoom level".
              1,
        },
      };
    }

    // Setting hardware-independent screen parameters:
    // https://chromedevtools.github.io/devtools-protocol/tot/Emulation
    await wipConnection
        .sendCommand('Emulation.setDeviceMetricsOverride', <String, dynamic>{
      'width': kMaxScreenshotWidth,
      'height': kMaxScreenshotHeight,
      'deviceScaleFactor': 1,
      'mobile': false,
    });
    final wip.WipResponse response = await wipConnection.sendCommand(
        'Page.captureScreenshot', captureScreenshotParameters);

    final Image screenshot =
        decodePng(base64.decode(response.result['data'] as String));

    return screenshot;
  }
}

/// [ScreenshotManager] implementation for Safari.
///
/// This manager will only be created/used for macOS.
class IosSafariScreenshotManager extends ScreenshotManager {
  String get filenameSuffix => '.iOS_Safari';

  IosSafariScreenshotManager() {
    final YamlMap browserLock = BrowserLock.instance.configuration;
    _heightOfHeader = browserLock['ios-safari']['heightOfHeader'] as int;
    _heightOfFooter = browserLock['ios-safari']['heightOfFooter'] as int;
    _scaleFactor = browserLock['ios-safari']['scaleFactor'] as double;

    /// Create the directory to use for taking screenshots, if it does not
    /// exists.
    if (!environment.webUiSimulatorScreenshotsDirectory.existsSync()) {
      environment.webUiSimulatorScreenshotsDirectory.createSync();
    }
    // Temporary directories are deleted in the clenaup phase of after `felt`
    // runs the tests.
    temporaryDirectories.add(environment.webUiSimulatorScreenshotsDirectory);
  }

  /// This scale factor is used to enlarge/shrink the screenshot region
  /// sent from the tests.
  /// For more details see [_scaleScreenshotRegion(region)].
  double _scaleFactor;

  /// Height of the part to crop from the top of the image.
  ///
  /// `xcrun simctl` command takes the screenshot of the entire simulator. We
  /// are cropping top bit from screenshot, otherwise due to the clock on top of
  /// the screen, the screenshot will differ between each run.
  /// Note that this gap can change per phone and per iOS version. For more
  /// details refer to `browser_lock.yaml` file.
  int _heightOfHeader;

  /// Height of the part to crop from the bottom of the image.
  ///
  /// This area is the footer navigation bar of the phone, it is not the area
  /// used by tests (which is inside the browser).
  int _heightOfFooter;

  /// Used as a suffix for the temporary file names used for screenshots.
  int _fileNameCounter = 0;

  /// Capture a screenshot of entire simulator.
  ///
  /// Example screenshot with dimensions: W x H.
  ///
  ///  <----------  W ------------->
  ///  _____________________________
  /// | Phone Top bar (clock etc.)  |   Ʌ
  /// |_____________________________|   |
  /// | Broswer search bar          |   |
  /// |_____________________________|   |
  /// | Web page content            |   |
  /// |                             |   |
  /// |                             |
  /// |                             |   H
  /// |                             |
  /// |                             |   |
  /// |                             |   |
  /// |                             |   |
  /// |                             |   |
  /// |_____________________________|   |
  /// | Phone footer bar            |   |
  /// |_____________________________|   V
  ///
  /// After taking the screenshot, the image is cropped as heigh as
  /// [_heightOfHeader] and [_heightOfFooter] from the top and bottom parts
  /// consecutively. Hence web content has the dimensions:
  ///
  /// W x (H - [_heightOfHeader] - [_heightOfFooter])
  ///
  /// [region] is used to decide which part of the web content will be used in
  /// test image. It includes starting coordinate x,y as well as height and
  /// width of the area to capture.
  ///
  /// Uses simulator tool `xcrun simctl`'s 'screenshot' command.
  Future<Image> capture(Rectangle region) async {
    final String filename = 'screenshot${_fileNameCounter}.png';
    _fileNameCounter++;

    await IosSafariArgParser.instance.iosSimulator.takeScreenshot(
        filename, environment.webUiSimulatorScreenshotsDirectory);

    final io.File file = io.File(path.join(
        environment.webUiSimulatorScreenshotsDirectory.path, filename));
    List<int> imageBytes;
    if (!file.existsSync()) {
      throw Exception('Failed to read the screenshot '
          'screenshot${_fileNameCounter}.png.');
    }
    imageBytes = await file.readAsBytes();
    file.deleteSync();

    final Image screenshot = decodePng(imageBytes);
    // Create an image with no footer and header. The _heightOfHeader,
    // _heightOfFooter values are already in real coordinates therefore
    // they don't need to be scaled.
    final Image content = copyCrop(
      screenshot,
      0,
      _heightOfHeader,
      screenshot.width,
      screenshot.height - _heightOfFooter - _heightOfHeader,
    );

    if (region == null) {
      return content;
    } else {
      final Rectangle scaledRegion = _scaleScreenshotRegion(region);
      return copyCrop(
        content,
        scaledRegion.left.toInt(),
        scaledRegion.top.toInt(),
        scaledRegion.width.toInt(),
        scaledRegion.height.toInt(),
      );
    }
  }

  /// Perform a linear transform on the screenshot region to convert its
  /// dimensions from linear coordinated to coordinated on the phone screen.
  /// This uniform/isotropic scaling is done using [_scaleFactor].
  Rectangle _scaleScreenshotRegion(Rectangle region) {
    return Rectangle(
      region.left * _scaleFactor,
      region.top * _scaleFactor,
      region.width * _scaleFactor,
      region.height * _scaleFactor,
    );
  }
}

const String _kBrowserChrome = 'chrome';
const String _kBrowserIOSSafari = 'ios-safari';

typedef ScreenshotManagerFactory = ScreenshotManager Function();

/// Abstract class for taking screenshots in one of the browsers.
abstract class ScreenshotManager {
  static final Map<String, ScreenshotManagerFactory> _browserFactories =
      <String, ScreenshotManagerFactory>{
    _kBrowserChrome: () => ChromeScreenshotManager(),
    _kBrowserIOSSafari: () => IosSafariScreenshotManager(),
  };

  static bool isBrowserSupported(String browser) =>
      _browserFactories.containsKey(browser);

  static ScreenshotManager choose(String browser) {
    if (isBrowserSupported(browser)) {
      return _browserFactories[browser]();
    }
    throw StateError('Screenshot tests are only supported on Chrome and on '
        'iOS Safari');
  }

  /// Capture a screenshot.
  ///
  /// Please read the details for the implementing classes.
  Future<Image> capture(Rectangle region);

  /// Suffix to be added to the end of the filename.
  ///
  /// Example file names:
  /// - Chrome, no-suffix: backdrop_filter_clip_moved.actual.png
  /// - iOS Safari: backdrop_filter_clip_moved.actual.iOS_Safari.png
  String get filenameSuffix;
}
