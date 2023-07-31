import 'dart:convert';
import 'dart:io';

String getShellCmdBinFileName(String command) =>
    '$command${Platform.isWindows ? '.bat' : ''}';

//
// [data] can be map a list
// if it is a string, it will try to parse it first
//
String? jsonPretty(dynamic data) {
  if (data is String) {
    dynamic parsed = jsonDecode(data);
    if (parsed != null) {
      data = parsed;
    }
  }
  if (data != null) {
    try {
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (e) {
      return ('Err: $e decoding $data');
    }
  }
  return null;
}
