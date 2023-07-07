import 'dart:typed_data';

import '../../formats/formats.dart';
import '../command.dart';

// Decode a Exr Image from byte [data].
class DecodeExrCmd extends Command {
  Uint8List data;

  DecodeExrCmd(Command? input, this.data) : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    outputImage = decodeExr(data);
  }
}

// Decode a Exr from a file at the given [path].
class DecodeExrFileCmd extends Command {
  String path;

  DecodeExrFileCmd(Command? input, this.path) : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    outputImage = await decodeExrFile(path);
  }
}
