import 'dart:typed_data';

import '../../formats/formats.dart';
import '../command.dart';

// Decode a ICO Image from byte [data].
class DecodeIcoCmd extends Command {
  Uint8List data;

  DecodeIcoCmd(Command? input, this.data) : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    outputImage = decodeIco(data);
  }
}

// Decode a ICO from a file at the given [path].
class DecodeIcoFileCmd extends Command {
  String path;

  DecodeIcoFileCmd(Command? input, this.path) : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    outputImage = await decodeIcoFile(path);
  }
}

// Encode an Image to the ICO format.
class EncodeIcoCmd extends Command {
  EncodeIcoCmd(Command? input) : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    outputImage = input?.outputImage;
    if (outputImage != null) {
      outputBytes = encodeIco(outputImage!);
    }
  }
}

// Encode an Image to the ICO format and write it to a file at the given
// [path].
class EncodeIcoFileCmd extends EncodeIcoCmd {
  String path;

  EncodeIcoFileCmd(Command? input, this.path) : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    outputImage = input?.outputImage;
    if (outputImage != null) {
      await encodeIcoFile(path, outputImage!);
    }
  }
}
