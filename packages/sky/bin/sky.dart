import 'dart:io' show Platform;

void main() {
  var uri = Platform.script;
  print(uri);
  var path = uri.toFilePath();
  print(path);
}