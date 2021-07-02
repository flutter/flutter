// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;
import 'dart:math' as math;

import 'package:image/image.dart';
import 'package:path/path.dart' as path;
import 'package:test_api/src/backend/runtime.dart';
import 'package:yaml/yaml.dart';

import 'browser.dart';
import 'common.dart';
import 'environment.dart';
import 'safari_installation.dart';
import 'utils.dart';

/// Provides an environment for the mobile variant of Safari running in an iOS
/// simulator.
class SafariIosEnvironment implements BrowserEnvironment {
  @override
  Browser launchBrowserInstance(Uri url, {bool debug = false}) {
    return SafariIos(url);
  }

  @override
  Runtime get packageTestRuntime => Runtime.safari;

  @override
  Future<void> prepareEnvironment() async {
    await IosSafariArgParser.instance.initIosSimulator();
  }

  @override
  ScreenshotManager? getScreenshotManager() {
    return SafariIosScreenshotManager();
  }

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
  @override
  final name = 'Safari iOS';

  /// Starts a new instance of Safari open to the given [url], which may be a
  /// [Uri].
  factory SafariIos(Uri url) {
    return SafariIos._(() async {
      // iOS-Safari
      // Uses `xcrun simctl`. It is a command line utility to control the
      // Simulator. For more details on interacting with the simulator:
      // https://developer.apple.com/library/archive/documentation/IDEs/Conceptual/iOS_Simulator_Guide/InteractingwiththeiOSSimulator/InteractingwiththeiOSSimulator.html
      var process = await io.Process.start('xcrun', [
        'simctl',
        'openurl', // Opens the url on Safari installed on the simulator.
        'booted', // The simulator is already booted.
        '${url.toString()}',
      ]);

      return process;
    });
  }

  SafariIos._(Future<io.Process> startBrowser()) : super(startBrowser);
}

/// [ScreenshotManager] implementation for Safari.
///
/// This manager will only be created/used for macOS.
class SafariIosScreenshotManager extends ScreenshotManager {
  String get filenameSuffix => '.iOS_Safari';

  SafariIosScreenshotManager() {
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
  late final double _scaleFactor;

  /// Height of the part to crop from the top of the image.
  ///
  /// `xcrun simctl` command takes the screenshot of the entire simulator. We
  /// are cropping top bit from screenshot, otherwise due to the clock on top of
  /// the screen, the screenshot will differ between each run.
  /// Note that this gap can change per phone and per iOS version. For more
  /// details refer to `browser_lock.yaml` file.
  late final int _heightOfHeader;

  /// Height of the part to crop from the bottom of the image.
  ///
  /// This area is the footer navigation bar of the phone, it is not the area
  /// used by tests (which is inside the browser).
  late final int _heightOfFooter;

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
  Future<Image> capture(math.Rectangle? region) async {
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

    final Image screenshot = decodePng(imageBytes)!;
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
      final math.Rectangle scaledRegion = _scaleScreenshotRegion(region);
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
  math.Rectangle _scaleScreenshotRegion(math.Rectangle region) {
    return math.Rectangle(
      region.left * _scaleFactor,
      region.top * _scaleFactor,
      region.width * _scaleFactor,
      region.height * _scaleFactor,
    );
  }
}
