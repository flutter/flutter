import 'dart:io';

void main() {
  var result = Process.runSync('grep', ['-rl', r'Cache.flutterRoot', 'packages/flutter_tools/test']);
  var files = result.stdout.toString().split('\n').where((l) => l.isNotEmpty).toList();
  for (var file in files) {
    if (file.contains('.yaml') || file.contains('.json')) continue;
    var f = File(file);
    var content = f.readAsStringSync();
    
    // Add globals import if missing
    if (!content.contains('globals.dart')) {
      // Find where to insert import. After the last package/dart import.
      content = "import 'package:flutter_tools/src/globals.dart' as globals;\n" + content;
    }
    content = content.replaceAll(r'Cache.flutterRoot!', r'globals.cache.flutterRoot');
    content = content.replaceAll(r'Cache.flutterRoot', r'globals.cache.flutterRoot');
    f.writeAsStringSync(content);
    print('Fixed $file');
  }
}
