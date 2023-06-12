import 'dart:typed_data';

import '../../formats/formats.dart';
import '../command.dart';

// Decode a TIFF Image from byte [data].
class DecodeTiffCmd extends Command {
  Uint8List data;

  DecodeTiffCmd(Command? input, this.data) : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    outputImage = decodeTiff(data);
  }
}

// Decode a TIFF from a file at the given [path].
class DecodeTiffFileCmd extends Command {
  String path;

  DecodeTiffFileCmd(Command? input, this.path) : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    outputImage = await decodeTiffFile(path);
  }
}

// Encode an Image to the TIFF format.
class EncodeTiffCmd extends Command {
  EncodeTiffCmd(Command? input) : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    outputImage = input?.outputImage;
    if (outputImage != null) {
      outputBytes = encodeTiff(outputImage!);
    }
  }
}

// Encode an Image to the TIFF format and write it to a file at the given
// [path].
class EncodeTiffFileCmd extends EncodeTiffCmd {
  String path;

  EncodeTiffFileCmd(Command? input, this.path) : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    outputImage = input?.outputImage;
    if (outputImage != null) {
      await encodeTiffFile(path, outputImage!);
    }
  }
}
