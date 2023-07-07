import 'dart:typed_data';

import '../../formats/formats.dart';
import '../command.dart';

// Decode a BMP Image from byte [data].
class DecodeBmpCmd extends Command {
  Uint8List data;

  DecodeBmpCmd(Command? input, this.data) : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    outputImage = decodeBmp(data);
  }
}

// Decode a BMP from a file at the given [path].
class DecodeBmpFileCmd extends Command {
  String path;

  DecodeBmpFileCmd(Command? input, this.path) : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    outputImage = await decodeBmpFile(path);
  }
}

// Encode an Image to the BMP format.
class EncodeBmpCmd extends Command {
  EncodeBmpCmd(Command? input) : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    outputImage = input?.outputImage;
    if (outputImage != null) {
      outputBytes = encodeBmp(outputImage!);
    }
  }
}

// Encode an Image to the BMP format and write it to a file at the given
// [path].
class EncodeBmpFileCmd extends Command {
  String path;

  EncodeBmpFileCmd(Command? input, this.path) : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    outputImage = input?.outputImage;
    if (outputImage != null) {
      await encodeBmpFile(path, outputImage!);
    }
  }
}
