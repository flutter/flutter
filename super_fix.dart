import 'dart:io';

void replace(String file, String from, String to) {
  var f = File(file);
  if (!f.existsSync()) return;
  var content = f.readAsStringSync();
  f.writeAsStringSync(content.replaceAll(from, to));
}

void main() {
  // run_hot.dart
  replace('packages/flutter_tools/lib/src/run_hot.dart', 'analytics.send(', 'globals.analytics.send(');
  replace('packages/flutter_tools/lib/src/run_hot.dart', 'analytics,', 'globals.analytics,');
  replace('packages/flutter_tools/lib/src/run_hot.dart', 'platform.isWindows', 'globals.platform.isWindows');
  replace('packages/flutter_tools/lib/src/run_hot.dart', 'logger = flutterDevices.firstOrNull?.logger', 'logger = flutterDevices.firstOrNull?.device?.logger'); // Wait, FlutterDevice doesn't have logger! Wait! FlutterDevice is from resident_runner.dart, which has a bunch of fields but not logger. Let's just use globals.logger!
  replace('packages/flutter_tools/lib/src/run_hot.dart', 'flutterDevices.firstOrNull?.logger ?? BufferLogger.test()', 'globals.logger');
  replace('packages/flutter_tools/lib/src/run_hot.dart', 'await cacheInitialDillCompilation();', '');
  replace('packages/flutter_tools/lib/src/run_hot.dart', 'super.artifacts,', '');

  // run_cold.dart
  replace('packages/flutter_tools/lib/src/run_cold.dart', 'super.artifacts,', '');
  replace('packages/flutter_tools/lib/src/run_cold.dart', 'platform.environment', 'globals.platform.environment');
  replace('packages/flutter_tools/lib/src/run_cold.dart', '_globals.platform.isWindows', 'globals.platform.isWindows');

  // command run
  replace('packages/flutter_tools/lib/src/commands/run.dart', 'analytics: analytics,', '');

  // coverage collector
  replace('packages/flutter_tools/lib/src/commands/test.dart', 'collector = CoverageCollector(', 'collector = CoverageCollector(fileSystem: globals.fs, ');

  // upgrade
  replace('packages/flutter_tools/lib/src/commands/upgrade.dart', 'Cache.flutterRoot!', 'globals.cache.flutterRoot');

  // experimental templates
  replace('packages/flutter_tools/lib/src/experimental/templates.dart', 'Cache.flutterRoot!', 'globals.cache.flutterRoot');

  // resident web runner
  replace('packages/flutter_tools/lib/src/isolated/resident_web_runner.dart', 'fileSystem: fileSystem,', 'fileSystem: globals.fs,');
  replace('packages/flutter_tools/lib/src/isolated/resident_web_runner.dart', 'unawaited(cacheInitialDillCompilation());', '');
  replace('packages/flutter_tools/lib/src/isolated/resident_web_runner.dart', 'cache?.flutterRoot', 'globals.cache.flutterRoot');

  // resident runner
  replace('packages/flutter_tools/lib/src/resident_runner.dart', 'static Future<FlutterDevice> create(', 'static Future<FlutterDevice> create({');
  replace('packages/flutter_tools/lib/src/resident_runner.dart', 'logger.printWarning', 'globals.logger.printWarning');

}
