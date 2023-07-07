import 'dart:typed_data';

import '../../formats/formats.dart';
import '../../formats/png_encoder.dart';
import '../command.dart';

/// Decode a PNG Image from byte data.
class DecodePngCmd extends Command {
  final Uint8List _data;

  DecodePngCmd(Command? input, this._data) : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    outputImage = decodePng(_data);
  }
}

/// Decode a PNG Image from a file at the given path.
class DecodePngFileCmd extends Command {
  final String path;

  DecodePngFileCmd(Command? input, this.path) : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    outputImage = await decodePngFile(path);
  }
}

/// Encode an Image to the PNG format.
class EncodePngCmd extends Command {
  final int _level;
  final PngFilter _filter;

  EncodePngCmd(Command? input,
      {int level = 6, PngFilter filter = PngFilter.paeth})
      : _level = level,
        _filter = filter,
        super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    outputImage = input?.outputImage;
    if (outputImage != null) {
      outputBytes = encodePng(outputImage!, level: _level, filter: _filter);
    }
  }
}

/// Encode an Image to the PNG format and write it to a file at the given
/// path.
class EncodePngFileCmd extends EncodePngCmd {
  final String path;

  EncodePngFileCmd(Command? input, this.path,
      {int level = 6, PngFilter filter = PngFilter.paeth})
      : super(input, level: level, filter: filter);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    outputImage = input?.outputImage;
    if (outputImage != null) {
      await encodePngFile(path, outputImage!, level: _level, filter: _filter);
    }
  }
}
