import 'dart:typed_data';

import '../../formats/formats.dart';
import '../command.dart';

class DecodeNamedImageCmd extends Command {
  String name;
  Uint8List data;

  DecodeNamedImageCmd(Command? input, this.name, this.data) : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final decoder = findDecoderForNamedImage(name);
    if (decoder != null) {
      outputImage = decoder.decode(data);
    } else {
      outputImage = decodeImage(data);
    }
  }
}
