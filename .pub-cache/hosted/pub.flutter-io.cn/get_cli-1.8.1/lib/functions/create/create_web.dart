import 'dart:io';

Future<File> getOnlineModel(String path, String url) async {
  final file = File(path);

  // await file.writeAsString(BindingSample().file(await read(url)));
  // BindingSample().file(await read('https://example.com/foobar.txt')));
  return file;
}
