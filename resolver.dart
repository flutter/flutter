import 'dart:io';

void main() {
  var result = Process.runSync('git', ['diff', '--name-only', '--diff-filter=U']);
  var files = result.stdout.toString().split('\n').where((l) => l.isNotEmpty).toList();
  for (var file in files) {
    if (file.isEmpty) continue;
    var lines = File(file).readAsLinesSync();
    var out = <String>[];
    int i = 0;
    while(i < lines.length) {
      if (lines[i].startsWith('<<<<<<< HEAD')) {
        int headStart = i + 1;
        while (!lines[i].startsWith('=======')) i++;
        int headEnd = i;
        int theirsStart = i + 1;
        while (!lines[i].startsWith('>>>>>>>')) i++;
        int theirsEnd = i;
        
        var headBlock = lines.sublist(headStart, headEnd);
        var theirsBlock = lines.sublist(theirsStart, theirsEnd);
        
        var mergedBlock = List<String>.from(headBlock);
        
        bool replaceCache = false;
        String cacheReplacement = '';
        for (var line in theirsBlock) {
          if (line.contains('globals.cache.flutterRoot')) cacheReplacement = 'globals.cache.flutterRoot';
          else if (line.contains('cache.flutterRoot')) cacheReplacement = 'cache.flutterRoot';
          else if (line.contains('environment.flutterRootDir')) cacheReplacement = 'environment.flutterRootDir';
        }
        
        if (cacheReplacement.isNotEmpty) {
           for (int j = 0; j < mergedBlock.length; j++) {
             mergedBlock[j] = mergedBlock[j].replaceAll('Cache.flutterRoot', cacheReplacement);
           }
        }
        
        if (file.contains('executable.dart')) {
           for (var line in theirsBlock) {
             if (line.contains('import ')) {
               if (!mergedBlock.any((l) => l.trim() == line.trim())) {
                 mergedBlock.add(line);
               }
             }
           }
        }
        
        out.addAll(mergedBlock); 
      } else {
        out.add(lines[i]);
      }
      i++;
    }
    File(file).writeAsStringSync(out.join('\n') + '\n');
  }
}
