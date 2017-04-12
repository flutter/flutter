// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/platform.dart';
import '../cache.dart';
import '../device.dart';
import '../flx.dart' as flx;
import '../fuchsia/fuchsia_device.dart';
import '../globals.dart';
import '../run_hot.dart';
import '../runner/flutter_command.dart';
import '../vmservice.dart';

// Usage:
// With e.g. flutter_gallery already running, a HotRunner can be attached to it
// with:
// $ flutter fuchsia_reload -f ~/fuchsia -a 192.168.1.39 \
//       -g //lib/flutter/examples/flutter_gallery:flutter_gallery

class FuchsiaReloadCommand extends FlutterCommand {
  FuchsiaReloadCommand() {
    addBuildModeFlags(defaultToRelease: false);
    argParser.addOption('address',
      abbr: 'a',
      help: 'Fuchsia device network name or address.');
    argParser.addOption('build-type',
      abbr: 'b',
      defaultsTo: 'release-x86-64',
      help: 'Fuchsia build type, e.g. release-x86-64.');
    argParser.addOption('fuchsia-root',
      abbr: 'f',
      defaultsTo: platform.environment['FUCHSIA_ROOT'],
      help: 'Path to Fuchsia source tree.');
    argParser.addOption('gn-target',
      abbr: 'g',
      help: 'GN target of the application, e.g //path/to/app:app');
    argParser.addOption('name-override',
      abbr: 'n',
      help: 'On-device name of the application binary.');
    argParser.addOption('target',
      abbr: 't',
      defaultsTo: flx.defaultMainPath,
      help: 'Target app path / main entry-point file. '
            'Relative to --gn-target path, e.g. lib/main.dart');
  }

  @override
  final String name = 'fuchsia_reload';

  @override
  final String description = 'Hot reload on Fuchsia.';

  String _fuchsiaRoot;
  String _projectRoot;
  String _projectName;
  String _binaryName;
  String _fuchsiaProjectPath;
  String _target;
  String _address;
  String _dotPackagesPath;

  @override
  Future<Null> runCommand() async {
    Cache.releaseLockEarly();

    _validateArguments();

    // Find the network ports used on the device by VM service instances.
    final List<int> servicePorts = await _getServicePorts();
    if (servicePorts.isEmpty)
      throwToolExit('Couldn\'t find any running Observatory instances.');
    for (int port in servicePorts)
      printTrace('Fuchsia service port: $port');

    // Check that there are running VM services on the returned
    // ports, and find the Isolates that are running the target app.
    final String isolateName = '$_binaryName\$main';
    final List<int> targetPorts = await _filterPorts(servicePorts, isolateName);
    if (targetPorts.isEmpty)
      throwToolExit('No VMs found running $_binaryName.');
    for (int port in targetPorts)
      printTrace('Found $_binaryName at $port');

    // Set up a device and hot runner and attach the hot runner to the first
    // vm service we found.
    final int firstPort = targetPorts[0];
    final String fullAddress = '$_address:$firstPort';
    final FuchsiaDevice device = new FuchsiaDevice(fullAddress);
    final HotRunner hotRunner = new HotRunner(
      device,
      debuggingOptions: new DebuggingOptions.enabled(getBuildMode()),
      target: _target,
      projectRootPath: _fuchsiaProjectPath,
      packagesFilePath: _dotPackagesPath,
    );
    final Uri observatoryUri = Uri.parse('http://$fullAddress');
    printStatus('Connecting to $_binaryName at $observatoryUri');
    await hotRunner.attach(observatoryUri, isolateFilter: isolateName);
  }

  // Find ports where there is a view isolate with the given name
  Future<List<int>> _filterPorts(List<int> ports, String isolateFilter) async {
    final List<int> result = <int>[];
    for (int port in ports) {
      final String addr = 'http://$_address:$port';
      final Uri uri = Uri.parse(addr);
      final VMService vmService = VMService.connect(uri);
      await vmService.getVM();
      await vmService.waitForViews();
      if (vmService.vm.firstView == null) {
        printTrace('Found no views at $addr');
        continue;
      }
      for (FlutterView v in vmService.vm.views) {
        printTrace('At $addr, found view: ${v.uiIsolate.name}');
        if (v.uiIsolate.name.indexOf(isolateFilter) == 0)
          result.add(port);
      }
    }
    return result;
  }

  void _validateArguments() {
    _fuchsiaRoot = argResults['fuchsia-root'];
    if (_fuchsiaRoot == null)
      throwToolExit('Please give the location of the Fuchsia tree with --fuchsia-root.');
    if (!_directoryExists(_fuchsiaRoot))
      throwToolExit('Specified --fuchsia-root "$_fuchsiaRoot" does not exist.');

    _address = argResults['address'];
    if (_address == null)
      throwToolExit('Give the address of the device running Fuchsia with --address.');

    final List<String> gnTarget = _extractPathAndName(argResults['gn-target']);
    _projectRoot = gnTarget[0];
    _projectName = gnTarget[1];
    _fuchsiaProjectPath = '$_fuchsiaRoot/$_projectRoot';
    if (!_directoryExists(_fuchsiaProjectPath))
      throwToolExit('Target does not exist in the Fuchsia tree: $_fuchsiaProjectPath.');

    final String relativeTarget = argResults['target'];
    if (relativeTarget == null)
      throwToolExit('Give the application entry point with --target.');
    _target = '$_fuchsiaProjectPath/$relativeTarget';
    if (!_fileExists(_target))
      throwToolExit('Couldn\'t find application entry point at $_target.');

    final String buildType = argResults['build-type'];
    if (buildType == null)
      throwToolExit('Give the build type with --build-type.');
    final String packagesFileName = '${_projectName}_dart_package.packages';
    _dotPackagesPath = '$_fuchsiaRoot/out/$buildType/gen/$_projectRoot/$packagesFileName';
    if (!_fileExists(_dotPackagesPath))
      throwToolExit('Couldn\'t find .packages file at $_dotPackagesPath.');

    final String nameOverride = argResults['name-override'];
    if (nameOverride == null) {
      _binaryName = _projectName;
    } else {
      _binaryName = nameOverride;
    }
  }

  List<String> _extractPathAndName(String gnTarget) {
    final String errorMessage =
      'fuchsia_reload --target "$gnTarget" should have the form: '
      '"//path/to/app:name"';
    // Separate strings like //path/to/target:app into [path/to/target, app]
    final int lastColon = gnTarget.lastIndexOf(':');
    if (lastColon < 0)
      throwToolExit(errorMessage);
    final String name = gnTarget.substring(lastColon + 1);
    // Skip '//' and chop off after :
    if ((gnTarget.length < 3) || (gnTarget[0] != '/') || (gnTarget[1] != '/'))
      throwToolExit(errorMessage);
    final String path = gnTarget.substring(2, lastColon);
    return <String>[path, name];
  }

  Future<List<int>> _getServicePorts() async {
    final FuchsiaDeviceCommandRunner runner = new FuchsiaDeviceCommandRunner(_fuchsiaRoot);
    final List<String> lsOutput = await runner.run('ls /tmp/dart.services');
    final List<int> ports = <int>[];
    for (String s in lsOutput) {
      final String trimmed = s.trim();
      final int lastSpace = trimmed.lastIndexOf(' ');
      final String lastWord = trimmed.substring(lastSpace + 1);
      if ((lastWord != '.') && (lastWord != '..')) {
        final int value = int.parse(lastWord, onError: (_) => null);
        if (value != null)
          ports.add(value);
      }
    }
    return ports;
  }

  bool _directoryExists(String path) {
    final Directory d = fs.directory(path);
    return d.existsSync();
  }

  bool _fileExists(String path) {
    final File f = fs.file(path);
    return f.existsSync();
  }
}


// TODO(zra): When Fuchsia has ssh, this should be changed to use that instead.
class FuchsiaDeviceCommandRunner {
  final String _fuchsiaRoot;
  final Random _rng = new Random(new DateTime.now().millisecondsSinceEpoch);

  FuchsiaDeviceCommandRunner(this._fuchsiaRoot);

  Future<List<String>> run(String command) async {
    final int tag = _rng.nextInt(999999);
    const String kNetRunCommand = 'out/build-magenta/tools/netruncmd';
    final String netruncmd = fs.path.join(_fuchsiaRoot, kNetRunCommand);
    const String kNetCP = 'out/build-magenta/tools/netcp';
    final String netcp = fs.path.join(_fuchsiaRoot, kNetCP);
    final String remoteStdout = '/tmp/netruncmd.$tag';
    final String localStdout = '${fs.systemTempDirectory.path}/netruncmd.$tag';
    final String redirectedCommand = '$command > $remoteStdout';
    // Run the command with output directed to a tmp file.
    ProcessResult result =
        await Process.run(netruncmd, <String>[':', redirectedCommand]);
    if (result.exitCode != 0)
      return null;
    // Copy that file to the local filesystem.
    result = await Process.run(netcp, <String>[':$remoteStdout', localStdout]);
    // Try to delete the remote file. Don't care about the result;
    Process.run(netruncmd, <String>[':', 'rm $remoteStdout']);
    if (result.exitCode != 0)
      return null;
    // Read the local file.
    final File f = fs.file(localStdout);
    List<String> lines;
    try {
      lines = await f.readAsLines();
    } finally {
      f.delete();
    }
    return lines;
  }
}
