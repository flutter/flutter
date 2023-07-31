import 'dart:io';

void dumpStringMap(Map<String, String> map) {
  var keys = map.keys.toList()
    ..sort((t1, t2) => t1.toLowerCase().compareTo(t2.toLowerCase()));
  for (var key in keys) {
    var value = map[key];
    stdout.writeln('$key: $value');
  }
}

void dumpStringList(List<String?> list) {
  for (var item in list) {
    stdout.writeln('$item');
  }
}
