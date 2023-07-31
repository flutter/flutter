import 'dart:convert';

import 'package:process_run/shell.dart';
import 'package:process_run/src/bin/shell/env_file_content.dart';
import 'package:process_run/src/user_config.dart';

class ShellEnvIoHelper {
  final Shell shell;
  final bool local;
  final bool verbose;

  ShellEnvIoHelper(
      {required this.shell, required this.local, required this.verbose});

  String get label => local ? 'local' : 'user';

  Future<EnvFileContent> envFileReadOrCreate({bool write = false}) async {
    var fileContent = EnvFileContent(_envFilePath!);
    if (!await fileContent.read()) {
      fileContent.lines = sampleFileContent;
    }
    if (write) {
      await fileContent.write();
    }
    return fileContent;
  }

  String? get envFilePath => _envFilePath;

  String? get _envFilePath => local
      ? getLocalEnvFilePath(shell.options.environment)
      : getUserEnvFilePath(shell.options.environment);

  List<String>? _sampleFileContent;

  List<String> get sampleFileContent => _sampleFileContent ??= () {
        var content = local
            ? '''
# Local Environment path and variable for `Shell.run` calls.
#
# `path(s)` is a list of path, `var(s)` is a key/value map.
#
# Content example. See <https://github.com/tekartik/process_run.dart/blob/master/packages/process_run/doc/user_config.md> for more information
#
# path:
#   - ./local
#   - bin/
# var:
#   MY_PWD: my_password
#   MY_USER: my user
# alias:
#   qr: /path/to/my_qr_app
  '''
            : '''
# Environment path and variable for `Shell.run` calls.
#
# `path` is a list of path, `var` is a key/value map.
#
# Content example. See <https://github.com/tekartik/process_run.dart/blob/master/packages/process_run/doc/user_config.md> for more information
#
# path:
#   - ~/Android/Sdk/tools/bin
#   - ~/Android/Sdk/platform-tools
#   - ~/.gem/bin/
#   - ~/.pub-cache/bin
# var:
#   ANDROID_TOP: ~/.android
#   FLUTTER_BIN: ~/.flutter/bin
# alias:
#   qr: /path/to/my_qr_app

''';

        return LineSplitter.split(content).toList();
      }();
}
