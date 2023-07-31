import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart';

class CliConfig {
  static final DateFormat _formatter = DateFormat('yyyy-MM-dd');
  // Em devsevolvimento
  static File getFileConfig() {
    var scriptFile = Platform.script.toFilePath();
    var path = join(dirname(scriptFile), '.get_cli.yaml');
    var configFile = File(path);
    if (!configFile.existsSync()) {
      configFile.createSync(recursive: true);
    }
    return configFile;
  }

  static void setUpdateCheckToday() {
    final now = DateTime.now();

    final formatted = _formatter.format(now);
    var configFile = getFileConfig();
    var lines = configFile.readAsLinesSync();
    var lastUpdateIndex = lines.indexWhere(
      (element) => element.startsWith('last_update_check:'),
    );
    if (lastUpdateIndex != -1) {
      lines.removeAt(lastUpdateIndex);
    }

    lines.add('last_update_check: $formatted');
    configFile.writeAsStringSync(lines.join('\n'));
  }

  static bool updateIsCheckingToday() {
    var configFile = getFileConfig();

    var lines = configFile.readAsLinesSync();
    var lastUpdateIndex = lines.indexWhere(
      (element) => element.startsWith('last_update_check:'),
    );
    if (lines.isEmpty || lastUpdateIndex == -1) {
      return false;
    }
    var dateLatsUpdate = lines[lastUpdateIndex].split(':').last.trim();
    var now = _formatter.parse(_formatter.format(DateTime.now()));

    return _formatter.parse(dateLatsUpdate) == now;
  }
}
