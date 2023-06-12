import 'dart:typed_data';

import '../../formats/formats.dart';
import '../command.dart';

// Decode a WebP Image from byte [data].
class DecodeWebPCmd extends Command {
  Uint8List data;

  DecodeWebPCmd(Command? input, this.data) : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    outputImage = decodeWebP(data);
  }
}

// Decode a WebP from a file at the given [path].
class DecodeWebPFileCmd extends Command {
  String path;

  DecodeWebPFileCmd(Command? input, this.path) : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    outputImage = await decodeWebPFile(path);
  }
}
