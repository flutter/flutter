// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:process/process.dart';

import 'android/android_emulator.dart';
import 'android/android_sdk.dart';
import 'android/android_workflow.dart';
import 'android/java.dart';
import 'base/context.dart';
import 'base/file_system.dart';
import 'base/logger.dart';
import 'base/process.dart';
import 'context/tool_context.dart';
import 'device.dart';
import 'experimental/extension_device_manager.dart';
import 'experimental/extension_manager.dart';
import 'ios/ios_emulators.dart';
import 'ios/ios_workflow.dart';
import 'macos/xcode.dart';

EmulatorManager? get emulatorManager => context.get<EmulatorManager>();

/// A class to get all available emulators.
class EmulatorManager {
  EmulatorManager({
    required this._androidWorkflow,
    required this._iosWorkflow,
    required this._javaBuilder,
    required this._toolContext,
    required this._xcode,
    this._androidSdkBuilder,
    this._extensionManager,
  });

  /// Platform identifier for built-in Android AVD creation (`--platform android`).
  static const androidPlatform = 'android';

  final AndroidSdk? Function()? _androidSdkBuilder;
  late final AndroidSdk? _androidSdk = _androidSdkBuilder?.call();
  final AndroidWorkflow _androidWorkflow;
  final ExtensionManager? _extensionManager;
  final IOSWorkflow? _iosWorkflow;
  final Java? Function() _javaBuilder;
  late final Java? _java = _javaBuilder();
  final ToolContext _toolContext;
  final Xcode? _xcode;

  late final AndroidEmulators _androidEmulators = () {
    final ToolContext(:FileSystem fs, :Logger logger, :ProcessManager processManager) =
        _toolContext;
    return AndroidEmulators(
      androidSdkBuilder: _androidSdkBuilder,
      androidWorkflow: _androidWorkflow,
      fileSystem: fs,
      logger: logger,
      processManager: processManager,
    );
  }();

  late final ExtensionEmulators? _extensionEmulators = _extensionManager != null
      ? ExtensionEmulators(extensionManager: _extensionManager, logger: _toolContext.logger)
      : null;

  // Constructing EmulatorManager is cheap; discoverers are only instantiated
  // when emulator methods are called.
  late final _emulatorDiscoverers = <EmulatorDiscovery>[
    IOSEmulators(iosWorkflow: _iosWorkflow, toolContext: _toolContext, xcode: _xcode),
    _androidEmulators,
    ?_extensionEmulators,
  ];

  Future<List<Emulator>> getEmulatorsMatching(String searchText) async {
    final List<Emulator> emulators = await getAllAvailableEmulators();
    searchText = searchText.toLowerCase();
    bool exactlyMatchesEmulatorId(Emulator emulator) =>
        emulator.id.toLowerCase() == searchText || emulator.name.toLowerCase() == searchText;
    bool startsWithEmulatorId(Emulator emulator) =>
        emulator.id.toLowerCase().startsWith(searchText) ||
        emulator.name.toLowerCase().startsWith(searchText);

    Emulator? exactMatch;
    for (final emulator in emulators) {
      if (exactlyMatchesEmulatorId(emulator)) {
        exactMatch = emulator;
        break;
      }
    }
    if (exactMatch != null) {
      return <Emulator>[exactMatch];
    }

    // Match on a id or name starting with [emulatorId].
    return emulators.where(startsWithEmulatorId).toList();
  }

  Iterable<EmulatorDiscovery> get _platformDiscoverers {
    return _emulatorDiscoverers.where(
      (EmulatorDiscovery discoverer) => discoverer.supportsPlatform,
    );
  }

  /// Return the list of all available emulators.
  Future<List<Emulator>> getAllAvailableEmulators() async {
    final emulators = <Emulator>[];
    await Future.forEach<EmulatorDiscovery>(_platformDiscoverers, (
      EmulatorDiscovery discoverer,
    ) async {
      emulators.addAll(await discoverer.emulators);
    });
    return emulators;
  }

  bool get _canCreateAndroidEmulator =>
      _androidSdk?.avdManagerPath != null && _androidEmulators.canLaunchAnything;

  /// Returns whether any active tool extension contributes emulators or supports
  /// creating emulators.
  Future<bool> hasExtensionEmulatorSources() async {
    final ExtensionEmulators? extensionEmulators = _extensionEmulators;
    if (extensionEmulators == null) {
      return false;
    }
    return extensionEmulators.hasEmulatorSources();
  }

  /// Returns the platform identifiers currently capable of creating emulators
  /// (for example, `'android'` when `avdmanager` is available, followed by
  /// active extension emulator platforms).
  Future<List<String>> getAvailableCreatePlatforms() async {
    final ExtensionEmulators? extensionEmulators = _extensionEmulators;
    final List<String> extensionPlatforms = extensionEmulators != null
        ? await extensionEmulators.getCreatePlatforms()
        : const <String>[];
    return <String>[if (_canCreateAndroidEmulator) androidPlatform, ...extensionPlatforms];
  }

  /// Creates a new emulator, optionally named [name], targeting [platform]
  /// (`'android'` by default, or an extension platform identifier).
  Future<CreateEmulatorResult> createEmulator({
    String? name,
    String platform = androidPlatform,
  }) async {
    if (platform == androidPlatform) {
      return _createAndroidEmulator(name: name);
    }

    final ExtensionEmulators? extensionEmulators = _extensionEmulators;
    if (extensionEmulators != null) {
      final CreateEmulatorResult? result = await extensionEmulators.createEmulator(
        platform: platform,
        name: name,
      );
      if (result != null) {
        return result;
      }
    }
    final List<String> availablePlatforms = await getAvailableCreatePlatforms();
    return CreateEmulatorResult(
      name ?? '',
      success: false,
      error: availablePlatforms.isEmpty
          ? 'Unknown emulator creation platform "$platform". '
                'No emulator creation platforms are available.'
          : 'Unknown emulator creation platform "$platform". '
                'Available platforms: ${availablePlatforms.join(', ')}.',
    );
  }

  Future<CreateEmulatorResult> _createAndroidEmulator({String? name}) async {
    if (name == null || name.isEmpty) {
      const autoName = 'flutter_emulator';
      // Don't use getEmulatorsMatching here, as it will only return one
      // if there's an exact match and we need all those with this prefix
      // so we can keep adding suffixes until we miss.
      final List<Emulator> all = await getAllAvailableEmulators();
      final Set<String> takenNames = all
          .map<String>((Emulator e) => e.id)
          .where((String id) => id.startsWith(autoName))
          .toSet();
      var suffix = 1;
      name = autoName;
      while (takenNames.contains(name)) {
        name = '${autoName}_${++suffix}';
      }
    }
    final String emulatorName = name!;
    final String? avdManagerPath = _androidSdk?.avdManagerPath;
    if (avdManagerPath == null || !_androidEmulators.canLaunchAnything) {
      return CreateEmulatorResult(
        emulatorName,
        success: false,
        error: 'avdmanager is missing from the Android SDK',
      );
    }

    final String? device = await _getPreferredAvailableDevice(avdManagerPath);
    if (device == null) {
      return CreateEmulatorResult(
        emulatorName,
        success: false,
        error: 'No device definitions are available',
      );
    }

    final String? sdkId = await _getPreferredSdkId(avdManagerPath);
    if (sdkId == null) {
      return CreateEmulatorResult(
        emulatorName,
        success: false,
        error:
            'No suitable Android AVD system images are available. You may need to install these'
            ' using sdkmanager, for example:\n'
            '  sdkmanager "system-images;android-27;google_apis_playstore;x86"',
      );
    }

    // Cleans up error output from avdmanager to make it more suitable to show
    // to flutter users. Specifically:
    // - Removes lines that say "null" (!)
    // - Removes lines that tell the user to use '--force' to overwrite emulators
    String? cleanError(String? error) {
      if (error == null || error.trim() == '') {
        return null;
      }
      return error
          .split('\n')
          .where((String l) => l.trim() != 'null')
          .where((String l) => l.trim() != 'Use --force if you want to replace it.')
          .join('\n')
          .trim();
    }

    final RunResult runResult = await _toolContext.processUtils.run(<String>[
      avdManagerPath,
      'create',
      'avd',
      '-n',
      emulatorName,
      '-k',
      sdkId,
      '-d',
      device,
    ], environment: _java?.environment);
    return CreateEmulatorResult(
      emulatorName,
      success: runResult.exitCode == 0,
      output: runResult.stdout,
      error: cleanError(runResult.stderr),
    );
  }

  static const preferredDevices = <String>['pixel', 'pixel_xl'];

  Future<String?> _getPreferredAvailableDevice(String avdManagerPath) async {
    final args = <String>[avdManagerPath, 'list', 'device', '-c'];
    final RunResult runResult = await _toolContext.processUtils.run(
      args,
      environment: _java?.environment,
    );
    if (runResult.exitCode != 0) {
      return null;
    }

    final List<String> availableDevices = runResult.stdout
        .split('\n')
        .where((String l) => preferredDevices.contains(l.trim()))
        .toList();

    for (final String device in preferredDevices) {
      if (availableDevices.contains(device)) {
        return device;
      }
    }
    return null;
  }

  static final _androidApiVersion = RegExp(r';android-(\d+);');

  Future<String?> _getPreferredSdkId(String avdManagerPath) async {
    // It seems that to get the available list of images, we need to send a
    // request to create without the image and it'll provide us a list :-(
    final args = <String>[avdManagerPath, 'create', 'avd', '-n', 'temp'];
    final RunResult runResult = await _toolContext.processUtils.run(
      args,
      environment: _java?.environment,
    );

    // Get the list of IDs that match our criteria
    final List<String> availableIDs = runResult.stderr
        .split('\n')
        .where((String l) => _androidApiVersion.hasMatch(l))
        .where((String l) => l.contains('system-images'))
        .where((String l) => l.contains('google_apis_playstore'))
        .toList();

    final List<int> availableApiVersions = availableIDs
        .map<String>((String id) => _androidApiVersion.firstMatch(id)!.group(1)!)
        .map<int>((String apiVersion) => int.parse(apiVersion))
        .toList();

    // Get the highest Android API version or whats left
    final int apiVersion = availableApiVersions.isNotEmpty
        ? availableApiVersions.reduce(math.max)
        : -1; // Don't match below

    // We're out of preferences, we just have to return the first one with the high
    // API version.
    for (final id in availableIDs) {
      if (id.contains(';android-$apiVersion;')) {
        return id;
      }
    }
    return null;
  }

  /// Whether we're capable of listing any emulators given the current environment configuration.
  bool get canListAnything {
    return _platformDiscoverers.any((EmulatorDiscovery discoverer) => discoverer.canListAnything);
  }
}

/// An abstract class to discover and enumerate a specific type of emulators.
abstract class EmulatorDiscovery {
  bool get supportsPlatform;

  /// Whether this emulator discovery is capable of listing any emulators.
  bool get canListAnything;

  /// Whether this emulator discovery is capable of launching new emulators.
  bool get canLaunchAnything;

  Future<List<Emulator>> get emulators;
}

@immutable
abstract class Emulator {
  const Emulator(this.id, this.hasConfig);

  final String id;
  final bool hasConfig;
  String get name;
  String? get manufacturer;
  Category get category;
  PlatformType get platformType;

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is Emulator && other.id == id;
  }

  Future<void> launch({bool coldBoot});

  @override
  String toString() => name;

  static List<String> descriptions(List<Emulator> emulators) {
    if (emulators.isEmpty) {
      return <String>[];
    }

    const tableHeader = <String>['Id', 'Name', 'Manufacturer', 'Platform'];

    // Extract emulators information
    final table = <List<String>>[
      tableHeader,
      for (final Emulator emulator in emulators)
        <String>[
          emulator.id,
          emulator.name,
          emulator.manufacturer ?? '',
          emulator.platformType.toString(),
        ],
    ];

    // Calculate column widths
    final indices = List<int>.generate(table[0].length - 1, (int i) => i);
    List<int> widths = indices.map<int>((int i) => 0).toList();
    for (final row in table) {
      widths = indices.map<int>((int i) => math.max(widths[i], row[i].length)).toList();
    }

    // Join columns into lines of text
    final whiteSpaceAndDots = RegExp(r'[•\s]+$');
    return table
        .map<String>((List<String> row) {
          return indices
              .map<String>((int i) => row[i].padRight(widths[i]))
              .followedBy(<String>[row.last])
              .join(' • ');
        })
        .map<String>((String line) => line.replaceAll(whiteSpaceAndDots, ''))
        .toList();
  }

  static void printEmulators(List<Emulator> emulators, Logger logger) {
    final List<String> emulatorDescriptions = descriptions(emulators);
    // Prints the first description as the table header, followed by a newline.
    logger.printStatus('${emulatorDescriptions.first}\n');
    emulatorDescriptions.sublist(1).forEach(logger.printStatus);
  }
}

class CreateEmulatorResult {
  CreateEmulatorResult(this.emulatorName, {required this.success, this.output, this.error});

  final bool success;
  final String emulatorName;
  final String? output;
  final String? error;
}
