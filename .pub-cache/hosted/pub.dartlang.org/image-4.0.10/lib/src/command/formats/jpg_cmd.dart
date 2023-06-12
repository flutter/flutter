import 'dart:typed_data';

import '../../formats/formats.dart';
import '../command.dart';

// Decode a JPEG Image from byte [data].
class DecodeJpgCmd extends Command {
  Uint8List data;

  DecodeJpgCmd(Command? input, this.data) : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    outputImage = decodeJpg(data);
  }
}

// Decode a JPEG from a file at the given [path].
class DecodeJpgFileCmd extends Command {
  String path;

  DecodeJpgFileCmd(Command? input, this.path) : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    outputImage = await decodeJpgFile(path);
  }
}

// Encode an Image to the JPEG format.
class EncodeJpgCmd extends Command {
  int quality;

  EncodeJpgCmd(Command? input, {this.quality = 100}) : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    outputImage = input?.outputImage;
    if (outputImage != null) {
      outputBytes = encodeJpg(outputImage!, quality: quality);
    }
  }
}

// Encode an Image to the JPEG format and write it to a file at the given
// [path].
class EncodeJpgFileCmd extends EncodeJpgCmd {
  String path;

  EncodeJpgFileCmd(Command? input, this.path, {int quality = 100})
      : super(input, quality: quality);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    outputImage = input?.outputImage;
    if (outputImage != null) {
      await encodeJpgFile(path, outputImage!, quality: quality);
    }
  }
}
