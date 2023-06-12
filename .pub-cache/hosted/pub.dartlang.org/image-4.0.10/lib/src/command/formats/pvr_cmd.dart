import 'dart:typed_data';

import '../../formats/formats.dart';
import '../command.dart';

// Decode a PVR Image from byte [data].
class DecodePvrCmd extends Command {
  Uint8List data;

  DecodePvrCmd(Command? input, this.data) : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    outputImage = decodePvr(data);
  }
}

// Decode a PVR from a file at the given [path].
class DecodePvrFileCmd extends Command {
  String path;

  DecodePvrFileCmd(Command? input, this.path) : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    outputImage = await decodePvrFile(path);
  }
}

// Encode an Image to the PVR format.
class EncodePvrCmd extends Command {
  EncodePvrCmd(Command? input) : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    outputImage = input?.outputImage;
    if (outputImage != null) {
      outputBytes = encodePvr(outputImage!);
    }
  }
}

// Encode an Image to the PVR format and write it to a file at the given
// [path].
class EncodePvrFileCmd extends EncodePvrCmd {
  String path;

  EncodePvrFileCmd(Command? input, this.path) : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    outputImage = input?.outputImage;
    if (outputImage != null) {
      await encodePvrFile(path, outputImage!);
    }
  }
}
