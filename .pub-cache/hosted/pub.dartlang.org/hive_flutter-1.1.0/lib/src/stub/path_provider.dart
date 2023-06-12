abstract class Directory {
  String get path;
}

Future<Directory> getApplicationDocumentsDirectory() {
  throw UnimplementedError(
    '[Hive Error] Tried to use the `path_provider` package from Flutter Web.',
  );
}
