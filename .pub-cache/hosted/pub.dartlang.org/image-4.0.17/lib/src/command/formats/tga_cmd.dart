import 'dart:typed_data';

import '../../formats/formats.dart';
import '../command.dart';

// Decode a TGA Image from byte [data].
class DecodeTgaCmd extends Command {
  Uint8List data;

  DecodeTgaCmd(Command? input, this.data) : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    outputImage = decodeTga(data);
  }
}

// Decode a TGA from a file at the given [path].
class DecodeTgaFileCmd extends Command {
  String path;

  DecodeTgaFileCmd(Command? input, this.path) : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    outputImage = await decodeTgaFile(path);
  }
}

// Encode an Image to the TGA format.
class EncodeTgaCmd extends Command {
  EncodeTgaCmd(Command? input) : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    outputImage = input?.outputImage;
    if (outputImage != null) {
      outputBytes = encodeTga(outputImage!);
    }
  }
}

// Encode an Image to the TGA format and write it to a file at the given
// [path].
class EncodeTgaFileCmd extends EncodeTgaCmd {
  String path;

  EncodeTgaFileCmd(Command? input, this.path) : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    outputImage = input?.outputImage;
    if (outputImage != null) {
      await encodeTgaFile(path, outputImage!);
    }
  }
}
