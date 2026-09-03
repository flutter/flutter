import 'dart:io';

void main() {
  var file = File('packages/flutter_tools/lib/src/commands/channel.dart');
  var text = file.readAsStringSync();
  text = text.replaceAll('workingDirectory: Cache.flutterRoot', 'workingDirectory: flutterRoot');
  file.writeAsStringSync(text);
}
