import 'dart:io';

void replace(String file, String from, String to) {
  var f = File(file);
  var content = f.readAsStringSync();
  f.writeAsStringSync(content.replaceAll(from, to));
}

void main() {
  // run_hot.dart
  replace('packages/flutter_tools/lib/src/run_hot.dart', 'analytics.send(', 'globals.analytics.send(');
  replace('packages/flutter_tools/lib/src/run_hot.dart', 'analytics,', 'globals.analytics,');
  replace('packages/flutter_tools/lib/src/run_hot.dart', 'platform.isWindows', 'globals.platform.isWindows');
  replace('packages/flutter_tools/lib/src/run_hot.dart', 'await cacheInitialDillCompilation();', '');

  // resident_runner.dart
  replace('packages/flutter_tools/lib/src/resident_runner.dart', 'logger.printTrace', 'globals.logger.printTrace');

  // test/runner.dart
  var r = File('packages/flutter_tools/lib/src/test/runner.dart');
  var runnerText = r.readAsStringSync();
  runnerText = runnerText.replaceAll(r'final Config _config;', r'');
  runnerText = runnerText.replaceAll(r'final Logger _logger;', r'');
  runnerText = runnerText.replaceAll(r'final OperatingSystemUtils _os;', r'');
  runnerText = runnerText.replaceAll(r'final Platform _platform;', r'');
  runnerText = runnerText.replaceAll(r'final ProcessManager _processManager;', r'');
  runnerText = runnerText.replaceAll(r'final ShutdownHooks _shutdownHooks;', r'');
  runnerText = runnerText.replaceAll(r'final AnsiTerminal _terminal;', r'');
  runnerText = runnerText.replaceAll(r'required Config config,', r'');
  runnerText = runnerText.replaceAll(r'required Logger logger,', r'');
  runnerText = runnerText.replaceAll(r'required OperatingSystemUtils os,', r'');
  runnerText = runnerText.replaceAll(r'required Platform platform,', r'');
  runnerText = runnerText.replaceAll(r'required ProcessManager processManager,', r'');
  runnerText = runnerText.replaceAll(r'required ShutdownHooks shutdownHooks,', r'');
  runnerText = runnerText.replaceAll(r'required AnsiTerminal terminal,', r'');
  runnerText = runnerText.replaceAll(r'_config = config,', r'');
  runnerText = runnerText.replaceAll(r'_logger = logger,', r'');
  runnerText = runnerText.replaceAll(r'_os = os,', r'');
  runnerText = runnerText.replaceAll(r'_platform = platform,', r'');
  runnerText = runnerText.replaceAll(r'_processManager = processManager,', r'');
  runnerText = runnerText.replaceAll(r'_shutdownHooks = shutdownHooks,', r'');
  runnerText = runnerText.replaceAll(r'_terminal = terminal,', r'');
  
  // Also remove it from super calls
  runnerText = runnerText.replaceAll(r'fileSystem: fileSystem,', r'');
  runnerText = runnerText.replaceAll(r'platform: platform,', r'');
  r.writeAsStringSync(runnerText);
  
}
