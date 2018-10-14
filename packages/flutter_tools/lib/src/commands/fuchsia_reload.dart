// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/process_manager.dart';
import '../base/terminal.dart';
import '../base/utils.dart';
import '../bundle.dart' as bundle;
import '../cache.dart';
import '../device.dart';
import '../fuchsia/fuchsia_device.dart';
import '../globals.dart';
import '../resident_runner.dart';
import '../run_hot.dart';
import '../runner/flutter_command.dart';
import '../vmservice.dart';

// Usage:
// With e.g. hello_mod already running, a HotRunner can be attached to it.
//
// From a Fuchsia in-tree build:
// $ flutter fuchsia_reload --address 192.168.1.39 \
//       --build-dir ~/fuchsia/out/x64 \
//       --gn-target //topaz/examples/ui/hello_mod:hello_mod
//
// From out of tree:
// $ flutter fuchsia_reload --address 192.168.1.39 \
//       --mod_name hello_mod \
//       --path /path/to/hello_mod
//       --dot-packages /path/to/hello_mod_out/app.packages \
//       --ssh-config /path/to/ssh_config \
//       --target /path/to/hello_mod/lib/main.dart

final String ipv4Loopback = InternetAddress.loopbackIPv4.address;

class FuchsiaReloadCommand extends FlutterCommand {
  FuchsiaReloadCommand() {
    addBuildModeFlags(defaultToRelease: false);
    argParser.addOption('address',
      abbr: 'a',
      help: 'Fuchsia device network name or address.');
    argParser.addOption('build-dir',
      abbr: 'b',
      defaultsTo: null,
      help: 'Fuchsia build directory, e.g. out/release-x86-64.');
    argParser.addOption('dot-packages',
      abbr: 'd',
      defaultsTo: null,
      help: 'Path to the mod\'s .packages file. Required if no'
            'GN target specified.');
    argParser.addOption('gn-target',
      abbr: 'g',
      help: 'GN target of the application, e.g //path/to/app:app.');
    argParser.addOption('isolate-number',
      abbr: 'i',
      help: 'To reload only one instance, specify the isolate number, e.g. '
            'the number in foo\$main-###### given by --list.');
    argParser.addFlag('list',
      abbr: 'l',
      defaultsTo: false,
      help: 'Lists the running modules. ');
    argParser.addOption('mod-name',
      abbr: 'm',
      help: 'Name of the flutter mod. If used with -g, overrides the name '
            'inferred from the GN target.');
    argParser.addOption('path',
      abbr: 'p',
      defaultsTo: null,
      help: 'Path to the flutter mod project.');
    argParser.addOption('ssh-config',
      abbr: 's',
      defaultsTo: null,
      help: 'Path to the Fuchsia target\'s ssh config file.');
    argParser.addOption('target',
      abbr: 't',
      defaultsTo: bundle.defaultMainPath,
      help: 'Target app path / main entry-point file. '
            'Relative to --path or --gn-target path, e.g. lib/main.dart.');
  }

  @override
  final String name = 'fuchsia_reload';

  @override
  final String description = 'Hot reload on Fuchsia.';

  String _modName;
  String _isolateNumber;
  String _fuchsiaProjectPath;
  String _target;
  String _address;
  String _dotPackagesPath;
  String _sshConfig;

  bool _list;

  @override
  Future<FlutterCommandResult> runCommand() async {
    Cache.releaseLockEarly();

    await _validateArguments();

    // Find the network ports used on the device by VM service instances.
    final List<int> deviceServicePorts = await _getServicePorts();
    if (deviceServicePorts.isEmpty)
      throwToolExit('Couldn\'t find any running Observatory instances.');
    for (int port in deviceServicePorts)
      printTrace('Fuchsia service port: $port');

    // Set up ssh tunnels to forward the device ports to local ports.
    final List<_PortForwarder> forwardedPorts = await _forwardPorts(
        deviceServicePorts);
    // Wrap everything in try/finally to make sure we kill the ssh processes
    // doing the port forwarding.
    try {
      final List<int> servicePorts = forwardedPorts.map<int>(
          (_PortForwarder pf) => pf.port).toList();

      if (_list) {
        await _listVMs(servicePorts);
        // Port forwarding stops when the command ends. Keep the program running
        // until directed by the user so that Observatory URLs that we print
        // continue to work.
        printStatus('Press Enter to exit.');
        await stdin.first;
        return null;
      }

      // Check that there are running VM services on the returned
      // ports, and find the Isolates that are running the target app.
      final String isolateName = '$_modName\$main$_isolateNumber';
      final List<int> targetPorts = await _filterPorts(
          servicePorts, isolateName);
      if (targetPorts.isEmpty)
        throwToolExit('No VMs found running $_modName.');
      for (int port in targetPorts)
        printTrace('Found $_modName at $port');

      // Set up a device and hot runner and attach the hot runner to the first
      // vm service we found.
      final List<String> fullAddresses = targetPorts.map<String>(
        (int p) => '$ipv4Loopback:$p'
      ).toList();
      final List<Uri> observatoryUris = fullAddresses.map<Uri>(
        (String a) => Uri.parse('http://$a')
      ).toList();
      final FuchsiaDevice device = FuchsiaDevice(
          fullAddresses[0], name: _address);
      final FlutterDevice flutterDevice = FlutterDevice(
        device,
        trackWidgetCreation: false,
      );
      flutterDevice.observatoryUris = observatoryUris;
      final HotRunner hotRunner = HotRunner(
        <FlutterDevice>[flutterDevice],
        debuggingOptions: DebuggingOptions.enabled(getBuildInfo()),
        target: _target,
        projectRootPath: _fuchsiaProjectPath,
        packagesFilePath: _dotPackagesPath
      );
      printStatus('Connecting to $_modName');
      await hotRunner.attach(viewFilter: isolateName);
    } finally {
      await Future.wait<void>(forwardedPorts.map<Future<void>>((_PortForwarder pf) => pf.stop()));
    }

    return null;
  }

  // A cache of VMService connections.
  final HashMap<int, VMService> _vmServiceCache = HashMap<int, VMService>();

  Future<VMService> _getVMService(int port) async {
    if (!_vmServiceCache.containsKey(port)) {
      final String addr = 'http://$ipv4Loopback:$port';
      final Uri uri = Uri.parse(addr);
      final VMService vmService = await VMService.connect(uri);
      _vmServiceCache[port] = vmService;
    }
    return _vmServiceCache[port];
  }

  Future<List<FlutterView>> _getViews(List<int> ports) async {
    final List<FlutterView> views = <FlutterView>[];
    for (int port in ports) {
      final VMService vmService = await _getVMService(port);
      await vmService.getVM();
      await vmService.refreshViews();
      views.addAll(vmService.vm.views);
    }
    return views;
  }

  // Find ports where there is a view isolate with the given name
  Future<List<int>> _filterPorts(List<int> ports, String viewFilter) async {
    printTrace('Looing for view $viewFilter');
    final List<int> result = <int>[];
    for (FlutterView v in await _getViews(ports)) {
      if (v.uiIsolate == null)
        continue;
      final Uri addr = v.owner.vmService.httpAddress;
      printTrace('At $addr, found view: ${v.uiIsolate.name}');
      if (v.uiIsolate.name.contains(viewFilter))
        result.add(addr.port);
    }
    return result;
  }

  String _vmServiceToString(VMService vmService, {int tabDepth = 0}) {
    final Uri addr = vmService.httpAddress;
    final String embedder = vmService.vm.embedder;
    final int numIsolates = vmService.vm.isolates.length;
    final String maxRSS = getSizeAsMB(vmService.vm.maxRSS);
    final String heapSize = getSizeAsMB(vmService.vm.heapAllocatedMemoryUsage);
    int totalNewUsed = 0;
    int totalNewCap = 0;
    int totalOldUsed = 0;
    int totalOldCap = 0;
    int totalExternal = 0;
    for (Isolate i in vmService.vm.isolates) {
      totalNewUsed += i.newSpace.used;
      totalNewCap += i.newSpace.capacity;
      totalOldUsed += i.oldSpace.used;
      totalOldCap += i.oldSpace.capacity;
      totalExternal += i.newSpace.external;
      totalExternal += i.oldSpace.external;
    }
    final String newUsed = getSizeAsMB(totalNewUsed);
    final String newCap = getSizeAsMB(totalNewCap);
    final String oldUsed = getSizeAsMB(totalOldUsed);
    final String oldCap = getSizeAsMB(totalOldCap);
    final String external = getSizeAsMB(totalExternal);
    final String tabs = '\t' * tabDepth;
    final String extraTabs = '\t' * (tabDepth + 1);
    final StringBuffer stringBuffer = StringBuffer(
      '$tabs${terminal.bolden('$embedder at $addr')}\n'
      '${extraTabs}RSS: $maxRSS\n'
      '${extraTabs}Native allocations: $heapSize\n'
      '${extraTabs}New Spaces: $newUsed of $newCap\n'
      '${extraTabs}Old Spaces: $oldUsed of $oldCap\n'
      '${extraTabs}External: $external\n'
      '${extraTabs}Isolates: $numIsolates\n'
    );
    for (Isolate isolate in vmService.vm.isolates) {
      stringBuffer.write(_isolateToString(isolate, tabDepth: tabDepth + 1));
    }
    return stringBuffer.toString();
  }

  String _isolateToString(Isolate isolate, {int tabDepth = 0}) {
    final Uri vmServiceAddr = isolate.owner.vmService.httpAddress;
    final String name = isolate.name;
    final String shortName = name.substring(0, name.indexOf('\$'));
    const String main = '\$main-';
    final String number = name.substring(name.indexOf(main) + main.length);

    // The Observatory requires somewhat non-standard URIs that the Uri class
    // can't build for us, so instead we build them by hand.
    final String isolateIdQuery = '?isolateId=isolates%2F$number';
    final String isolateAddr = '$vmServiceAddr/#/inspect$isolateIdQuery';
    final String debuggerAddr = '$vmServiceAddr/#/debugger$isolateIdQuery';

    final String newUsed = getSizeAsMB(isolate.newSpace.used);
    final String newCap = getSizeAsMB(isolate.newSpace.capacity);
    final String newFreq = '${isolate.newSpace.avgCollectionTime.inMilliseconds}ms';
    final String newPer = '${isolate.newSpace.avgCollectionPeriod.inSeconds}s';
    final String oldUsed = getSizeAsMB(isolate.oldSpace.used);
    final String oldCap = getSizeAsMB(isolate.oldSpace.capacity);
    final String oldFreq = '${isolate.oldSpace.avgCollectionTime.inMilliseconds}ms';
    final String oldPer = '${isolate.oldSpace.avgCollectionPeriod.inSeconds}s';
    final String external = getSizeAsMB(isolate.newSpace.external + isolate.oldSpace.external);
    final String tabs = '\t' * tabDepth;
    final String extraTabs = '\t' * (tabDepth + 1);
    return
      '$tabs${terminal.bolden(shortName)}\n'
      '${extraTabs}Isolate number: $number\n'
      '${extraTabs}Observatory: $isolateAddr\n'
      '${extraTabs}Debugger: $debuggerAddr\n'
      '${extraTabs}New gen: $newUsed used of $newCap, GC: $newFreq every $newPer\n'
      '${extraTabs}Old gen: $oldUsed used of $oldCap, GC: $oldFreq every $oldPer\n'
      '${extraTabs}External: $external\n';
  }

  Future<void> _listVMs(List<int> ports) async {
    for (int port in ports) {
      final VMService vmService = await _getVMService(port);
      await vmService.getVM();
      await vmService.refreshViews();
      printStatus(_vmServiceToString(vmService));
    }
  }

  Future<void> _validateArguments() async {
    final String fuchsiaBuildDir = argResults['build-dir'];
    final String gnTarget = argResults['gn-target'];

    if (fuchsiaBuildDir != null) {
      if (gnTarget == null)
        throwToolExit('Must provide --gn-target when specifying --build-dir.');

      if (!_directoryExists(fuchsiaBuildDir))
        throwToolExit('Specified --build-dir "$fuchsiaBuildDir" does not exist.');

      _sshConfig = '$fuchsiaBuildDir/ssh-keys/ssh_config';
    }

    // If sshConfig path not available from the fuchsiaBuildDir, get from command line.
    _sshConfig ??= argResults['ssh-config'];
    if (_sshConfig == null)
      throwToolExit('Provide the path to the ssh config file with --ssh-config.');
    if (!_fileExists(_sshConfig))
      throwToolExit('Couldn\'t find ssh config file at $_sshConfig.');

    _address = argResults['address'];
    if (_address == null && fuchsiaBuildDir != null) {
      final ProcessResult result = await processManager.run(<String>['fx', 'netaddr', '--fuchsia']);
      if (result.exitCode == 0)
        _address = result.stdout.trim();
      else
        printStatus('netaddr failed:\nstdout: ${result.stdout}\nstderr: ${result.stderr}');
    }
    if (_address == null)
      throwToolExit('Give the address of the device running Fuchsia with --address.');

    _list = argResults['list'];
    if (_list) {
      // For --list, we only need the ssh config and device address.
      return;
    }

    String projectRoot;
    if (gnTarget != null) {
      if (fuchsiaBuildDir == null)
        throwToolExit('Must provide --build-dir when specifying --gn-target.');

      final List<String> targetInfo = _extractPathAndName(gnTarget);
      projectRoot = targetInfo[0];
      _modName = targetInfo[1];
      _fuchsiaProjectPath = '$fuchsiaBuildDir/../../$projectRoot';
    } else if (argResults['path'] != null) {
      _fuchsiaProjectPath = argResults['path'];
    }

    if (_fuchsiaProjectPath == null)
      throwToolExit('Provide the mod project path with --path.');
    if (!_directoryExists(_fuchsiaProjectPath))
      throwToolExit('Cannot locate project at $_fuchsiaProjectPath.');

    final String relativeTarget = argResults['target'];
    if (relativeTarget == null)
      throwToolExit('Give the application entry point with --target.');
    _target = '$_fuchsiaProjectPath/$relativeTarget';
    if (!_fileExists(_target))
      throwToolExit('Couldn\'t find application entry point at $_target.');

    if (argResults['mod-name'] != null)
      _modName = argResults['mod-name'];
    if (_modName == null)
      throwToolExit('Provide the mod name with --mod-name.');

    if (argResults['dot-packages'] != null) {
      _dotPackagesPath = argResults['dot-packages'];
    } else if (fuchsiaBuildDir != null) {
      final String packagesFileName = '${_modName}_dart_library.packages';
      _dotPackagesPath = '$fuchsiaBuildDir/dartlang/gen/$projectRoot/$packagesFileName';
    }
    if (_dotPackagesPath == null)
      throwToolExit('Provide the .packages path with --dot-packages.');
    if (!_fileExists(_dotPackagesPath))
      throwToolExit('Couldn\'t find .packages file at $_dotPackagesPath.');

    final String isolateNumber = argResults['isolate-number'];
    if (isolateNumber == null) {
      _isolateNumber = '';
    } else {
      _isolateNumber = '-$isolateNumber';
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

  Future<List<_PortForwarder>> _forwardPorts(List<int> remotePorts) async {
    final List<_PortForwarder> forwarders = <_PortForwarder>[];
    for (int port in remotePorts) {
      final _PortForwarder f =
          await _PortForwarder.start(_sshConfig, _address, port);
      forwarders.add(f);
    }
    return forwarders;
  }

  Future<List<int>> _getServicePorts() async {
    final FuchsiaDeviceCommandRunner runner =
        FuchsiaDeviceCommandRunner(_address, _sshConfig);
    final List<String> lsOutput = await runner.run('ls /tmp/dart.services');
    final List<int> ports = <int>[];
    if (lsOutput != null) {
      for (String s in lsOutput) {
        final String trimmed = s.trim();
        final int lastSpace = trimmed.lastIndexOf(' ');
        final String lastWord = trimmed.substring(lastSpace + 1);
        if ((lastWord != '.') && (lastWord != '..')) {

          final int value = int.tryParse(lastWord);
          if (value != null)
            ports.add(value);
        }
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

// Instances of this class represent a running ssh tunnel from the host to a
// VM service running on a Fuchsia device. [process] is the ssh process running
// the tunnel and [port] is the local port.
class _PortForwarder {
  _PortForwarder._(this._remoteAddress,
                   this._remotePort,
                   this._localPort,
                   this._process,
                   this._sshConfig);

  final String _remoteAddress;
  final int _remotePort;
  final int _localPort;
  final Process _process;
  final String _sshConfig;

  int get port => _localPort;

  static Future<_PortForwarder> start(String sshConfig,
                                      String address,
                                      int remotePort) async {
    final int localPort = await _potentiallyAvailablePort();
    if (localPort == 0) {
      printStatus(
          '_PortForwarder failed to find a local port for $address:$remotePort');
      return _PortForwarder._(null, 0, 0, null, null);
    }
    const String dummyRemoteCommand = 'date';
    final List<String> command = <String>[
        'ssh', '-F', sshConfig, '-nNT', '-vvv', '-f',
        '-L', '$localPort:$ipv4Loopback:$remotePort', address, dummyRemoteCommand];
    printTrace("_PortForwarder running '${command.join(' ')}'");
    final Process process = await processManager.start(command);
    process.stderr
        .transform<String>(utf8.decoder)
        .transform<String>(const LineSplitter())
        .listen((String data) { printTrace(data); });
    // Best effort to print the exit code.
    process.exitCode.then<void>((int c) { // ignore: unawaited_futures
      printTrace("'${command.join(' ')}' exited with exit code $c");
    });
    printTrace('Set up forwarding from $localPort to $address:$remotePort');
    return _PortForwarder._(address, remotePort, localPort, process, sshConfig);
  }

  Future<void> stop() async {
    // Kill the original ssh process if it is still around.
    if (_process != null) {
      printTrace('_PortForwarder killing ${_process.pid} for port $_localPort');
      _process.kill();
    }
    // Cancel the forwarding request.
    final List<String> command = <String>[
        'ssh', '-F', _sshConfig, '-O', 'cancel', '-vvv',
        '-L', '$_localPort:$ipv4Loopback:$_remotePort', _remoteAddress];
    final ProcessResult result = await processManager.run(command);
    printTrace(command.join(' '));
    if (result.exitCode != 0) {
      printTrace('Command failed:\nstdout: ${result.stdout}\nstderr: ${result.stderr}');
    }
  }

  static Future<int> _potentiallyAvailablePort() async {
    int port = 0;
    ServerSocket s;
    try {
      s = await ServerSocket.bind(ipv4Loopback, 0);
      port = s.port;
    } catch (e) {
      // Failures are signaled by a return value of 0 from this function.
      printTrace('_potentiallyAvailablePort failed: $e');
    }
    if (s != null)
      await s.close();
    return port;
  }
}

class FuchsiaDeviceCommandRunner {
  FuchsiaDeviceCommandRunner(this._address, this._sshConfig);

  final String _address;
  final String _sshConfig;

  Future<List<String>> run(String command) async {
    final List<String> args = <String>['ssh', '-F', _sshConfig, _address, command];
    printTrace(args.join(' '));
    final ProcessResult result = await processManager.run(args);
    if (result.exitCode != 0) {
      printStatus('Command failed: $command\nstdout: ${result.stdout}\nstderr: ${result.stderr}');
      return null;
    }
    printTrace(result.stdout);
    return result.stdout.split('\n');
  }
}
