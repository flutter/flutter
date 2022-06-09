// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;
import 'dart:math' as math;

import 'package:image/image.dart';
import 'package:path/path.dart' as path;
import 'package:test_api/src/backend/runtime.dart';
import 'package:uuid/uuid.dart';

import 'browser.dart';
import 'browser_lock.dart';
import 'browser_process.dart';
import 'environment.dart';
import 'safari_installation.dart';
import 'utils.dart';

/// Info about the screen layout for the current version of iOS Safari.
///
/// This is used to properly take screenshots of the browser.
class SafariScreenInfo {
  final int heightOfHeader;
  final int heightOfFooter;
  final double scaleFactor;

  SafariScreenInfo(this.heightOfHeader, this.heightOfFooter, this.scaleFactor);
}

/// Provides an environment for the mobile variant of Safari running in an iOS
/// simulator.
class SafariIosEnvironment implements BrowserEnvironment {
  late final SafariScreenInfo _screenInfo;

  @override
  final String name = 'Safari iOS';

  @override
  Future<Browser> launchBrowserInstance(Uri url, {bool debug = false}) async {
    return SafariIos(url, _screenInfo);
  }

  @override
  Runtime get packageTestRuntime => Runtime.safari;

  @override
  Future<void> prepare() async {
    final SafariIosLock lock = browserLock.safariIosLock;
    _screenInfo = SafariScreenInfo(
        lock.heightOfHeader, lock.heightOfFooter, lock.scaleFactor);

    /// Create the directory to use for taking screenshots, if it does not
    /// exists.
    if (!environment.webUiSimulatorScreenshotsDirectory.existsSync()) {
      environment.webUiSimulatorScreenshotsDirectory.createSync();
    }
    // Temporary directories are deleted in the clenaup phase of after `felt`
    // runs the tests.
    temporaryDirectories.add(environment.webUiSimulatorScreenshotsDirectory);

    await initIosSimulator();
  }

  @override
  Future<void> cleanup() async {}

  @override
  String get packageTestConfigurationYamlFile => 'dart_test_safari.yaml';
}

/// Runs an instance of Safari for iOS (i.e. mobile Safari).
///
/// Most of the communication with the browser is expected to happen via HTTP,
/// so this exposes a bare-bones API. The browser starts as soon as the class is
/// constructed, and is killed when [close] is called.
///
/// Any errors starting or running the process are reported through [onExit].
class SafariIos extends Browser {
  final BrowserProcess _process;
  final SafariScreenInfo _screenInfo;

  /// Starts a new instance of Safari open to the given [url], which may be a
  /// [Uri].
  factory SafariIos(Uri url, SafariScreenInfo screenInfo) {
    return SafariIos._(BrowserProcess(() async {
      // iOS-Safari
      // Uses `xcrun simctl`. It is a command line utility to control the
      // Simulator. For more details on interacting with the simulator:
      // https://developer.apple.com/library/archive/documentation/IDEs/Conceptual/iOS_Simulator_Guide/InteractingwiththeiOSSimulator/InteractingwiththeiOSSimulator.html
      final io.Process process = await io.Process.start('xcrun', <String>[
        'simctl',
        'openurl', // Opens the url on Safari installed on the simulator.
        'booted', // The simulator is already booted.
        url.toString(),
      ]);

      return process;
    }), screenInfo);
  }

  SafariIos._(this._process, this._screenInfo);

  @override
  Future<void> get onExit => _process.onExit;

  @override
  Future<void> close() => _process.close();

  @override
  bool get supportsScreenshots => true;

  @override

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
  @override
  Future<Image> captureScreenshot(math.Rectangle<num>? region) async {
    final String screenshotTag = const Uuid().v4();

    final String filename = 'screenshot$screenshotTag.png';

    await iosSimulator.takeScreenshot(
      filename,
      environment.webUiSimulatorScreenshotsDirectory,
    );

    final io.File file = io.File(path.join(
        environment.webUiSimulatorScreenshotsDirectory.path, filename));
    List<int> imageBytes;
    if (!file.existsSync()) {
      throw Exception('Failed to read the screenshot $filename.');
    }
    imageBytes = await file.readAsBytes();
    file.deleteSync();

    final Image screenshot = decodePng(imageBytes)!;
    // Create an image with no footer and header. The _heightOfHeader,
    // _heightOfFooter values are already in real coordinates therefore
    // they don't need to be scaled.
    final Image content = copyCrop(
      screenshot,
      0,
      _screenInfo.heightOfHeader,
      screenshot.width,
      screenshot.height -
          _screenInfo.heightOfFooter -
          _screenInfo.heightOfHeader,
    );

    if (region == null) {
      return content;
    } else {
      final math.Rectangle<num> scaledRegion = _scaleScreenshotRegion(region);
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
  math.Rectangle<num> _scaleScreenshotRegion(math.Rectangle<num> region) {
    return math.Rectangle<num>(
      region.left * _screenInfo.scaleFactor,
      region.top * _screenInfo.scaleFactor,
      region.width * _screenInfo.scaleFactor,
      region.height * _screenInfo.scaleFactor,
    );
  }
}
