import 'dart:typed_data';

import '../../formats/formats.dart';
import '../command.dart';

// Decode a Psd Image from byte [data].
class DecodePsdCmd extends Command {
  Uint8List data;

  DecodePsdCmd(Command? input, this.data) : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    outputImage = decodePsd(data);
  }
}

// Decode a Psd from a file at the given [path].
class DecodePsdFileCmd extends Command {
  String path;

  DecodePsdFileCmd(Command? input, this.path) : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    outputImage = await decodePsdFile(path);
  }
}
