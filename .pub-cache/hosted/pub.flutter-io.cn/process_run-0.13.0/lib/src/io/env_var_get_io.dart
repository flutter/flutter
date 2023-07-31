import 'package:process_run/shell.dart';

class ShellEnvVarGetIoHelper {
  ShellEnvVarGetIoHelper();

  Map<String, String> getMulti(List<String> keys) {
    Map<String, String> map = ShellEnvironment().vars;
    map = Map<String, String>.from(map)
      ..removeWhere((key, value) => !keys.contains(key));
    return map;
  }

  String? get(String key) {
    var value = ShellEnvironment().vars[key];
    return value;
  }
}
